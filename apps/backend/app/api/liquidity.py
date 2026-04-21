from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import Market
from app.schemas.nba import AddLiquidityRequest, LiquidityResponse
from app.services.liquidity_engine import LiquidityIntelligenceService

router = APIRouter(prefix="/liquidity", tags=["liquidity"])


@router.get("/{market_id}", response_model=LiquidityResponse)
def get_liquidity(market_id: int, db: Session = Depends(get_db)) -> LiquidityResponse:
    market = db.scalar(select(Market).where(Market.id == market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    snapshot = LiquidityIntelligenceService(db).build_market_snapshot(market)
    detail = snapshot.detail
    ladder = detail["depth"].get("order_distribution", [])
    return LiquidityResponse(
        market_id=market_id,
        liquidity=market.liquidity,
        spread=snapshot.summary["spread_width_cents"] / 100,
        depth=detail["depth"]["yes_depth_total"] + detail["depth"]["no_depth_total"],
        slippage=detail["retail"]["micro_trade_preview"]["slippage_pct"],
        liquidity_score=detail["liquidity_score"],
        bids=ladder[:4],
        asks=ladder[-4:],
    )


@router.post("/add")
def add_liquidity(payload: AddLiquidityRequest, db: Session = Depends(get_db)) -> dict:
    market = db.scalar(select(Market).where(Market.id == payload.market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    market.liquidity += payload.amount
    db.commit()
    return {"status": "accepted", "market_id": market.id, "liquidity": market.liquidity}
