import asyncio

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import inspect

from app.api import agents, ai, auth, disputes, markets, notifications, portfolio, ws
from app.core.config import settings
from app.db.session import engine, SessionLocal
from app.services.bootstrap import seed_demo_data
from app.services.redis_bus import market_feed_worker

app = FastAPI(title=settings.app_name, version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(markets.router)
app.include_router(portfolio.router)
app.include_router(ai.router)
app.include_router(agents.router)
app.include_router(disputes.router)
app.include_router(notifications.router)
app.include_router(ws.router)

stream_task: asyncio.Task | None = None


@app.on_event("startup")
async def startup() -> None:
    global stream_task
    inspector = inspect(engine)
    required_tables = {"users", "markets", "portfolio_positions", "agent_statuses", "disputes"}
    existing_tables = set(inspector.get_table_names())
    missing_tables = sorted(required_tables - existing_tables)
    if missing_tables:
        joined = ", ".join(missing_tables)
        raise RuntimeError(
            f"Database schema is missing tables: {joined}. Run 'alembic upgrade head' from apps/backend before starting the API."
        )
    db = SessionLocal()
    try:
        seed_demo_data(db)
    finally:
        db.close()
    stream_task = asyncio.create_task(market_feed_worker())


@app.on_event("shutdown")
async def shutdown() -> None:
    global stream_task
    if stream_task is not None:
        stream_task.cancel()


@app.get("/health")
def health():
    return {"status": "ok", "service": "backend"}
