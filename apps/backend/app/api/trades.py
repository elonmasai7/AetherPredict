from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import Market, Notification, PortfolioPosition, TradeOrder, TransactionRecord
from app.schemas.trade import CreateTradeRequest, TradeResponse
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/trades", tags=["trades"])


@router.get("", response_model=list[TradeResponse])
def list_trades(db: Session = Depends(get_db), user=Depends(get_current_user)) -> list[TradeResponse]:
    rows = db.scalars(select(TradeOrder).where(TradeOrder.user_id == user.id).order_by(TradeOrder.created_at.desc())).all()
    return [TradeResponse.model_validate(row, from_attributes=True) for row in rows]


@router.post("", response_model=TradeResponse, status_code=201)
def create_trade(payload: CreateTradeRequest, db: Session = Depends(get_db), user=Depends(get_current_user)) -> TradeResponse:
    market = db.scalar(select(Market).where(Market.id == payload.market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")

    shares = round(payload.collateral_amount / max(payload.price, 0.0001), 6)
    trade = TradeOrder(
        user_id=user.id,
        market_id=market.id,
        side=payload.side.upper(),
        order_type=payload.order_type,
        collateral_amount=payload.collateral_amount,
        price=payload.price,
        shares=shares,
        status="SIGNED" if payload.signed_payload else "PENDING_SIGNATURE",
        wallet_address=payload.wallet_address,
        signed_payload=payload.signed_payload,
        tx_hash=None,
        explorer_url=None,
        gas_estimate=0.0012,
        gas_fee_native=None,
    )
    db.add(trade)

    position = PortfolioPosition(
        user_id=user.id,
        market_id=market.id,
        side=payload.side.upper(),
        size=shares,
        avg_price=payload.price,
        mark_price=payload.price,
        realized_pnl=0,
        unrealized_pnl=0,
        pnl=0,
        status="OPEN",
    )
    db.add(position)
    db.add(
        TransactionRecord(
            user_id=user.id,
            trade=trade,
            transaction_type="TRADE",
            asset_symbol=market.collateral_token or "USDC",
            amount=payload.collateral_amount,
            status=trade.status,
            tx_hash=trade.tx_hash,
            explorer_url=trade.explorer_url,
            gas_fee_native=trade.gas_fee_native,
            metadata_json={"market_title": market.title, "side": trade.side},
        )
    )
    db.add(
        Notification(
            user_id=user.id,
            level="info",
            category="trade",
            message=f"Trade {trade.status.lower()} for {market.title}",
            metadata_json={"market_id": market.id, "side": trade.side},
        )
    )
    market.volume += payload.collateral_amount
    db.commit()
    db.refresh(trade)
    return TradeResponse.model_validate(trade, from_attributes=True)
