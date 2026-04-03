from pydantic import BaseModel


class PositionResponse(BaseModel):
    market_id: int
    market_title: str
    side: str
    size: float
    avg_price: float
    mark_price: float
    pnl: float
