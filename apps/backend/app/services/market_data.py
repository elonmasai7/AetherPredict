from __future__ import annotations

import asyncio
from datetime import datetime, timezone

import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import SessionLocal
from app.models.entities import AssetSnapshot, Market, Notification
from app.services.redis_bus import publish


ASSET_MAP = {
    "bitcoin": ("BTC", "Bitcoin"),
    "ethereum": ("ETH", "Ethereum"),
    "solana": ("SOL", "Solana"),
    "hashkey-ecosphere": ("HSK", "HashKey Ecosystem"),
}


async def fetch_live_assets() -> list[dict]:
    params = {
        "vs_currency": "usd",
        "ids": ",".join(ASSET_MAP.keys()),
        "order": "market_cap_desc",
        "sparkline": "false",
        "price_change_percentage": "24h",
    }
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.get(f"{settings.coingecko_api_url}/coins/markets", params=params)
        response.raise_for_status()
        return response.json()


def _compute_volatility(high_24h: float, low_24h: float, price: float) -> float:
    if price <= 0:
        return 0
    return round(((high_24h - low_24h) / price) * 100, 2)


def _compute_order_flow(change_24h: float, volume_24h: float, market_cap: float) -> float:
    if market_cap <= 0:
        return 0
    return round((change_24h * (volume_24h / market_cap)) * 100, 4)


def upsert_assets(db: Session, payload: list[dict]) -> list[AssetSnapshot]:
    saved: list[AssetSnapshot] = []
    now = datetime.now(timezone.utc)
    for item in payload:
        mapping = ASSET_MAP.get(item["id"])
        if mapping is None:
            continue
        symbol, default_name = mapping
        snapshot = db.scalar(select(AssetSnapshot).where(AssetSnapshot.symbol == symbol))
        if snapshot is None:
            snapshot = AssetSnapshot(symbol=symbol, name=default_name)
            db.add(snapshot)

        price = float(item.get("current_price") or 0)
        high_24h = float(item.get("high_24h") or price)
        low_24h = float(item.get("low_24h") or price)
        change_24h = float(item.get("price_change_percentage_24h") or 0)
        volume_24h = float(item.get("total_volume") or 0)
        market_cap = float(item.get("market_cap") or 0)
        snapshot.name = item.get("name") or default_name
        snapshot.price_usd = price
        snapshot.change_24h = change_24h
        snapshot.volume_24h = volume_24h
        snapshot.market_cap = market_cap
        snapshot.high_24h = high_24h
        snapshot.low_24h = low_24h
        snapshot.volatility_pct = _compute_volatility(high_24h, low_24h, price)
        snapshot.order_flow_score = _compute_order_flow(change_24h, volume_24h, market_cap)
        snapshot.source = "coingecko"
        snapshot.recorded_at = now
        saved.append(snapshot)
    db.commit()
    return saved


def sync_prediction_markets(db: Session, assets: list[AssetSnapshot]) -> None:
    markets = db.scalars(select(Market)).all()
    asset_by_symbol = {asset.symbol: asset for asset in assets}
    touched = False
    for market in markets:
        symbol = _infer_symbol(market.title)
        asset = asset_by_symbol.get(symbol)
        if asset is None:
            continue
        market.yes_probability = max(0.01, min(0.99, 0.5 + (asset.change_24h / 100)))
        market.no_probability = round(1 - market.yes_probability, 4)
        market.ai_confidence = max(0.05, min(0.99, 0.55 + (asset.volatility_pct / 200)))
        market.volume = max(market.volume, asset.volume_24h)
        market.liquidity = max(market.liquidity, asset.market_cap * 0.0001)
        touched = True
    if touched:
        db.commit()


def _infer_symbol(title: str) -> str:
    upper = title.upper()
    if "BTC" in upper or "BITCOIN" in upper:
        return "BTC"
    if "ETH" in upper or "ETHEREUM" in upper:
        return "ETH"
    if "SOL" in upper or "SOLANA" in upper:
        return "SOL"
    if "HASHKEY" in upper or "HSK" in upper:
        return "HSK"
    return "BTC"


async def live_market_data_worker() -> None:
    while True:
        db: Session = SessionLocal()
        try:
            payload = await fetch_live_assets()
            assets = upsert_assets(db, payload)
            sync_prediction_markets(db, assets)
            for asset in assets:
                await publish(
                    settings.websocket_channel,
                    {
                        "type": "asset",
                        "market": asset.symbol,
                        "yes_probability": 0,
                        "confidence": asset.volatility_pct / 100,
                        "price_usd": asset.price_usd,
                        "change_24h": asset.change_24h,
                        "timestamp": asset.recorded_at.isoformat(),
                    },
                )
                if abs(asset.change_24h) >= settings.price_alert_threshold_pct:
                    db.add(
                        Notification(
                            level="warning" if asset.change_24h < 0 else "info",
                            category="market",
                            message=f"{asset.symbol} moved {asset.change_24h:.2f}% over 24h",
                            metadata_json={"symbol": asset.symbol, "price_usd": asset.price_usd},
                        )
                    )
            db.commit()
        except Exception:
            db.rollback()
        finally:
            db.close()
        await asyncio.sleep(settings.market_poll_interval_seconds)
