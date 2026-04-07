import asyncio
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import inspect

from app.api import (
    agents,
    ai,
    auth,
    blockchain,
    chain_tx,
    bundles,
    discussions,
    disputes,
    insurance,
    leaderboard,
    markets,
    notifications,
    portfolio,
    copy_trading,
    reports,
    trades,
    vaults,
    watchlists,
    workspaces,
    ws,
)
from app.core.config import settings
from app.db.session import SessionLocal, engine
from app.services.market_data import live_market_data_worker
from app.services.redis_bus import market_feed_worker
from app.services.tx_receipt_worker import tx_receipt_worker

app = FastAPI(title=settings.app_name, version="0.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

for route in (
    auth.router,
    blockchain.router,
    chain_tx.router,
    markets.router,
    portfolio.router,
    trades.router,
    ai.router,
    agents.router,
    leaderboard.router,
    bundles.router,
    insurance.router,
    discussions.router,
    disputes.router,
    notifications.router,
    vaults.router,
    copy_trading.router,
    watchlists.router,
    workspaces.router,
    reports.router,
    ws.router,
):
    app.include_router(route)

stream_task: asyncio.Task | None = None
asset_task: asyncio.Task | None = None
receipt_task: asyncio.Task | None = None


@app.on_event("startup")
async def startup() -> None:
    global stream_task, asset_task, receipt_task
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    required_tables = {
        "users",
        "markets",
        "portfolio_positions",
        "trade_orders",
        "notifications",
        "wallet_balances",
        "asset_snapshots",
        "strategy_vaults",
        "vault_markets",
        "vault_subscriptions",
        "vault_trades",
        "vault_performance_snapshots",
        "copy_relationships",
        "copy_allocation_rules",
        "copied_trades",
        "copy_performance_snapshots",
    }
    missing_tables = sorted(required_tables - existing_tables)
    if missing_tables:
        joined = ", ".join(missing_tables)
        raise RuntimeError(
            f"Database schema is missing tables: {joined}. Run 'alembic upgrade head' from apps/backend before starting the API."
        )
    SessionLocal().close()
    stream_task = asyncio.create_task(market_feed_worker())
    asset_task = asyncio.create_task(live_market_data_worker())
    receipt_task = asyncio.create_task(tx_receipt_worker())


@app.on_event("shutdown")
async def shutdown() -> None:
    global stream_task, asset_task, receipt_task
    for task in (stream_task, asset_task, receipt_task):
        if task is not None:
            task.cancel()


@app.get("/health")
def health():
    return {"status": "ok", "service": "backend", "version": "0.2.0"}


frontend_dist = Path(__file__).resolve().parents[2] / "flutter_app" / "build" / "web"
if frontend_dist.exists():
    app.mount("/", StaticFiles(directory=frontend_dist, html=True), name="frontend")
