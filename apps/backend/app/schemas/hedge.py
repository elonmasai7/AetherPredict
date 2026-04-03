from pydantic import BaseModel


class AutoHedgeRequest(BaseModel):
    market_id: str
    current_side: str
    position_size: float
    enable: bool


class AutoHedgeResponse(BaseModel):
    enabled: bool
    hedge_ratio: float
    protection_score: int
    estimated_loss_reduction: float
