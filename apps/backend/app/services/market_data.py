from __future__ import annotations

import asyncio
from datetime import UTC, datetime

from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import SessionLocal
from app.services.market_service import MarketService
from app.services.news_service import NewsService
from app.services.redis_bus import publish


async def live_market_data_worker() -> None:
    while True:
        db: Session = SessionLocal()
        try:
            market_service = MarketService(db)
            markets = market_service.sync_live_markets()
            news_items = NewsService().latest_news()[:8]
            games = market_service.live_games()
            timestamp = datetime.now(UTC).isoformat()

            for game in games:
                await publish(
                    settings.games_websocket_channel,
                    {
                        "type": "game",
                        "game_id": game["game_id"],
                        "matchup": game["matchup"],
                        "status": game["status"],
                        "home_score": game["home_score"],
                        "away_score": game["away_score"],
                        "win_probability_home": game["win_probability_home"],
                        "headline": game["headline"],
                        "timestamp": timestamp,
                    },
                )

            for market in markets:
                metadata = market.metadata_json or {}
                await publish(
                    settings.websocket_channel,
                    {
                        "type": "market",
                        "market": market.slug,
                        "market_id": market.id,
                        "title": market.title,
                        "yes_probability": round(market.yes_probability, 4),
                        "confidence": round(market.ai_confidence, 4),
                        "headline": metadata.get("headline") or metadata.get("matchup") or market.title,
                        "timestamp": timestamp,
                    },
                )
                await publish(
                    settings.activity_websocket_channel,
                    {
                        "type": "probability_update",
                        "market_id": market.id,
                        "market": market.title,
                        "probability": round(market.yes_probability, 4),
                        "confidence": round(market.ai_confidence, 4),
                        "timestamp": timestamp,
                    },
                )

            for news_item in news_items:
                await publish(
                    settings.activity_websocket_channel,
                    {
                        "type": "news",
                        "title": news_item["title"],
                        "urgency": news_item["urgency"],
                        "team": news_item.get("team"),
                        "player": news_item.get("player"),
                        "timestamp": news_item["published_at"].isoformat(),
                    },
                )
        except Exception:
            db.rollback()
        finally:
            db.close()
        await asyncio.sleep(settings.market_poll_interval_seconds)
