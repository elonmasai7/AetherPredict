from datetime import datetime

from pydantic import BaseModel


class AssetSnapshotResponse(BaseModel):
    symbol: str
    name: str
    price_usd: float
    change_24h: float
    volume_24h: float
    market_cap: float
    high_24h: float
    low_24h: float
    volatility_pct: float
    order_flow_score: float
    source: str
    recorded_at: datetime
