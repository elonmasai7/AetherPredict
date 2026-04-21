from __future__ import annotations

import asyncio
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import SessionLocal
from app.models.entities import Market
from app.services.redis_bus import publish


def refresh_nba_markets(db: Session) -> list[Market]:
    markets = db.scalars(
        select(Market)
        .where(Market.category.in_(["Game Outcome", "Player Performance", "Season Market"]))
        .order_by(Market.expiry_at.asc())
    ).all()
    touched = False
    minute_factor = datetime.now(UTC).minute
    for index, market in enumerate(markets):
        drift = ((minute_factor + index) % 7 - 3) * 0.0015
        market.yes_probability = round(min(0.99, max(0.01, market.yes_probability + drift)), 4)
        market.no_probability = round(1 - market.yes_probability, 4)
        market.ai_confidence = round(min(0.92, max(0.58, market.ai_confidence + abs(drift) / 2)), 4)
        metadata = dict(market.metadata_json or {})
        points = list(metadata.get("probability_points") or [])
        points.append(market.yes_probability)
        metadata["probability_points"] = points[-8:]
        market.metadata_json = metadata
        touched = True
    if touched:
        db.commit()
    return markets


async def live_market_data_worker() -> None:
    while True:
        db: Session = SessionLocal()
        try:
            markets = refresh_nba_markets(db)
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
                        "headline": metadata.get("player_context", {}).get("trend")
                        or metadata.get("matchup", market.title),
                        "timestamp": datetime.now(UTC).isoformat(),
                    },
                )
        except Exception:
            db.rollback()
        finally:
            db.close()
        await asyncio.sleep(settings.market_poll_interval_seconds)
