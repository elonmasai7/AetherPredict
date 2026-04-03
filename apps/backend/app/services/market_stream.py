from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import Market
from app.services.redis_bus import publish


async def publish_market_update(db: Session, market: Market) -> None:
    await publish(
        "aetherpredict:market_updates",
        {
            "market": market.slug,
            "yes_probability": round(market.yes_probability, 4),
            "confidence": round(market.ai_confidence, 4),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    )


def get_market_by_id(db: Session, market_id: int) -> Market | None:
    return db.scalar(select(Market).where(Market.id == market_id))
