from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, HTTPException

from app.db.session import get_db
from app.models.entities import Market
from app.schemas.market import CreateMarketRequest, MarketResponse
from app.services.market_stream import publish_market_update

router = APIRouter(prefix="/markets", tags=["markets"])


@router.get("", response_model=list[MarketResponse])
def list_markets(db: Session = Depends(get_db)) -> list[MarketResponse]:
    markets = db.scalars(select(Market).order_by(Market.volume.desc())).all()
    return [MarketResponse.model_validate(market, from_attributes=True) for market in markets]


@router.get("/{market_id}", response_model=MarketResponse)
def get_market(market_id: int, db: Session = Depends(get_db)) -> MarketResponse:
    market = db.scalar(select(Market).where(Market.id == market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    return MarketResponse.model_validate(market, from_attributes=True)


@router.post("", response_model=MarketResponse, status_code=201)
async def create_market(payload: CreateMarketRequest, db: Session = Depends(get_db)) -> MarketResponse:
    market = Market(
        slug=payload.title.lower().replace(" ", "-"),
        title=payload.title,
        description=payload.description,
        category=payload.category,
        oracle_source=payload.oracle_source,
        expiry_at=payload.expiry_at,
        yes_probability=0.5,
        no_probability=0.5,
        ai_confidence=0.7,
        volume=0,
        liquidity=0,
        resolved=False,
        outcome="PENDING",
    )
    db.add(market)
    db.commit()
    db.refresh(market)
    await publish_market_update(db, market)
    return MarketResponse.model_validate(market, from_attributes=True)
