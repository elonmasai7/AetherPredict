import asyncio
import contextlib
import json
from datetime import datetime, timezone

from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import SessionLocal
from app.models.entities import Market


redis_client = Redis.from_url(settings.redis_url, decode_responses=True)


async def publish(channel: str, payload: dict) -> None:
    await redis_client.publish(channel, json.dumps(payload))


async def market_feed_worker() -> None:
    while True:
        db: Session = SessionLocal()
        try:
            market = db.scalar(select(Market).order_by(Market.volume.desc()))
            if market is not None:
                payload = {
                    "market": market.slug,
                    "yes_probability": round(market.yes_probability, 4),
                    "confidence": round(market.ai_confidence, 4),
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }
                await publish(settings.websocket_channel, payload)
        finally:
            db.close()
        await asyncio.sleep(2)


async def subscribe(channel: str):
    pubsub = redis_client.pubsub()
    await pubsub.subscribe(channel)
    try:
        async for message in pubsub.listen():
            if message["type"] == "message":
                yield json.loads(message["data"])
    finally:
        with contextlib.suppress(Exception):
            await pubsub.unsubscribe(channel)
            await pubsub.close()
