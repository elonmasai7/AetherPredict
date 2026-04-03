from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends

from app.db.session import get_db
from app.models.entities import Market, PortfolioPosition
from app.schemas.hedge import AutoHedgeRequest, AutoHedgeResponse
from app.schemas.portfolio import PositionResponse
from app.schemas.risk import ExposureSlice, PerformancePoint, PortfolioRiskResponse
from app.services.platform_data import build_exposure, build_performance

router = APIRouter(prefix="/portfolio", tags=["portfolio"])


@router.get("/positions", response_model=list[PositionResponse])
def positions(db: Session = Depends(get_db)) -> list[PositionResponse]:
    rows = db.execute(
        select(
            PortfolioPosition.market_id,
            PortfolioPosition.side,
            PortfolioPosition.size,
            PortfolioPosition.avg_price,
            PortfolioPosition.mark_price,
            PortfolioPosition.pnl,
        ).order_by(PortfolioPosition.pnl.desc())
    ).all()
    markets = {market.id: market.title for market in db.scalars(select(Market)).all()}
    return [
        PositionResponse(
            market_id=row.market_id,
            market_title=markets.get(row.market_id, "Unknown market"),
            side=row.side,
            size=row.size,
            avg_price=row.avg_price,
            mark_price=row.mark_price,
            pnl=row.pnl,
        )
        for row in rows
    ]


@router.get("/risk", response_model=PortfolioRiskResponse)
def risk(db: Session = Depends(get_db)) -> PortfolioRiskResponse:
    positions_list = db.scalars(select(PortfolioPosition)).all()
    total_exposure = sum(position.size * position.mark_price for position in positions_list)
    max_loss = round(total_exposure * 0.31, 2)
    var_95 = round(total_exposure * 0.24, 2)
    volatility_score = round(sum(abs(position.mark_price - position.avg_price) for position in positions_list) * 100, 2)
    confidence_weighted = round(total_exposure * 0.68, 2)
    risk_score = "HIGH" if total_exposure > 3000 else "MEDIUM"
    return PortfolioRiskResponse(
        total_exposure=round(total_exposure, 2),
        risk_score=risk_score,
        max_loss=max_loss,
        var_95=var_95,
        volatility_score=volatility_score,
        confidence_weighted_risk=confidence_weighted,
    )


@router.get("/exposure", response_model=list[ExposureSlice])
def exposure(db: Session = Depends(get_db)) -> list[ExposureSlice]:
    markets = db.scalars(select(Market)).all()
    positions_list = db.scalars(select(PortfolioPosition)).all()
    return [ExposureSlice(**item) for item in build_exposure(markets, positions_list)]


@router.get("/performance", response_model=list[PerformancePoint])
def performance() -> list[PerformancePoint]:
    return [PerformancePoint(**item) for item in build_performance()]


@router.post("/auto-hedge", response_model=AutoHedgeResponse)
def auto_hedge(payload: AutoHedgeRequest) -> AutoHedgeResponse:
    hedge_ratio = 0.2 if payload.enable else 0.0
    protection_score = 74 if payload.enable else 0
    estimated_loss_reduction = round(payload.position_size * hedge_ratio * 0.35, 2)
    return AutoHedgeResponse(
        enabled=payload.enable,
        hedge_ratio=hedge_ratio,
        protection_score=protection_score,
        estimated_loss_reduction=estimated_loss_reduction,
    )
