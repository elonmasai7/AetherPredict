from datetime import datetime

from pydantic import BaseModel, Field


class FollowTraderRequest(BaseModel):
    source_user_id: int
    source_type: str = "TRADER"
    allocation_pct: float = 0.2
    max_loss_pct: float = 0.08
    risk_level: str = "MEDIUM"
    auto_stop_threshold: float = 0.08
    max_follower_exposure: float = 5000
    trader_commission_bps: int = 1500
    platform_fee_bps: int = 200
    allowed_market_ids: list[int] = Field(default_factory=list)


class UpdateCopySettingsRequest(BaseModel):
    allocation_pct: float | None = None
    max_loss_pct: float | None = None
    risk_level: str | None = None
    auto_stop_threshold: float | None = None
    allowed_market_ids: list[int] | None = None


class CopyRelationshipResponse(BaseModel):
    id: int
    follower_user_id: int
    source_user_id: int
    source_type: str
    status: str
    allocation_pct: float
    max_loss_pct: float
    risk_level: str
    auto_stop_threshold: float
    max_follower_exposure: float
    trader_commission_bps: int
    platform_fee_bps: int
    allowed_market_ids: list[int]


class CopiedTradeResponse(BaseModel):
    id: int
    relationship_id: int
    source_trade_id: int
    follower_trade_id: int | None
    market_id: int
    copied_allocation: float
    copied_amount: float
    status: str
    reason: str | None = None
    created_at: datetime


class CopyPerformanceSnapshotResponse(BaseModel):
    timestamp: datetime
    roi_7d: float
    roi_30d: float
    lifetime_accuracy: float
    copied_followers: int
    assets_copied: float
    drawdown_pct: float


class CopyPortfolioSummary(BaseModel):
    copied_traders: int
    live_copied_positions: int
    copied_roi: float
    active_alerts: int
    performance_by_trader: list[dict]
