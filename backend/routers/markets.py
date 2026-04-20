from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import get_db, redis_client, settings
from integrations import ProviderProxy
from liquidity import dynamic_spread_cents, implied_yes_probability, liquidity_snapshot, order_book_from_mid, realized_volatility, spread_tier
from models import Market, OddsHistory


router = APIRouter(tags=["markets"])
provider_proxy = ProviderProxy()


class MarketCreateRequest(BaseModel):
    title: str
    event: str
    end_date: datetime
    min_liquidity: float = Field(default=2000, ge=250)
    provider: str = Field(default="mock")
    provider_market_id: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


def list_market_rows(db: Session) -> list[Market]:
    return list(db.scalars(select(Market).where(Market.archived.is_(False)).order_by(Market.updated_at.desc())))


def market_history_prices(db: Session, market_id: int, limit: int = 20) -> list[float]:
    rows = list(
        db.scalars(
            select(OddsHistory.yes_price).where(OddsHistory.market_id == market_id).order_by(OddsHistory.captured_at.desc()).limit(limit)
        )
    )
    return list(reversed(rows))


def sync_market_quote(db: Session, market: Market) -> dict[str, Any]:
    history = market_history_prices(db, market.id)
    external = provider_proxy.fetch_market_data(market) if settings.use_external_markets else {}
    probability = implied_yes_probability(market.yes_shares, market.no_shares, market.b_param)
    if external:
        probability = (probability * 0.6) + (float(external.get("reference_yes_price", probability)) * 0.4)
    volatility = realized_volatility(history + [probability])
    event_tag = f"{market.event} {market.title}"
    market.spread_cents = dynamic_spread_cents(probability, market.liquidity_usd, volatility, market.end_ts, event_tag)
    market.implied_probability = round(probability, 4)
    market.yes_price = round(probability, 4)
    market.no_price = round(1 - probability, 4)
    market.order_book_json = order_book_from_mid(market.yes_price, market.spread_cents, market.liquidity_usd)
    market.maker_concentration = max(18.0, min(89.0, 65 - (market.liquidity_usd / 12000)))
    history_row = OddsHistory(
        market_id=market.id,
        yes_price=market.yes_price,
        no_price=market.no_price,
        spread_cents=market.spread_cents,
        liquidity_usd=market.liquidity_usd,
        order_book_json=market.order_book_json,
    )
    db.add(history_row)
    db.commit()
    db.refresh(market)
    return liquidity_snapshot(market)


@router.get("/markets")
def list_markets(db: Session = Depends(get_db)) -> list[dict[str, Any]]:
    payload = []
    for market in list_market_rows(db):
        snapshot = liquidity_snapshot(market)
        payload.append(
            {
                "id": market.id,
                "title": market.title,
                "event": market.event,
                "provider": market.provider,
                "provider_market_id": market.provider_market_id,
                "yes_price": market.yes_price,
                "no_price": market.no_price,
                "implied_probability": market.implied_probability,
                "spread_cents": market.spread_cents,
                "spread_tier": spread_tier(market.spread_cents),
                "liquidity_usd": market.liquidity_usd,
                "end_ts": market.end_ts.isoformat(),
                "odds_history": market_history_prices(db, market.id, limit=30),
                "order_book": snapshot["order_book"],
            }
        )
    return payload


@router.post("/markets", status_code=201)
def create_market(payload: MarketCreateRequest, db: Session = Depends(get_db)) -> dict[str, Any]:
    event_metadata = {
        "theme": payload.metadata.get("theme", "macro"),
        "reference_note": payload.metadata.get("reference_note", "Internal odds engine"),
        **payload.metadata,
    }
    market = Market(
        title=payload.title,
        event=payload.event,
        provider=payload.provider,
        provider_market_id=payload.provider_market_id,
        end_ts=payload.end_date.astimezone(timezone.utc) if payload.end_date.tzinfo else payload.end_date.replace(tzinfo=timezone.utc),
        min_liquidity=payload.min_liquidity,
        liquidity_usd=max(payload.min_liquidity, payload.min_liquidity * 1.25),
        b_param=settings.default_b_param,
        yes_shares=settings.default_b_param / 2,
        no_shares=settings.default_b_param / 2,
        metadata_json=event_metadata,
    )
    db.add(market)
    db.commit()
    db.refresh(market)
    snapshot = sync_market_quote(db, market)
    return {
        "market_id": market.id,
        "title": market.title,
        "provider": market.provider,
        "snapshot": snapshot,
    }


@router.get("/markets/{market_id}/odds")
def get_market_odds(market_id: int, db: Session = Depends(get_db)) -> dict[str, Any]:
    market = db.get(Market, market_id)
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    snapshot = liquidity_snapshot(market)
    return {
        "market_id": market.id,
        "title": market.title,
        "event": market.event,
        "yes_price": snapshot["yes_price"],
        "no_price": snapshot["no_price"],
        "implied_probability": snapshot["implied_probability"],
        "bid_ask_spread_cents": snapshot["bid_ask_spread_cents"],
        "spread_tier": snapshot["spread_tier"],
        "order_book_depth": snapshot["depth_usd"],
        "order_book": snapshot["order_book"],
        "history": market_history_prices(db, market.id, limit=60),
    }


@router.get("/liquidity/{market_id}")
def get_market_liquidity(market_id: int, db: Session = Depends(get_db)) -> dict[str, Any]:
    market = db.get(Market, market_id)
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    snapshot = liquidity_snapshot(market)
    maker_concentration = round(market.maker_concentration, 2)
    return {
        "market_id": market.id,
        "spread_cents": snapshot["bid_ask_spread_cents"],
        "spread_tier": snapshot["spread_tier"],
        "maker_concentration": maker_concentration,
        "top_maker_share_pct": maker_concentration,
        "liquidity_warning": "Liquidity drying up into expiry"
        if market.end_ts <= datetime.now(timezone.utc) + timedelta(hours=48)
        else None,
        "depth_usd": snapshot["depth_usd"],
    }


async def push_market_snapshot(market_id: int, snapshot: dict[str, Any]) -> None:
    await redis_client.set(f"market:{market_id}:snapshot", str(snapshot), ex=60)
    await redis_client.publish(f"market:{market_id}:odds", str(snapshot))
