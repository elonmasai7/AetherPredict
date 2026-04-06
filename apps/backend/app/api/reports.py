from fastapi import APIRouter, Depends, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import PortfolioPosition, TradeOrder
from app.services.auth_service import get_current_user
from app.services.reporting import render_csv, render_simple_pdf

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/trades.csv")
def trade_csv(db: Session = Depends(get_db), user=Depends(get_current_user)) -> Response:
    rows = db.scalars(select(TradeOrder).where(TradeOrder.user_id == user.id).order_by(TradeOrder.created_at.desc())).all()
    payload = render_csv(
        [
            {
                "id": row.id,
                "market_id": row.market_id,
                "side": row.side,
                "collateral_amount": row.collateral_amount,
                "price": row.price,
                "shares": row.shares,
                "status": row.status,
                "created_at": row.created_at.isoformat(),
            }
            for row in rows
        ]
    )
    return Response(content=payload, media_type="text/csv")


@router.get("/portfolio.pdf")
def portfolio_pdf(db: Session = Depends(get_db), user=Depends(get_current_user)) -> Response:
    positions = db.scalars(select(PortfolioPosition).where(PortfolioPosition.user_id == user.id)).all()
    lines = [
        f"Market {row.market_id} {row.side} size={row.size:.4f} mark={row.mark_price:.4f} pnl={row.pnl:.2f}"
        for row in positions
    ] or ["No active positions"]
    payload = render_simple_pdf("AetherPredict Portfolio Report", lines)
    return Response(content=payload, media_type="application/pdf")
