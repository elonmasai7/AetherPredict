from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.models.entities import ChainTransaction, Market
from app.schemas.common import MessageResponse
from app.services.auth_service import get_current_user, get_optional_user, get_or_create_wallet_user

router = APIRouter(prefix="/chain-tx", tags=["chain-tx"])


@router.post("/market-create", response_model=MessageResponse)
def create_market_tx(payload: dict, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> MessageResponse:
    if user is None:
        wallet_address = payload.get("wallet_address")
        if not wallet_address:
            raise HTTPException(status_code=401, detail="wallet_address required")
        user = get_or_create_wallet_user(db, wallet_address)
    market_id = payload.get("market_id")
    if not market_id:
        raise HTTPException(status_code=400, detail="market_id required")
    market = db.scalar(select(Market).where(Market.id == market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    tx = ChainTransaction(
        user_id=user.id,
        market_id=market.id,
        tx_type="MARKET_CREATE",
        status="AWAITING_WALLET_SIGNATURE",
        metadata_json={"title": market.title},
    )
    db.add(tx)
    db.commit()
    return MessageResponse(message=str(tx.id))


@router.post("/dispute", response_model=MessageResponse)
def create_dispute_tx(payload: dict, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> MessageResponse:
    if user is None:
        wallet_address = payload.get("wallet_address")
        if not wallet_address:
            raise HTTPException(status_code=401, detail="wallet_address required")
        user = get_or_create_wallet_user(db, wallet_address)
    market_id = payload.get("market_id")
    if not market_id:
        raise HTTPException(status_code=400, detail="market_id required")
    market = db.scalar(select(Market).where(Market.id == market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    tx = ChainTransaction(
        user_id=user.id,
        market_id=market.id,
        tx_type="DISPUTE",
        status="AWAITING_WALLET_SIGNATURE",
        metadata_json={"evidence_uri": payload.get("evidence_uri")},
    )
    db.add(tx)
    db.commit()
    return MessageResponse(message=str(tx.id))


@router.post("/{tx_id}/submit", response_model=MessageResponse)
def submit_chain_tx(tx_id: int, payload: dict, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> MessageResponse:
    if user is None:
        wallet_address = payload.get("wallet_address")
        if not wallet_address:
            raise HTTPException(status_code=401, detail="wallet_address required")
        user = get_or_create_wallet_user(db, wallet_address)
    tx_hash = payload.get("tx_hash")
    if not tx_hash:
        raise HTTPException(status_code=400, detail="tx_hash required")
    chain_tx = db.scalar(select(ChainTransaction).where(ChainTransaction.id == tx_id, ChainTransaction.user_id == user.id))
    if chain_tx is None:
        raise HTTPException(status_code=404, detail="chain tx not found")
    chain_tx.tx_hash = tx_hash
    chain_tx.status = "PENDING_CONFIRMATION"
    chain_tx.explorer_url = f"{settings.hashkey_explorer_url}/tx/{tx_hash}"
    db.commit()
    return MessageResponse(message="submitted")
