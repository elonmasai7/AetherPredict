from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends

from app.db.session import get_db
from app.models.entities import AgentStatus
from app.schemas.agent import AgentResponse

router = APIRouter(prefix="/agents", tags=["agents"])


@router.get("")
def list_agents(db: Session = Depends(get_db)) -> list[AgentResponse]:
    agents = db.scalars(select(AgentStatus).order_by(AgentStatus.interventions.desc())).all()
    return [
        AgentResponse(
            agent=agent.agent_key,
            status=agent.status,
            pnl=agent.pnl,
            interventions=agent.interventions,
            summary=agent.summary,
            active_trades=agent.active_trades,
        )
        for agent in agents
    ]
