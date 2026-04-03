from fastapi import APIRouter

from app.schemas.market import CreateMarketRequest, MarketResponse
from app.services.demo_data import demo_markets

router = APIRouter(prefix="/markets", tags=["markets"])


@router.get("", response_model=list[MarketResponse])
def list_markets() -> list[MarketResponse]:
    return [MarketResponse(**market) for market in demo_markets()]


@router.get("/{market_id}", response_model=MarketResponse)
def get_market(market_id: int) -> MarketResponse:
    market = next(item for item in demo_markets() if item["id"] == market_id)
    return MarketResponse(**market)


@router.post("", response_model=MarketResponse)
def create_market(payload: CreateMarketRequest) -> MarketResponse:
    return MarketResponse(
        id=999,
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
