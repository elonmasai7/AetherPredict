from datetime import datetime

from pydantic import BaseModel


class MarketResponse(BaseModel):
    id: int
    slug: str
    title: str
    description: str
    category: str
    oracle_source: str
    expiry_at: datetime
    yes_probability: float
    no_probability: float
    ai_confidence: float
    volume: float
    liquidity: float
    resolved: bool
    outcome: str


class CreateMarketRequest(BaseModel):
    title: str
    description: str
    category: str
    oracle_source: str
    expiry_at: datetime
