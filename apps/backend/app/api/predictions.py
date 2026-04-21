from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import Market, PortfolioPosition
from app.schemas.nba import ClosePredictionRequest, PredictRequest, PredictionResponse
from app.services.auth_service import get_optional_user, get_or_create_wallet_user
from app.services.execution_service import ExecutionService

router = APIRouter(tags=["predictions"])


@router.post("/predict", response_model=PredictionResponse)
def predict(
    payload: PredictRequest,
    db: Session = Depends(get_db),
    user=Depends(get_optional_user),
) -> PredictionResponse:
    if user is None:
        wallet = payload.wallet_address or f"user-{payload.user_id or 'demo'}"
        user = get_or_create_wallet_user(db, wallet)
    market = db.scalar(select(Market).where(Market.id == payload.market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    choice = payload.choice.upper()
    price = market.yes_probability if choice == "YES" else market.no_probability
    trade = ExecutionService(db).execute_prediction(
        user=user,
        market=market,
        side=choice,
        collateral_amount=payload.amount,
        price=price,
        wallet_address=payload.wallet_address or user.wallet_address or "demo-wallet",
        liquidity_preview={"confidence": payload.confidence},
    )
    return PredictionResponse(
        id=trade.id,
        user_id=user.id,
        market_id=trade.market_id,
        choice=trade.side,
        amount=trade.collateral_amount,
        entry_price=trade.price,
        status=trade.status,
        tx_status="simulated" if trade.signed_payload is None else "broadcasting",
    )


@router.get("/positions/{user_id}")
def positions_by_user(user_id: int, db: Session = Depends(get_db)) -> list[dict]:
    rows = db.scalars(
        select(PortfolioPosition).where(PortfolioPosition.user_id == user_id)
    ).all()
    markets = {row.id: row.title for row in db.scalars(select(Market)).all()}
    return [
        {
            "id": row.id,
            "user_id": row.user_id,
            "market_id": row.market_id,
            "market_title": markets.get(row.market_id, "Unknown market"),
            "choice": row.side,
            "amount": row.size * row.avg_price,
            "entry_price": row.avg_price,
            "status": row.status,
            "pnl": row.pnl,
        }
        for row in rows
    ]


@router.post("/close-position")
def close_position(payload: ClosePredictionRequest, db: Session = Depends(get_db)) -> dict:
    position = db.scalar(select(PortfolioPosition).where(PortfolioPosition.id == payload.prediction_id))
    if position is None:
        raise HTTPException(status_code=404, detail="Position not found")
    position.status = "CLOSED"
    db.commit()
    return {"status": "closed", "prediction_id": payload.prediction_id}
