from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import Market, PortfolioPosition, TradeOrder
from app.services.liquidity_engine import LiquidityIntelligenceService
from app.services.news_service import NewsService
from app.services.nba_data_service import NbaDataService
from app.services.prediction_engine import PredictionEngine


class MarketService:
    def __init__(self, db: Session):
        self.db = db
        self.seed_data = NbaDataService()
        self.news_service = NewsService()
        self.prediction_engine = PredictionEngine()
        self.liquidity_service = LiquidityIntelligenceService(db)

    def ensure_seed_data(self) -> None:
        existing = {
            market.slug: market
            for market in self.db.scalars(select(Market).where(Market.category.in_(["Game Outcome", "Player Performance", "Season Market"]))).all()
        }
        changed = False
        for payload in self.seed_data.market_seeds():
            market = existing.get(payload["slug"])
            if market is None:
                market = Market(
                    slug=payload["slug"],
                    title=payload["title"],
                    description=payload["description"],
                    category=payload["category"],
                    oracle_source=payload["oracle_source"],
                    expiry_at=payload["expiry_at"],
                    yes_probability=payload["yes_probability"],
                    no_probability=round(1 - payload["yes_probability"], 4),
                    ai_confidence=payload["ai_confidence"],
                    volume=payload["volume"],
                    liquidity=payload["liquidity"],
                    resolved=False,
                    outcome="PENDING",
                    resolution_rules="Resolved from official NBA results at market expiry.",
                    collateral_token="USDC",
                    metadata_json=payload["metadata_json"] | {"market_type": payload["market_type"]},
                )
                self.db.add(market)
                changed = True
                continue
            market.title = payload["title"]
            market.description = payload["description"]
            market.category = payload["category"]
            market.oracle_source = payload["oracle_source"]
            market.expiry_at = payload["expiry_at"]
            market.yes_probability = payload["yes_probability"]
            market.no_probability = round(1 - payload["yes_probability"], 4)
            market.ai_confidence = payload["ai_confidence"]
            market.volume = payload["volume"]
            market.liquidity = payload["liquidity"]
            market.resolved = False
            market.outcome = "PENDING"
            market.resolution_rules = "Resolved from official NBA results at market expiry."
            market.collateral_token = "USDC"
            market.metadata_json = payload["metadata_json"] | {"market_type": payload["market_type"]}
            changed = True
        if changed:
            self.db.commit()

    def nba_markets(self) -> list[Market]:
        return self.db.scalars(
            select(Market)
            .where(Market.category.in_(["Game Outcome", "Player Performance", "Season Market"]))
            .order_by(Market.expiry_at.asc())
        ).all()

    def enriched_markets(self) -> list[dict]:
        result = []
        for market in self.nba_markets():
            snapshot = self.liquidity_service.build_market_snapshot(market)
            news = self.news_service.news_for_market(
                {"title": market.title, **(market.metadata_json or {})}
            )
            result.append(self.prediction_engine.enrich_market(market, snapshot.__dict__, news))
        return result

    def overview(self) -> dict:
        positions = self.db.scalars(select(PortfolioPosition).order_by(PortfolioPosition.opened_at.desc())).all()
        roi = 0.0
        if positions:
            exposure = sum(max(position.size * position.avg_price, 1) for position in positions)
            pnl = sum(position.pnl for position in positions)
            roi = (pnl / exposure) * 100 if exposure else 0.0
        markets = self.enriched_markets()
        return {
            "active_markets": len(markets),
            "live_games": len([game for game in self.seed_data.live_games() if game["status"] != "Pre-game"]),
            "model_accuracy": 68.7,
            "total_liquidity": round(sum(market["liquidity"] for market in markets), 2),
            "open_predictions": len(positions),
            "prediction_roi": round(roi, 2),
        }

    def live_games(self) -> list[dict]:
        return self.seed_data.live_games()

    def activity_feed(self) -> list[dict]:
        trades = self.db.scalars(select(TradeOrder).order_by(TradeOrder.created_at.desc()).limit(8)).all()
        if trades:
            return [
                {
                    "id": f"trade-{trade.id}",
                    "user": trade.wallet_address or "Desk User",
                    "market": trade.market.title if trade.market else f"Market {trade.market_id}",
                    "pick": trade.side,
                    "confidence": trade.metadata_json.get("confidence_label", "Actionable"),
                    "amount": trade.collateral_amount,
                    "created_at": trade.created_at.astimezone(UTC) if trade.created_at.tzinfo else trade.created_at.replace(tzinfo=UTC),
                }
                for trade in trades
            ]
        now = datetime.now(UTC)
        return [
            {
                "id": "activity-1",
                "user": "Signal Desk",
                "market": "Lakers vs Warriors - Who Wins?",
                "pick": "YES",
                "confidence": "High Conviction",
                "amount": 2500.0,
                "created_at": now,
            },
            {
                "id": "activity-2",
                "user": "Model Ops",
                "market": "Will Nikola Jokic grab 12+ rebounds?",
                "pick": "YES",
                "confidence": "Actionable",
                "amount": 1800.0,
                "created_at": now,
            },
        ]

    def recent_predictions(self) -> list[dict]:
        return self.activity_feed()[:4]
