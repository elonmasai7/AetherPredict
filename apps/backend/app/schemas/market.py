from datetime import datetime

from pydantic import BaseModel


class LiquiditySummaryResponse(BaseModel):
    best_yes_bid: float
    best_yes_ask: float
    implied_no_spread: dict
    spread_width_cents: int
    liquidity_label: str
    risk_label: str


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
    liquidity_intelligence: LiquiditySummaryResponse | None = None


class LiquidityDetailResponse(BaseModel):
    market_id: int
    liquidity_intelligence: dict


class LiquidityDashboardResponse(BaseModel):
    generated_at: datetime
    market_count: int
    market_rankings: list[dict]
    spread_leaderboard: list[dict]
    most_liquid_markets: list[dict]
    least_liquid_markets: list[dict]
    lp_distribution: list[dict]
    slippage_heatmap: list[dict]


class CreateMarketRequest(BaseModel):
    title: str
    description: str
    category: str
    oracle_source: str
    expiry_at: datetime
    resolution_rules: str
    collateral_token: str
    liquidity_amount: float = 0
    wallet_address: str | None = None
