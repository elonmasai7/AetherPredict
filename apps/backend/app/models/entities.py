from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    wallet_address: Mapped[str | None] = mapped_column(String(120), nullable=True, index=True)
    role: Mapped[str] = mapped_column(String(50), default="user")
    wallet_nonce: Mapped[str | None] = mapped_column(String(120), nullable=True)
    display_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    notification_preferences: Mapped[dict] = mapped_column(JSON, default=dict)
    account_preferences: Mapped[dict] = mapped_column(JSON, default=dict)
    workspace_preferences: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    positions: Mapped[list["PortfolioPosition"]] = relationship(back_populates="user")
    trades: Mapped[list["TradeOrder"]] = relationship(back_populates="user")
    refresh_tokens: Mapped[list["RefreshToken"]] = relationship(back_populates="user")
    notifications: Mapped[list["Notification"]] = relationship(back_populates="user")
    device_tokens: Mapped[list["DeviceToken"]] = relationship(back_populates="user")
    watchlists: Mapped[list["Watchlist"]] = relationship(back_populates="user")
    workspaces: Mapped[list["Workspace"]] = relationship(back_populates="user")
    notes: Mapped[list["Note"]] = relationship(back_populates="user")
    ai_signals: Mapped[list["AISignal"]] = relationship(back_populates="user")
    wallet_balances: Mapped[list["WalletBalance"]] = relationship(back_populates="user")
    comments: Mapped[list["DiscussionComment"]] = relationship(back_populates="user")
    managed_vaults: Mapped[list["StrategyVault"]] = relationship(back_populates="manager")
    vault_subscriptions: Mapped[list["VaultSubscription"]] = relationship(back_populates="user")
    copy_following: Mapped[list["CopyRelationship"]] = relationship(
        back_populates="follower",
        foreign_keys="CopyRelationship.follower_user_id",
    )
    copy_followers: Mapped[list["CopyRelationship"]] = relationship(
        back_populates="source",
        foreign_keys="CopyRelationship.source_user_id",
    )
    strategy_engine_strategies: Mapped[list["StrategyEngineStrategy"]] = relationship(
        back_populates="user"
    )


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    token_hash: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    user: Mapped["User"] = relationship(back_populates="refresh_tokens")


class Market(Base):
    __tablename__ = "markets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    slug: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str] = mapped_column(Text)
    category: Mapped[str] = mapped_column(String(80))
    oracle_source: Mapped[str] = mapped_column(String(255))
    expiry_at: Mapped[datetime] = mapped_column(DateTime)
    yes_probability: Mapped[float] = mapped_column(Float, default=0.5)
    no_probability: Mapped[float] = mapped_column(Float, default=0.5)
    ai_confidence: Mapped[float] = mapped_column(Float, default=0.75)
    volume: Mapped[float] = mapped_column(Float, default=0)
    liquidity: Mapped[float] = mapped_column(Float, default=0)
    resolved: Mapped[bool] = mapped_column(Boolean, default=False)
    outcome: Mapped[str] = mapped_column(String(20), default="PENDING")
    resolution_rules: Mapped[str | None] = mapped_column(Text, nullable=True)
    collateral_token: Mapped[str | None] = mapped_column(String(64), nullable=True)
    on_chain_address: Mapped[str | None] = mapped_column(String(120), nullable=True)
    creator_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    positions: Mapped[list["PortfolioPosition"]] = relationship(back_populates="market")
    disputes: Mapped[list["Dispute"]] = relationship(back_populates="market")
    comments: Mapped[list["DiscussionComment"]] = relationship(back_populates="market")
    signals: Mapped[list["AISignal"]] = relationship(back_populates="market")
    trades: Mapped[list["TradeOrder"]] = relationship(back_populates="market")
    watchlist_items: Mapped[list["WatchlistItem"]] = relationship(back_populates="market")


class PortfolioPosition(Base):
    __tablename__ = "portfolio_positions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    side: Mapped[str] = mapped_column(String(10))
    size: Mapped[float] = mapped_column(Float)
    avg_price: Mapped[float] = mapped_column(Float)
    mark_price: Mapped[float] = mapped_column(Float)
    realized_pnl: Mapped[float] = mapped_column(Float, default=0)
    unrealized_pnl: Mapped[float] = mapped_column(Float, default=0)
    pnl: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(30), default="OPEN")
    opened_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    market: Mapped["Market"] = relationship(back_populates="positions")
    user: Mapped["User"] = relationship(back_populates="positions")


class TradeOrder(Base):
    __tablename__ = "trade_orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    side: Mapped[str] = mapped_column(String(10))
    order_type: Mapped[str] = mapped_column(String(20), default="MARKET")
    collateral_amount: Mapped[float] = mapped_column(Float)
    price: Mapped[float] = mapped_column(Float)
    shares: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(30), default="PENDING_SIGNATURE")
    wallet_address: Mapped[str | None] = mapped_column(String(120), nullable=True)
    signed_payload: Mapped[str | None] = mapped_column(Text, nullable=True)
    tx_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    explorer_url: Mapped[str | None] = mapped_column(String(255), nullable=True)
    gas_estimate: Mapped[float | None] = mapped_column(Float, nullable=True)
    gas_fee_native: Mapped[float | None] = mapped_column(Float, nullable=True)
    failure_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="trades")
    market: Mapped["Market"] = relationship(back_populates="trades")
    transactions: Mapped[list["TransactionRecord"]] = relationship(back_populates="trade")


class TransactionRecord(Base):
    __tablename__ = "transaction_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    trade_id: Mapped[int | None] = mapped_column(ForeignKey("trade_orders.id"), nullable=True, index=True)
    transaction_type: Mapped[str] = mapped_column(String(40))
    asset_symbol: Mapped[str] = mapped_column(String(20))
    amount: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(30), default="PENDING")
    tx_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    explorer_url: Mapped[str | None] = mapped_column(String(255), nullable=True)
    gas_fee_native: Mapped[float | None] = mapped_column(Float, nullable=True)
    block_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    gas_used: Mapped[int | None] = mapped_column(Integer, nullable=True)
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    event_logs: Mapped[dict] = mapped_column(JSON, default=dict)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    trade: Mapped[TradeOrder | None] = relationship(back_populates="transactions")


class AgentStatus(Base):
    __tablename__ = "agent_statuses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    agent_key: Mapped[str] = mapped_column(String(80), unique=True)
    status: Mapped[str] = mapped_column(String(40))
    interventions: Mapped[int] = mapped_column(Integer, default=0)
    pnl: Mapped[float] = mapped_column(Float, default=0)
    summary: Mapped[str] = mapped_column(Text)
    active_trades: Mapped[int] = mapped_column(Integer, default=0)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Dispute(Base):
    __tablename__ = "disputes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    status: Mapped[str] = mapped_column(String(40), default="OPEN")
    evidence_url: Mapped[str] = mapped_column(String(255))
    ai_summary: Mapped[str] = mapped_column(Text)
    juror_votes_yes: Mapped[int] = mapped_column(Integer, default=0)
    juror_votes_no: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    market: Mapped["Market"] = relationship(back_populates="disputes")


class DiscussionComment(Base):
    __tablename__ = "discussion_comments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    author: Mapped[str] = mapped_column(String(120))
    content: Mapped[str] = mapped_column(Text)
    evidence_url: Mapped[str | None] = mapped_column(String(255), nullable=True)
    parent_id: Mapped[int | None] = mapped_column(ForeignKey("discussion_comments.id"), nullable=True)
    upvotes: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped[User | None] = relationship(back_populates="comments")
    market: Mapped["Market"] = relationship(back_populates="comments")


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    level: Mapped[str] = mapped_column(String(30))
    category: Mapped[str] = mapped_column(String(50))
    message: Mapped[str] = mapped_column(Text)
    read: Mapped[bool] = mapped_column(Boolean, default=False)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped[User | None] = relationship(back_populates="notifications")


class DeviceToken(Base):
    __tablename__ = "device_tokens"
    __table_args__ = (UniqueConstraint("user_id", "token", name="uq_device_tokens_user_token"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    token: Mapped[str] = mapped_column(String(255))
    platform: Mapped[str] = mapped_column(String(30), default="unknown")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="device_tokens")


class StrategyEngineStrategy(Base):
    __tablename__ = "strategy_engine_strategies"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    public_id: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(255))
    prompt: Mapped[str] = mapped_column(Text)
    template_key: Mapped[str] = mapped_column(String(80), index=True)
    template_name: Mapped[str] = mapped_column(String(160))
    stage: Mapped[str] = mapped_column(String(80), default="Scaffolded", index=True)
    market: Mapped[str] = mapped_column(String(255))
    confidence: Mapped[float] = mapped_column(Float, default=0.5)
    owner: Mapped[str] = mapped_column(String(160))
    status: Mapped[str] = mapped_column(String(40), default="Draft", index=True)
    project_name: Mapped[str] = mapped_column(String(180))
    project_path: Mapped[str] = mapped_column(String(255))
    automation_modes_json: Mapped[dict] = mapped_column(JSON, default=list)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="strategy_engine_strategies")
    runs: Mapped[list["StrategyEngineRun"]] = relationship(back_populates="strategy", cascade="all, delete-orphan")
    logs: Mapped[list["StrategyEngineLog"]] = relationship(back_populates="strategy", cascade="all, delete-orphan")
    exports: Mapped[list["StrategyEngineExport"]] = relationship(back_populates="strategy", cascade="all, delete-orphan")
    ranking: Mapped["StrategyEngineRanking | None"] = relationship(back_populates="strategy", uselist=False, cascade="all, delete-orphan")


class StrategyEngineRun(Base):
    __tablename__ = "strategy_engine_runs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    strategy_id: Mapped[int] = mapped_column(ForeignKey("strategy_engine_strategies.id"), index=True)
    run_type: Mapped[str] = mapped_column(String(60), index=True)
    stage: Mapped[str] = mapped_column(String(80))
    status: Mapped[str] = mapped_column(String(40))
    confidence: Mapped[float] = mapped_column(Float, default=0.5)
    is_current: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    pipeline_json: Mapped[dict] = mapped_column(JSON, default=list)
    project_files_json: Mapped[dict] = mapped_column(JSON, default=list)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    strategy: Mapped["StrategyEngineStrategy"] = relationship(back_populates="runs")
    logs: Mapped[list["StrategyEngineLog"]] = relationship(back_populates="run")


class StrategyEngineLog(Base):
    __tablename__ = "strategy_engine_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    strategy_id: Mapped[int] = mapped_column(ForeignKey("strategy_engine_strategies.id"), index=True)
    run_id: Mapped[int | None] = mapped_column(ForeignKey("strategy_engine_runs.id"), nullable=True, index=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)
    stage: Mapped[str] = mapped_column(String(80), index=True)
    message: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(40))
    confidence: Mapped[float] = mapped_column(Float, default=0.5)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    strategy: Mapped["StrategyEngineStrategy"] = relationship(back_populates="logs")
    run: Mapped["StrategyEngineRun | None"] = relationship(back_populates="logs")


class StrategyEngineExport(Base):
    __tablename__ = "strategy_engine_exports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    strategy_id: Mapped[int] = mapped_column(ForeignKey("strategy_engine_strategies.id"), index=True)
    export_label: Mapped[str] = mapped_column(String(255), index=True)
    archive_format: Mapped[str | None] = mapped_column(String(20), nullable=True)
    file_count: Mapped[int] = mapped_column(Integer, default=0)
    file_manifest_json: Mapped[dict] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)

    strategy: Mapped["StrategyEngineStrategy"] = relationship(back_populates="exports")


class StrategyEngineRanking(Base):
    __tablename__ = "strategy_engine_rankings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    strategy_id: Mapped[int] = mapped_column(ForeignKey("strategy_engine_strategies.id"), unique=True, index=True)
    rank: Mapped[int] = mapped_column(Integer, default=0, index=True)
    accuracy: Mapped[float] = mapped_column(Float, default=0)
    pnl: Mapped[float] = mapped_column(Float, default=0)
    consistency: Mapped[float] = mapped_column(Float, default=0)
    calibration: Mapped[float] = mapped_column(Float, default=0)
    risk_adjusted_performance: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(40), default="Draft", index=True)
    last_registered_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    strategy: Mapped["StrategyEngineStrategy"] = relationship(back_populates="ranking")


class Watchlist(Base):
    __tablename__ = "watchlists"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="watchlists")
    items: Mapped[list["WatchlistItem"]] = relationship(back_populates="watchlist")


class WatchlistItem(Base):
    __tablename__ = "watchlist_items"
    __table_args__ = (UniqueConstraint("watchlist_id", "market_id", name="uq_watchlist_market"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    watchlist_id: Mapped[int] = mapped_column(ForeignKey("watchlists.id"), index=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    watchlist: Mapped["Watchlist"] = relationship(back_populates="items")
    market: Mapped["Market"] = relationship(back_populates="watchlist_items")


class Workspace(Base):
    __tablename__ = "workspaces"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(120))
    layout_json: Mapped[dict] = mapped_column(JSON, default=dict)
    notes_json: Mapped[dict] = mapped_column(JSON, default=dict)
    chart_preferences: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="workspaces")


class Note(Base):
    __tablename__ = "notes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    market_id: Mapped[int | None] = mapped_column(ForeignKey("markets.id"), nullable=True, index=True)
    title: Mapped[str] = mapped_column(String(120))
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="notes")


class AISignal(Base):
    __tablename__ = "ai_signals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    market_id: Mapped[int | None] = mapped_column(ForeignKey("markets.id"), nullable=True, index=True)
    signal_type: Mapped[str] = mapped_column(String(50))
    action: Mapped[str] = mapped_column(String(50))
    confidence: Mapped[float] = mapped_column(Float)
    risk: Mapped[str] = mapped_column(String(30))
    reasoning: Mapped[str] = mapped_column(Text)
    payload_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped[User | None] = relationship(back_populates="ai_signals")
    market: Mapped[Market | None] = relationship(back_populates="signals")


class StrategyVault(Base, TimestampMixin):
    __tablename__ = "strategy_vaults"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(String(160), index=True)
    slug: Mapped[str] = mapped_column(String(180), unique=True, index=True)
    strategy_description: Mapped[str] = mapped_column(Text)
    risk_profile: Mapped[str] = mapped_column(String(30), default="MEDIUM")
    manager_type: Mapped[str] = mapped_column(String(20), default="AI")
    manager_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    status: Mapped[str] = mapped_column(String(30), default="ACTIVE", index=True)
    on_chain_address: Mapped[str | None] = mapped_column(String(120), nullable=True, index=True)
    share_token_address: Mapped[str | None] = mapped_column(String(120), nullable=True)
    collateral_token_address: Mapped[str | None] = mapped_column(String(120), nullable=True)
    collateral_token_decimals: Mapped[int] = mapped_column(Integer, default=18)
    auto_execute_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    target_markets_json: Mapped[list[str]] = mapped_column(JSON, default=list)
    current_allocation_json: Mapped[dict] = mapped_column(JSON, default=dict)
    performance_history_json: Mapped[list[dict]] = mapped_column(JSON, default=list)
    ai_confidence_score: Mapped[float] = mapped_column(Float, default=0.5)
    total_aum: Mapped[float] = mapped_column(Float, default=0)
    nav_per_share: Mapped[float] = mapped_column(Float, default=1.0)
    active_subscribers: Mapped[int] = mapped_column(Integer, default=0)
    roi_7d: Mapped[float] = mapped_column(Float, default=0)
    roi_30d: Mapped[float] = mapped_column(Float, default=0)
    win_rate: Mapped[float] = mapped_column(Float, default=0)
    volatility: Mapped[float] = mapped_column(Float, default=0)
    management_fee_bps: Mapped[int] = mapped_column(Integer, default=200)
    performance_fee_bps: Mapped[int] = mapped_column(Integer, default=1500)
    paused: Mapped[bool] = mapped_column(Boolean, default=False)
    archived: Mapped[bool] = mapped_column(Boolean, default=False)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    manager: Mapped[User | None] = relationship(back_populates="managed_vaults")
    subscriptions: Mapped[list["VaultSubscription"]] = relationship(back_populates="vault")
    trades: Mapped[list["VaultTrade"]] = relationship(back_populates="vault")
    snapshots: Mapped[list["VaultPerformanceSnapshot"]] = relationship(back_populates="vault")
    markets: Mapped[list["VaultMarket"]] = relationship(back_populates="vault")


class VaultMarket(Base):
    __tablename__ = "vault_markets"
    __table_args__ = (UniqueConstraint("vault_id", "market_id", name="uq_vault_market"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    vault_id: Mapped[int] = mapped_column(ForeignKey("strategy_vaults.id"), index=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    weight: Mapped[float] = mapped_column(Float, default=0)
    max_allocation_pct: Mapped[float] = mapped_column(Float, default=1.0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    vault: Mapped["StrategyVault"] = relationship(back_populates="markets")
    market: Mapped["Market"] = relationship()


class VaultSubscription(Base, TimestampMixin):
    __tablename__ = "vault_subscriptions"
    __table_args__ = (UniqueConstraint("vault_id", "user_id", name="uq_vault_subscription"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    vault_id: Mapped[int] = mapped_column(ForeignKey("strategy_vaults.id"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    wallet_address: Mapped[str] = mapped_column(String(120), index=True)
    deposited_amount: Mapped[float] = mapped_column(Float, default=0)
    share_balance: Mapped[float] = mapped_column(Float, default=0)
    realized_pnl: Mapped[float] = mapped_column(Float, default=0)
    unrealized_pnl: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(30), default="ACTIVE")
    auto_compound: Mapped[bool] = mapped_column(Boolean, default=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    vault: Mapped["StrategyVault"] = relationship(back_populates="subscriptions")
    user: Mapped["User"] = relationship(back_populates="vault_subscriptions")


class VaultTrade(Base):
    __tablename__ = "vault_trades"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    vault_id: Mapped[int] = mapped_column(ForeignKey("strategy_vaults.id"), index=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    side: Mapped[str] = mapped_column(String(10))
    allocation: Mapped[float] = mapped_column(Float, default=0)
    amount: Mapped[float] = mapped_column(Float, default=0)
    price: Mapped[float] = mapped_column(Float, default=0)
    confidence: Mapped[float] = mapped_column(Float, default=0)
    reasoning: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(30), default="EXECUTED")
    tx_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    vault: Mapped["StrategyVault"] = relationship(back_populates="trades")
    market: Mapped["Market"] = relationship()


class VaultPerformanceSnapshot(Base):
    __tablename__ = "vault_performance_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    vault_id: Mapped[int] = mapped_column(ForeignKey("strategy_vaults.id"), index=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)
    nav_per_share: Mapped[float] = mapped_column(Float, default=1.0)
    aum: Mapped[float] = mapped_column(Float, default=0)
    roi_period: Mapped[float] = mapped_column(Float, default=0)
    win_rate: Mapped[float] = mapped_column(Float, default=0)
    volatility: Mapped[float] = mapped_column(Float, default=0)
    confidence: Mapped[float] = mapped_column(Float, default=0)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    vault: Mapped["StrategyVault"] = relationship(back_populates="snapshots")


class CopyRelationship(Base, TimestampMixin):
    __tablename__ = "copy_relationships"
    __table_args__ = (UniqueConstraint("follower_user_id", "source_user_id", name="uq_copy_relationship"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    follower_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    source_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    source_type: Mapped[str] = mapped_column(String(30), default="TRADER")
    status: Mapped[str] = mapped_column(String(30), default="ACTIVE")
    allocation_pct: Mapped[float] = mapped_column(Float, default=0.1)
    max_loss_pct: Mapped[float] = mapped_column(Float, default=0.1)
    risk_level: Mapped[str] = mapped_column(String(20), default="MEDIUM")
    auto_stop_threshold: Mapped[float] = mapped_column(Float, default=0.08)
    max_follower_exposure: Mapped[float] = mapped_column(Float, default=5000)
    trader_commission_bps: Mapped[int] = mapped_column(Integer, default=1500)
    platform_fee_bps: Mapped[int] = mapped_column(Integer, default=200)
    allowed_markets_json: Mapped[list[int]] = mapped_column(JSON, default=list)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    follower: Mapped["User"] = relationship(back_populates="copy_following", foreign_keys=[follower_user_id])
    source: Mapped["User"] = relationship(back_populates="copy_followers", foreign_keys=[source_user_id])
    rules: Mapped[list["CopyAllocationRule"]] = relationship(back_populates="relationship")
    copied_trades: Mapped[list["CopiedTrade"]] = relationship(back_populates="relationship")
    snapshots: Mapped[list["CopyPerformanceSnapshot"]] = relationship(back_populates="relationship")


class CopyAllocationRule(Base, TimestampMixin):
    __tablename__ = "copy_allocation_rules"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    relationship_id: Mapped[int] = mapped_column(ForeignKey("copy_relationships.id"), index=True)
    market_id: Mapped[int | None] = mapped_column(ForeignKey("markets.id"), nullable=True, index=True)
    allocation_pct: Mapped[float] = mapped_column(Float, default=0.1)
    per_market_cap: Mapped[float] = mapped_column(Float, default=1000)
    position_limit: Mapped[float] = mapped_column(Float, default=5000)
    slippage_bps: Mapped[int] = mapped_column(Integer, default=75)
    stop_loss_pct: Mapped[float] = mapped_column(Float, default=0.08)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    market: Mapped["Market"] = relationship()
    relationship: Mapped["CopyRelationship"] = relationship(back_populates="rules")


class CopiedTrade(Base):
    __tablename__ = "copied_trades"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    relationship_id: Mapped[int] = mapped_column(ForeignKey("copy_relationships.id"), index=True)
    source_trade_id: Mapped[int] = mapped_column(ForeignKey("trade_orders.id"), index=True)
    follower_trade_id: Mapped[int | None] = mapped_column(ForeignKey("trade_orders.id"), nullable=True, index=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    copied_allocation: Mapped[float] = mapped_column(Float, default=0)
    copied_amount: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(30), default="EXECUTED")
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    source_tx_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    follower_tx_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    relationship: Mapped["CopyRelationship"] = relationship(back_populates="copied_trades")


class CopyPerformanceSnapshot(Base):
    __tablename__ = "copy_performance_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    relationship_id: Mapped[int] = mapped_column(ForeignKey("copy_relationships.id"), index=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)
    roi_7d: Mapped[float] = mapped_column(Float, default=0)
    roi_30d: Mapped[float] = mapped_column(Float, default=0)
    lifetime_accuracy: Mapped[float] = mapped_column(Float, default=0)
    copied_followers: Mapped[int] = mapped_column(Integer, default=0)
    assets_copied: Mapped[float] = mapped_column(Float, default=0)
    drawdown_pct: Mapped[float] = mapped_column(Float, default=0)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    relationship: Mapped["CopyRelationship"] = relationship(back_populates="snapshots")


class WalletBalance(Base):
    __tablename__ = "wallet_balances"
    __table_args__ = (UniqueConstraint("user_id", "wallet_address", "network", "symbol", name="uq_wallet_balance"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    wallet_address: Mapped[str] = mapped_column(String(120), index=True)
    network: Mapped[str] = mapped_column(String(40), default="hashkey")
    symbol: Mapped[str] = mapped_column(String(20))
    balance: Mapped[float] = mapped_column(Float, default=0)
    price_usd: Mapped[float] = mapped_column(Float, default=0)
    value_usd: Mapped[float] = mapped_column(Float, default=0)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="wallet_balances")


class ChainTransaction(Base):
    __tablename__ = "chain_transactions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    market_id: Mapped[int | None] = mapped_column(ForeignKey("markets.id"), nullable=True, index=True)
    tx_type: Mapped[str] = mapped_column(String(40))
    status: Mapped[str] = mapped_column(String(30), default="AWAITING_WALLET_SIGNATURE")
    tx_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    explorer_url: Mapped[str | None] = mapped_column(String(255), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class AssetSnapshot(Base):
    __tablename__ = "asset_snapshots"
    __table_args__ = (UniqueConstraint("symbol", name="uq_asset_snapshot_symbol"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    symbol: Mapped[str] = mapped_column(String(20), index=True)
    name: Mapped[str] = mapped_column(String(120))
    price_usd: Mapped[float] = mapped_column(Float, default=0)
    change_24h: Mapped[float] = mapped_column(Float, default=0)
    volume_24h: Mapped[float] = mapped_column(Float, default=0)
    market_cap: Mapped[float] = mapped_column(Float, default=0)
    high_24h: Mapped[float] = mapped_column(Float, default=0)
    low_24h: Mapped[float] = mapped_column(Float, default=0)
    volatility_pct: Mapped[float] = mapped_column(Float, default=0)
    order_flow_score: Mapped[float] = mapped_column(Float, default=0)
    source: Mapped[str] = mapped_column(String(80), default="coingecko")
    recorded_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
