from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends

from app.db.session import get_db
from app.models.entities import Market, PortfolioPosition
from app.schemas.portfolio import PositionResponse

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
        )
        .order_by(PortfolioPosition.pnl.desc())
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
