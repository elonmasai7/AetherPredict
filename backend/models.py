from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, Index, Integer, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    balance: Mapped[float] = mapped_column(Numeric(12, 2), default=1000)
    api_key_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    encrypted_api_credentials: Mapped[str | None] = mapped_column(Text, nullable=True)
    preferred_provider: Mapped[str] = mapped_column(String(32), default="kalshi")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    trades: Mapped[list["Trade"]] = relationship(back_populates="user")
    positions: Mapped[list["Position"]] = relationship(back_populates="user")


class Market(Base):
    __tablename__ = "markets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(String(255), index=True)
    event: Mapped[str] = mapped_column(String(255), index=True)
    provider: Mapped[str] = mapped_column(String(32), default="mock", index=True)
    provider_market_id: Mapped[str | None] = mapped_column(String(120), nullable=True, index=True)
    yes_price: Mapped[float] = mapped_column(Float, default=0.5)
    no_price: Mapped[float] = mapped_column(Float, default=0.5)
    end_ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    min_liquidity: Mapped[float] = mapped_column(Float, default=1000)
    liquidity_usd: Mapped[float] = mapped_column(Float, default=1000)
    b_param: Mapped[float] = mapped_column(Float, default=1800)
    yes_shares: Mapped[float] = mapped_column(Float, default=900)
    no_shares: Mapped[float] = mapped_column(Float, default=900)
    total_volume: Mapped[float] = mapped_column(Float, default=0)
    implied_probability: Mapped[float] = mapped_column(Float, default=0.5)
    spread_cents: Mapped[int] = mapped_column(Integer, default=2)
    maker_concentration: Mapped[float] = mapped_column(Float, default=42)
    order_book_json: Mapped[dict] = mapped_column(JSON, default=dict)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    archived: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    trades: Mapped[list["Trade"]] = relationship(back_populates="market")
    positions: Mapped[list["Position"]] = relationship(back_populates="market")
    history: Mapped[list["OddsHistory"]] = relationship(back_populates="market")


class Trade(Base):
    __tablename__ = "trades"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    side: Mapped[str] = mapped_column(String(8), index=True)
    shares: Mapped[float] = mapped_column(Float)
    price: Mapped[float] = mapped_column(Float)
    notional: Mapped[float] = mapped_column(Float)
    slippage_pct: Mapped[float] = mapped_column(Float, default=0)
    maker_rebate: Mapped[float] = mapped_column(Float, default=0)
    provider_trade_id: Mapped[str | None] = mapped_column(String(120), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, index=True)

    user: Mapped["User"] = relationship(back_populates="trades")
    market: Mapped["Market"] = relationship(back_populates="trades")


class Position(Base):
    __tablename__ = "positions"
    __table_args__ = (UniqueConstraint("user_id", "market_id", "side", name="uq_position_user_market_side"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    side: Mapped[str] = mapped_column(String(8), index=True)
    shares: Mapped[float] = mapped_column(Float, default=0)
    avg_price: Mapped[float] = mapped_column(Float, default=0)
    realized_pnl: Mapped[float] = mapped_column(Float, default=0)
    unrealized_pnl: Mapped[float] = mapped_column(Float, default=0)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    user: Mapped["User"] = relationship(back_populates="positions")
    market: Mapped["Market"] = relationship(back_populates="positions")


class OddsHistory(Base):
    __tablename__ = "odds_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    market_id: Mapped[int] = mapped_column(ForeignKey("markets.id"), index=True)
    yes_price: Mapped[float] = mapped_column(Float)
    no_price: Mapped[float] = mapped_column(Float)
    spread_cents: Mapped[int] = mapped_column(Integer)
    liquidity_usd: Mapped[float] = mapped_column(Float)
    order_book_json: Mapped[dict] = mapped_column(JSON, default=dict)
    captured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, index=True)

    market: Mapped["Market"] = relationship(back_populates="history")


Index("ix_history_market_captured", OddsHistory.market_id, OddsHistory.captured_at.desc())
