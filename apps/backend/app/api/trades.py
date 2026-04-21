import asyncio

import asyncio

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import Market, Notification, PortfolioPosition, TradeOrder, TransactionRecord
from app.core.config import settings
from app.schemas.trade import CreateTradeRequest, PrepareTradeRequest, PrepareTradeResponse, TradeResponse
from app.services.auth_service import get_current_user, get_optional_user, get_or_create_wallet_user
from app.services.copy_trading_service import CopyTradingService
from app.services.blockchain_service import BlockchainService
from app.services.copy_trading_service import CopyTradingService
from app.services.liquidity_engine import LiquidityIntelligenceService
from app.services.execution_service import ExecutionService

router = APIRouter(prefix="/trades", tags=["trades"])


@router.get("", response_model=list[TradeResponse])
def list_trades(db: Session = Depends(get_db), user=Depends(get_current_user)) -> list[TradeResponse]:
    rows = db.scalars(select(TradeOrder).where(TradeOrder.user_id == user.id).order_by(TradeOrder.created_at.desc())).all()
    return [TradeResponse.model_validate(row, from_attributes=True) for row in rows]


@router.post("/prepare", response_model=PrepareTradeResponse, status_code=201)
def prepare_trade(payload: PrepareTradeRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> PrepareTradeResponse:
    if user is None:
        user = get_or_create_wallet_user(db, payload.wallet_address)
    market = db.scalar(select(Market).where(Market.id == payload.market_id))
    if market is None or not market.on_chain_address:
        raise HTTPException(status_code=404, detail="Market not available on-chain")

    trade = TradeOrder(
        user_id=user.id,
        market_id=market.id,
        side=payload.side.upper(),
        order_type="MARKET",
        collateral_amount=payload.collateral_amount,
        price=market.yes_probability if payload.side.upper() == "YES" else market.no_probability,
        shares=0,
        status="AWAITING_WALLET_SIGNATURE",
        wallet_address=payload.wallet_address,
    )
    db.add(trade)
    db.commit()
    db.refresh(trade)

    chain = BlockchainService()
    value_wei = int(payload.collateral_amount * 1e18)
    if payload.side.upper() == "YES":
        built = chain.build_buy_yes(market.on_chain_address, payload.wallet_address, value_wei)
    else:
        built = chain.build_buy_no(market.on_chain_address, payload.wallet_address, value_wei)

    tx = {
        "to": built.to,
        "data": built.data,
        "value": hex(built.value),
        "gas": hex(built.gas) if built.gas else None,
        "gasPrice": hex(built.gas_price) if built.gas_price else None,
        "nonce": hex(built.nonce) if built.nonce is not None else None,
        "chainId": built.chain_id,
    }
    preview = LiquidityIntelligenceService(db).build_slippage_preview(
        market,
        payload.side,
        payload.collateral_amount,
    )
    return PrepareTradeResponse(trade_id=trade.id, tx=tx, liquidity_preview=preview)


@router.post("", response_model=TradeResponse, status_code=201)
def create_trade(payload: CreateTradeRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> TradeResponse:
    if user is None:
        user = get_or_create_wallet_user(db, payload.wallet_address)
    market = db.scalar(select(Market).where(Market.id == payload.market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")

    liquidity_service = LiquidityIntelligenceService(db)
    liquidity_preview = liquidity_service.build_slippage_preview(
        market,
        payload.side,
        payload.collateral_amount,
    )
    trade = ExecutionService(db).execute_prediction(
        user=user,
        market=market,
        side=payload.side.upper(),
        collateral_amount=payload.collateral_amount,
        price=payload.price,
        wallet_address=payload.wallet_address,
        order_type=payload.order_type,
        signed_payload=payload.signed_payload,
        liquidity_preview=liquidity_preview,
    )
    try:
        copy_service = CopyTradingService(db)
        copied_rows = copy_service.process_source_trade(trade)
        if copied_rows:
            status_breakdown: dict[str, int] = {}
            for row in copied_rows:
                status_breakdown[row.status] = status_breakdown.get(row.status, 0) + 1
            asyncio.create_task(
                copy_service.publish_copy_event(
                    "source_trade_copied",
                    {
                        "source_trade_id": trade.id,
                        "market_id": trade.market_id,
                        "copied_count": len(copied_rows),
                        "status_breakdown": status_breakdown,
                    },
                )
            )
    except Exception:
        pass
    response = TradeResponse.model_validate(trade, from_attributes=True)
    response.liquidity_preview = liquidity_preview
    return response


@router.post("/{trade_id}/submit", response_model=TradeResponse)
def submit_trade_hash(trade_id: int, payload: dict, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> TradeResponse:
    if user is None:
        wallet_address = payload.get("wallet_address")
        if not wallet_address:
            raise HTTPException(status_code=401, detail="wallet_address required")
        user = get_or_create_wallet_user(db, wallet_address)
    trade = db.scalar(select(TradeOrder).where(TradeOrder.id == trade_id, TradeOrder.user_id == user.id))
    if trade is None:
        raise HTTPException(status_code=404, detail="Trade not found")
    tx_hash = payload.get("tx_hash")
    if not tx_hash:
        raise HTTPException(status_code=400, detail="tx_hash required")
    if not isinstance(tx_hash, str) or not tx_hash.startswith("0x"):
        raise HTTPException(status_code=400, detail="Invalid tx_hash format")
    trade.tx_hash = tx_hash
    trade.status = "PENDING_CONFIRMATION"
    tx_row = TransactionRecord(
        user_id=user.id,
        trade_id=trade.id,
        transaction_type="TRADE",
        asset_symbol="HSK",
        amount=trade.collateral_amount,
        status="PENDING_CONFIRMATION",
        tx_hash=tx_hash,
        explorer_url=f"{settings.hashkey_explorer_url}/tx/{tx_hash}",
        metadata_json={"market_id": trade.market_id},
    )
    db.add(tx_row)
    db.commit()
    db.refresh(trade)
    response = TradeResponse.model_validate(trade, from_attributes=True)
    response.liquidity_preview = trade.metadata_json.get("liquidity_preview")
    return response
