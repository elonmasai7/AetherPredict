from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import AgentStatus, Dispute, PortfolioPosition, User
from app.schemas.leaderboard import LeaderboardEntry

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])


@router.get("/traders", response_model=list[LeaderboardEntry])
def traders(db: Session = Depends(get_db)) -> list[LeaderboardEntry]:
    rows = db.execute(
        select(
            User.display_name,
            func.coalesce(func.sum(PortfolioPosition.pnl), 0.0).label("score"),
            func.coalesce(func.sum(PortfolioPosition.realized_pnl), 0.0).label("roi"),
            func.coalesce(func.avg(PortfolioPosition.mark_price), 0.0).label("win_rate"),
        )
        .join(PortfolioPosition, PortfolioPosition.user_id == User.id)
        .group_by(User.id)
        .order_by(func.sum(PortfolioPosition.pnl).desc())
    ).all()
    return [
        LeaderboardEntry(
            rank=index + 1,
            name=row.display_name or f"Trader {index + 1}",
            score=float(row.score),
            roi=float(row.roi),
            win_rate=float(row.win_rate) * 100,
            period="all-time",
        )
        for index, row in enumerate(rows)
    ]


@router.get("/agents", response_model=list[LeaderboardEntry])
def agents(db: Session = Depends(get_db)) -> list[LeaderboardEntry]:
    rows = db.scalars(select(AgentStatus).order_by(AgentStatus.pnl.desc())).all()
    return [
        LeaderboardEntry(
            rank=index + 1,
            name=row.agent_key,
            score=row.pnl,
            roi=row.pnl,
            win_rate=min(100.0, row.interventions * 5.0),
            period="all-time",
        )
        for index, row in enumerate(rows)
    ]


@router.get("/jurors", response_model=list[LeaderboardEntry])
def jurors(db: Session = Depends(get_db)) -> list[LeaderboardEntry]:
    rows = db.execute(
        select(
            func.coalesce(Dispute.user_id, 0).label("user_id"),
            func.count(Dispute.id).label("score"),
            func.avg(Dispute.juror_votes_yes + Dispute.juror_votes_no).label("win_rate"),
        )
        .group_by(Dispute.user_id)
        .order_by(func.count(Dispute.id).desc())
    ).all()
    return [
        LeaderboardEntry(
            rank=index + 1,
            name=f"Juror {row.user_id or index + 1}",
            score=float(row.score),
            roi=0.0,
            win_rate=float(row.win_rate or 0),
            period="all-time",
        )
        for index, row in enumerate(rows)
    ]
