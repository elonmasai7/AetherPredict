from datetime import datetime

from pydantic import BaseModel


class PositionResponse(BaseModel):
    market_id: int
    market_title: str
    side: str
    size: float
    avg_price: float
    mark_price: float
    pnl: float
    realized_pnl: float = 0
    unrealized_pnl: float = 0
    status: str = "OPEN"
    opened_at: datetime | None = None
