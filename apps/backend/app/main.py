import asyncio
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from starlette.exceptions import HTTPException as StarletteHTTPException
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
    liquidity,
    markets,
    nba_data,
    notifications,
    news,
    portfolio,
    platform,
    predictions,
    copy_trading,
    reports,
    strategy,
    strategy_engine,
    trades,
    vaults,
    watchlists,
    workspaces,
    ws,
)
from app.core.config import settings
from app.db.session import engine
from app.services.market_data import live_market_data_worker
from app.services.strategy_engine_jobs import strategy_engine_refresh_worker
from app.services.tx_receipt_worker import tx_receipt_worker

app = FastAPI(
    title=settings.app_name,
    version="0.2.0",
    docs_url="/docs" if settings.docs_enabled else None,
    redoc_url="/redoc" if settings.docs_enabled else None,
    openapi_url="/openapi.json" if settings.docs_enabled else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
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
    nba_data.router,
    news.router,
    predictions.router,
    vaults.router,
    platform.router,
    liquidity.router,
    copy_trading.router,
    watchlists.router,
    workspaces.router,
    reports.router,
    strategy.router,
    strategy_engine.router,
    ws.router,
):
    app.include_router(route)

asset_task: asyncio.Task | None = None
receipt_task: asyncio.Task | None = None
strategy_refresh_task: asyncio.Task | None = None


@app.on_event("startup")
async def startup() -> None:
    global asset_task, receipt_task, strategy_refresh_task
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
        "strategy_engine_strategies",
        "strategy_engine_runs",
        "strategy_engine_logs",
        "strategy_engine_exports",
        "strategy_engine_rankings",
    }
    missing_tables = sorted(required_tables - existing_tables)
    if missing_tables:
        joined = ", ".join(missing_tables)
        raise RuntimeError(
            f"Database schema is missing tables: {joined}. Run 'alembic upgrade head' from apps/backend before starting the API."
        )
    asset_task = asyncio.create_task(live_market_data_worker())
    receipt_task = asyncio.create_task(tx_receipt_worker())
    strategy_refresh_task = asyncio.create_task(strategy_engine_refresh_worker())


@app.on_event("shutdown")
async def shutdown() -> None:
    global asset_task, receipt_task, strategy_refresh_task
    for task in (asset_task, receipt_task, strategy_refresh_task):
        if task is not None:
            task.cancel()


@app.get("/health")
def health():
    return {"status": "ok", "service": "backend", "version": "0.2.0"}


@app.get("/ready")
def ready():
    return {
        "status": "ready",
        "service": "backend",
        "environment": settings.app_env,
        "docs_enabled": settings.docs_enabled,
    }


def _resolve_frontend_dist() -> Path | None:
    base = Path(__file__).resolve()
    candidates = (
        # Docker image layout: /app/app/main.py -> /app/flutter_app/build/web
        base.parents[1] / "flutter_app" / "build" / "web",
        # Local repo layout: .../apps/backend/app/main.py -> .../apps/flutter_app/build/web
        base.parents[2] / "flutter_app" / "build" / "web",
    )
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


@app.get("/favicon.ico")
def favicon():
    if frontend_dist is None:
        raise HTTPException(status_code=404)
    favicon_path = frontend_dist / "favicon.png"
    if favicon_path.exists():
        return FileResponse(favicon_path)
    raise HTTPException(status_code=404)


frontend_dist = _resolve_frontend_dist()
if frontend_dist is not None:
    class SPAStaticFiles(StaticFiles):
        # Serve index.html for frontend deep-links while preserving API/asset 404s.
        _no_fallback_prefixes = (
            "auth",
            "blockchain",
            "chain-tx",
            "markets",
            "portfolio",
            "trades",
            "ai",
            "agents",
            "leaderboard",
            "bundles",
            "insurance",
            "market",
            "disputes",
            "notifications",
            "vaults",
            "copy-trading",
            "watchlists",
            "workspaces",
            "reports",
            "strategy-engine",
            "ws",
            "health",
            *(() if not settings.docs_enabled else ("openapi.json", "docs", "redoc")),
        )

        async def get_response(self, path: str, scope):
            try:
                return await super().get_response(path, scope)
            except StarletteHTTPException as ex:
                if ex.status_code != 404:
                    raise

                normalized = path.lstrip("/")
                first_segment = normalized.split("/", 1)[0]
                if "." in normalized.split("/")[-1] or first_segment in self._no_fallback_prefixes:
                    raise

                return await super().get_response("index.html", scope)

    app.mount("/", SPAStaticFiles(directory=frontend_dist, html=True), name="frontend")
