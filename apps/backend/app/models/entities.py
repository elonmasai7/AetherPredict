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
