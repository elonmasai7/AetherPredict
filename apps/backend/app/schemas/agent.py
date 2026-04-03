from pydantic import BaseModel


class AgentResponse(BaseModel):
    agent: str
    status: str
    pnl: float
    interventions: int
    summary: str
    active_trades: int
