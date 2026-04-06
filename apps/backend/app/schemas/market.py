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
    resolution_rules: str | None = None
    collateral_token: str | None = None
    on_chain_address: str | None = None
    created_at: datetime
    updated_at: datetime


class CreateMarketRequest(BaseModel):
    title: str
    description: str
    category: str
    oracle_source: str
    expiry_at: datetime
    resolution_rules: str
    collateral_token: str
    liquidity_amount: float = 0
