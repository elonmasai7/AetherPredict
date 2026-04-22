from __future__ import annotations

from datetime import UTC, datetime, timedelta

from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.models.entities import Market, PortfolioPosition, TradeOrder
from app.services.liquidity_engine import LiquidityIntelligenceService
from app.services.news_service import NewsService
from app.services.nba_data_service import NbaDataService
from app.services.prediction_engine import PredictionEngine


def _market_slug(game_id: str) -> str:
    return f"nba-{game_id}-winner"


class MarketService:
    def __init__(self, db: Session):
        self.db = db
        self.data = NbaDataService()
        self.news_service = NewsService()
        self.prediction_engine = PredictionEngine()
        self.liquidity_service = LiquidityIntelligenceService(db)

    def sync_live_markets(self) -> list[Market]:
        games = self.data.live_games()
        slugs = [_market_slug(game["game_id"]) for game in games if game.get("game_id")]
        existing = {
            market.slug: market
            for market in self.db.scalars(select(Market).where(Market.slug.in_(slugs))).all()
        } if slugs else {}
        synced: list[Market] = []
        changed = False
        latest_news = self.news_service.latest_news()

        for game in games:
            slug = _market_slug(game["game_id"])
            market = existing.get(slug)
            news_items = (
                self.news_service.news_for_team(game["home_team"], news_items=latest_news)
                + self.news_service.news_for_team(game["away_team"], news_items=latest_news)
            )
            yes_probability = round(float(game["win_probability_home"]), 4)
            ai_confidence = self._confidence_for_game(game, news_items)
            volume = self._trade_volume(market.id) if market is not None else 0.0
            liquidity = self._liquidity_value(market)
            metadata = {
                "provider": "espn-live",
                "source_kind": "live_game",
                "game_id": game["game_id"],
                "sport": "NBA",
                "league": "NBA",
                "matchup": game["matchup"],
                "primary_subject": game["home_team"],
                "yes_label": game["home_team"],
                "no_label": game["away_team"],
                "game_status": game["status"],
                "headline": game["headline"],
                "team_form": {
                    "home_team": game["home_team"],
                    "away_team": game["away_team"],
                    "home_score": game["home_score"],
                    "away_score": game["away_score"],
                    "pace": game["pace"],
                },
                "player_context": {},
                "latest_news_count": len(news_items),
            }

            if market is None:
                market = Market(
                    slug=slug,
                    title=f"{game['away_team']} at {game['home_team']} - Who Wins?",
                    description=f"Live NBA market synced from official game feed for {game['matchup']}.",
                    category="Game Outcome",
                    oracle_source="ESPN live scoreboard feed",
                    expiry_at=game["tipoff_time"] + timedelta(hours=6),
                    yes_probability=yes_probability,
                    no_probability=round(1 - yes_probability, 4),
                    ai_confidence=ai_confidence,
                    volume=volume,
                    liquidity=liquidity,
                    resolved="Final" in game["status"],
                    outcome=self._outcome_for_game(game) if "Final" in game["status"] else "PENDING",
                    resolution_rules="Resolved from official final NBA game result.",
                    collateral_token="USDC",
                    metadata_json={**metadata, "probability_points": [yes_probability]},
                )
                self.db.add(market)
                changed = True
                synced.append(market)
                continue

            prior_points = list((market.metadata_json or {}).get("probability_points") or [])
            prior_points.append(yes_probability)
            market.title = f"{game['away_team']} at {game['home_team']} - Who Wins?"
            market.description = f"Live NBA market synced from official game feed for {game['matchup']}."
            market.category = "Game Outcome"
            market.oracle_source = "ESPN live scoreboard feed"
            market.expiry_at = game["tipoff_time"] + timedelta(hours=6)
            market.yes_probability = yes_probability
            market.no_probability = round(1 - yes_probability, 4)
            market.ai_confidence = ai_confidence
            market.volume = volume
            market.liquidity = liquidity
            market.resolved = "Final" in game["status"]
            market.outcome = self._outcome_for_game(game) if market.resolved else "PENDING"
            market.resolution_rules = "Resolved from official final NBA game result."
            market.collateral_token = "USDC"
            market.metadata_json = {**metadata, "probability_points": prior_points[-24:]}
            changed = True
            synced.append(market)

        if changed:
            self.db.commit()
            for market in synced:
                self.db.refresh(market)
        return synced

    def nba_markets(self) -> list[Market]:
        return [
            market
            for market in self.db.scalars(select(Market).order_by(Market.expiry_at.asc())).all()
            if (market.metadata_json or {}).get("provider") == "espn-live"
        ]

    def enriched_markets(self) -> list[dict]:
        markets = sorted(self.sync_live_markets(), key=lambda market: market.expiry_at)
        latest_news = self.news_service.latest_news()
        result = []
        for market in markets:
            snapshot = self.liquidity_service.build_market_snapshot(market)
            news = self.news_service.news_for_market(
                {"title": market.title, **(market.metadata_json or {})},
                news_items=latest_news,
            )
            result.append(self.prediction_engine.enrich_market(market, snapshot.__dict__, news))
        return result

    def overview(self, *, markets: list[dict] | None = None, games: list[dict] | None = None) -> dict:
        positions = self.db.scalars(select(PortfolioPosition).order_by(PortfolioPosition.opened_at.desc())).all()
        roi = 0.0
        if positions:
            exposure = sum(max(position.size * position.avg_price, 1) for position in positions)
            pnl = sum(position.pnl for position in positions)
            roi = (pnl / exposure) * 100 if exposure else 0.0
        closed_positions = [position for position in positions if position.status == "CLOSED"]
        profitable = [position for position in closed_positions if position.pnl > 0]
        if markets is None:
            markets = self.enriched_markets()
        if games is None:
            games = self.live_games()
        return {
            "active_markets": len(markets),
            "live_games": len([game for game in games if not game["status"].lower().startswith("final") and "pre" not in game["status"].lower()]),
            "model_accuracy": round((len(profitable) / len(closed_positions)) * 100, 2) if closed_positions else 0.0,
            "total_liquidity": round(sum(market["liquidity"] for market in markets), 2),
            "open_predictions": len([position for position in positions if position.status == "OPEN"]),
            "prediction_roi": round(roi, 2),
        }

    def live_games(self) -> list[dict]:
        return self.data.live_games()

    def activity_feed(self) -> list[dict]:
        trades = self.db.scalars(select(TradeOrder).order_by(TradeOrder.created_at.desc()).limit(16)).all()
        return [
            {
                "id": f"trade-{trade.id}",
                "user": trade.wallet_address or "Wallet",
                "market": trade.market.title if trade.market else f"Market {trade.market_id}",
                "pick": trade.side,
                "confidence": (trade.metadata_json or {}).get("confidence_label", "submitted"),
                "amount": trade.collateral_amount,
                "created_at": trade.created_at.astimezone(UTC) if trade.created_at.tzinfo else trade.created_at.replace(tzinfo=UTC),
            }
            for trade in trades
        ]

    def recent_predictions(self) -> list[dict]:
        return self.activity_feed()[:4]

    def _confidence_for_game(self, game: dict, news_items: list[dict]) -> float:
        base = 0.5 + min(abs(game["win_probability_home"] - 0.5) * 0.6, 0.2)
        if any(item["urgency"] == "high" for item in news_items):
            base += 0.08
        if any(tag in game["status"] for tag in ("Q3", "Q4", "OT", "Final")):
            base += 0.1
        return round(max(0.5, min(base, 0.95)), 4)

    def _trade_volume(self, market_id: int | None) -> float:
        if market_id is None:
            return 0.0
        volume = self.db.scalar(
            select(func.coalesce(func.sum(TradeOrder.collateral_amount), 0.0)).where(
                TradeOrder.market_id == market_id
            )
        )
        return round(float(volume or 0.0), 2)

    def _liquidity_value(self, market: Market | None) -> float:
        if market is None:
            return 0.0
        return round(float(market.liquidity or 0.0), 2)

    def _outcome_for_game(self, game: dict) -> str:
        if game["home_score"] == game["away_score"]:
            return "PENDING"
        return "YES" if game["home_score"] > game["away_score"] else "NO"
