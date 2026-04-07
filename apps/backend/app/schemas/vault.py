from datetime import datetime

from pydantic import BaseModel, Field


class VaultCreateRequest(BaseModel):
    title: str
    strategy_description: str
    risk_profile: str = "MEDIUM"
    manager_type: str = "AI"
    collateral_token_address: str | None = None
    collateral_token_decimals: int | None = None
    auto_execute_enabled: bool | None = None
    target_market_ids: list[int] = Field(default_factory=list)
    ai_confidence_score: float = 0.5
    management_fee_bps: int = 200
    performance_fee_bps: int = 1500


class VaultAutoExecuteUpdateRequest(BaseModel):
    auto_execute_enabled: bool


class VaultResponse(BaseModel):
    id: int
    title: str
    slug: str
    strategy_description: str
    risk_profile: str
    collateral_token_decimals: int
    auto_execute_enabled: bool
    target_markets: list[str]
    performance_history: list[dict]
    current_allocation: dict
    ai_confidence_score: float
    manager_type: str
    roi_7d: float
    roi_30d: float
    win_rate: float
    volatility: float
    active_subscribers: int
    total_aum: float
    status: str


class VaultSubscriptionRequest(BaseModel):
    vault_id: int
    wallet_address: str
    amount: float


class VaultTradeResponse(BaseModel):
    id: int
    vault_id: int
    market_id: int
    side: str
    allocation: float
    amount: float
    price: float
    confidence: float
    reasoning: str
    status: str
    tx_hash: str | None = None
    chain_tx_id: int | None = None
    created_at: datetime


class VaultPerformancePoint(BaseModel):
    timestamp: datetime
    nav_per_share: float
    aum: float
    roi_period: float
    win_rate: float
    volatility: float
    confidence: float


class ExecuteVaultStrategyRequest(BaseModel):
    vault_id: str
    market_data: dict
    portfolio_state: dict


class ExecuteVaultStrategyResponse(BaseModel):
    action: str
    market: str
    allocation: float
    confidence: float
    reasoning: str
