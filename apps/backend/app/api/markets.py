from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import AssetSnapshot, Market, Notification
from app.schemas.asset import AssetSnapshotResponse
from app.schemas.market import CreateMarketRequest, MarketResponse
from app.services.auth_service import get_current_user
from app.services.market_stream import publish_market_update

router = APIRouter(prefix="/markets", tags=["markets"])


@router.get("", response_model=list[MarketResponse])
def list_markets(db: Session = Depends(get_db)) -> list[MarketResponse]:
    markets = db.scalars(select(Market).order_by(Market.updated_at.desc())).all()
    return [MarketResponse.model_validate(market, from_attributes=True) for market in markets]


@router.get("/assets", response_model=list[AssetSnapshotResponse])
def list_assets(db: Session = Depends(get_db)) -> list[AssetSnapshotResponse]:
    assets = db.scalars(select(AssetSnapshot).order_by(AssetSnapshot.market_cap.desc())).all()
    return [AssetSnapshotResponse.model_validate(asset, from_attributes=True) for asset in assets]


@router.get("/{market_id}", response_model=MarketResponse)
def get_market(market_id: int, db: Session = Depends(get_db)) -> MarketResponse:
    market = db.scalar(select(Market).where(Market.id == market_id))
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    return MarketResponse.model_validate(market, from_attributes=True)


@router.post("", response_model=MarketResponse, status_code=201)
async def create_market(
    payload: CreateMarketRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> MarketResponse:
    market = Market(
        slug=payload.title.lower().replace(" ", "-"),
        title=payload.title,
        description=payload.description,
        category=payload.category,
        oracle_source=payload.oracle_source,
        expiry_at=payload.expiry_at,
        yes_probability=0.5,
        no_probability=0.5,
        ai_confidence=0.5,
        volume=0,
        liquidity=payload.liquidity_amount,
        resolved=False,
        outcome="PENDING",
        resolution_rules=payload.resolution_rules,
        collateral_token=payload.collateral_token,
        creator_user_id=user.id,
        metadata_json={"creation_mode": "api"},
    )
    db.add(market)
    db.add(
        Notification(
            user_id=user.id,
            level="info",
            category="market",
            message=f"Created market {payload.title}",
            metadata_json={"title": payload.title},
        )
    )
    db.commit()
    db.refresh(market)
    await publish_market_update(db, market)
    return MarketResponse.model_validate(market, from_attributes=True)
