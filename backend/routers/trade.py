from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import get_current_user, get_db
from integrations import AlpacaAuthClient, KalshiAuthClient
from liquidity import simulate_slippage
from models import Market, Position, Trade, User
from routers.markets import liquidity_snapshot, push_market_snapshot, sync_market_quote
from security import decrypt_json


router = APIRouter(tags=["trade"])


class TradeRequest(BaseModel):
    side: str = Field(pattern="^(BUY_YES|BUY_NO|SELL_YES|SELL_NO)$")
    notional: float = Field(ge=1.0, le=10000.0)


@router.post("/trade/{market_id}")
async def trade_market(
    market_id: int,
    payload: TradeRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    market = db.get(Market, market_id)
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    if market.end_ts <= datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Market is expired")

    side = payload.side.upper()
    slippage = simulate_slippage(payload.notional, side, market)
    effective_price = slippage.execution_price
    shares = round(payload.notional / max(effective_price, 0.01), 4)
    cost = payload.notional
    maker_rebate = round(cost * 0.001, 2)

    if side in {"BUY_YES", "BUY_NO"} and float(user.balance) < cost:
        raise HTTPException(status_code=400, detail="Insufficient balance")

    if side == "BUY_YES":
        market.yes_shares += shares
        user.balance = float(user.balance) - cost + maker_rebate
        position_side = "YES"
        trade_multiplier = 1
    elif side == "BUY_NO":
        market.no_shares += shares
        user.balance = float(user.balance) - cost + maker_rebate
        position_side = "NO"
        trade_multiplier = 1
    elif side == "SELL_YES":
        market.yes_shares = max(market.yes_shares - shares, 1)
        user.balance = float(user.balance) + cost
        position_side = "YES"
        trade_multiplier = -1
    else:
        market.no_shares = max(market.no_shares - shares, 1)
        user.balance = float(user.balance) + cost
        position_side = "NO"
        trade_multiplier = -1

    market.total_volume += cost
    market.liquidity_usd = max(market.min_liquidity, market.liquidity_usd + (cost * 0.14))

    position = db.scalar(
        select(Position).where(
            Position.user_id == user.id,
            Position.market_id == market.id,
            Position.side == position_side,
        )
    )
    if position is None:
        position = Position(user_id=user.id, market_id=market.id, side=position_side, shares=0, avg_price=effective_price)
        db.add(position)
    new_shares = position.shares + (shares * trade_multiplier)
    position.shares = max(new_shares, 0)
    if trade_multiplier > 0:
        weighted_cost = (position.avg_price * max(position.shares - shares, 0)) + (effective_price * shares)
        position.avg_price = round(weighted_cost / max(position.shares, 1), 4)
    mark = market.yes_price if position_side == "YES" else market.no_price
    position.unrealized_pnl = round((mark - position.avg_price) * position.shares * 100, 2)

    provider_trade_id = None
    credentials = decrypt_json(user.encrypted_api_credentials)
    if market.provider == "kalshi" and credentials.get("provider") == "kalshi" and credentials.get("api_key") and credentials.get("private_key_pem"):
        client = KalshiAuthClient(credentials["api_key"], credentials["private_key_pem"])
        provider_trade_id = client.get_balance().get("portfolio_balance_id")
    elif credentials.get("provider") == "alpaca":
        account = AlpacaAuthClient(
            api_key_id=credentials.get("api_key"),
            api_secret=credentials.get("api_secret"),
            oauth_token=credentials.get("oauth_token"),
        ).account()
        provider_trade_id = account.get("id")

    trade = Trade(
        user_id=user.id,
        market_id=market.id,
        side=side,
        shares=shares,
        price=effective_price,
        notional=cost,
        slippage_pct=slippage.slippage_pct,
        maker_rebate=maker_rebate,
        provider_trade_id=provider_trade_id,
    )
    db.add(trade)
    db.commit()
    db.refresh(market)
    snapshot = sync_market_quote(db, market)
    await push_market_snapshot(market.id, snapshot)
    return {
        "trade_id": trade.id,
        "market_id": market.id,
        "side": side,
        "shares": shares,
        "execution_price": effective_price,
        "slippage_pct": slippage.slippage_pct,
        "price_impact_pct": slippage.price_impact,
        "maker_rebate": maker_rebate,
        "updated_market": liquidity_snapshot(market),
        "balance": float(user.balance),
    }
