from __future__ import annotations

import asyncio

from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import SessionLocal
from app.services.strategy_engine_service import StrategyEngineService


async def strategy_engine_refresh_worker() -> None:
    while True:
        db: Session = SessionLocal()
        try:
            StrategyEngineService(db).refresh_active_strategies()
        finally:
            db.close()
        await asyncio.sleep(settings.strategy_engine_refresh_seconds)
