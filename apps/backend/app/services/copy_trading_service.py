from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.entities import (
    CopyAllocationRule,
    CopiedTrade,
    CopyPerformanceSnapshot,
    CopyRelationship,
    ChainTransaction,
    Market,
    Notification,
    PortfolioPosition,
    TransactionRecord,
    TradeOrder,
    User,
)
from app.schemas.copy_trading import FollowTraderRequest, UpdateCopySettingsRequest
from app.services.redis_bus import publish


class CopyTradingService:
    def __init__(self, db: Session):
        self.db = db

    def follow_trader(self, follower_user_id: int, payload: FollowTraderRequest) -> CopyRelationship:
        if follower_user_id == payload.source_user_id:
            raise ValueError("Cannot copy yourself")

        relation = self.db.scalar(
            select(CopyRelationship).where(
                CopyRelationship.follower_user_id == follower_user_id,
                CopyRelationship.source_user_id == payload.source_user_id,
            )
        )
        if relation is None:
            relation = CopyRelationship(
                follower_user_id=follower_user_id,
                source_user_id=payload.source_user_id,
                source_type=payload.source_type.upper(),
                status="ACTIVE",
                allocation_pct=payload.allocation_pct,
                max_loss_pct=payload.max_loss_pct,
                risk_level=payload.risk_level.upper(),
                auto_stop_threshold=payload.auto_stop_threshold,
                max_follower_exposure=payload.max_follower_exposure,
                trader_commission_bps=payload.trader_commission_bps,
                platform_fee_bps=payload.platform_fee_bps,
                allowed_markets_json=payload.allowed_market_ids,
            )
            self.db.add(relation)
            self.db.flush()
        else:
            relation.status = "ACTIVE"
            relation.allocation_pct = payload.allocation_pct
            relation.max_loss_pct = payload.max_loss_pct
            relation.risk_level = payload.risk_level.upper()
            relation.auto_stop_threshold = payload.auto_stop_threshold
            relation.max_follower_exposure = payload.max_follower_exposure
            relation.allowed_markets_json = payload.allowed_market_ids

        existing_rule = self.db.scalar(
            select(CopyAllocationRule).where(
                CopyAllocationRule.relationship_id == relation.id,
                CopyAllocationRule.market_id.is_(None),
            )
        )
        if existing_rule is None:
            self.db.add(
                CopyAllocationRule(
                    relationship_id=relation.id,
                    market_id=None,
                    allocation_pct=payload.allocation_pct,
                    per_market_cap=payload.max_follower_exposure * 0.4,
                    position_limit=payload.max_follower_exposure,
                    slippage_bps=90,
                    stop_loss_pct=payload.max_loss_pct,
                )
            )

        self.db.add(
            Notification(
                user_id=follower_user_id,
                level="info",
                category="copy",
                message=f"Copy forecasts enabled for source #{payload.source_user_id}",
                metadata_json={"source_user_id": payload.source_user_id},
            )
        )

        self._save_snapshot(relation.id)
        self.db.commit()
        self.db.refresh(relation)
        return relation

    def unfollow_trader(self, follower_user_id: int, source_user_id: int) -> CopyRelationship:
        relation = self._require_relationship(follower_user_id, source_user_id)
        relation.status = "STOPPED"
        self.db.commit()
        self.db.refresh(relation)
        return relation

    def stop_copying(self, relationship_id: int, follower_user_id: int) -> CopyRelationship:
        relation = self.db.scalar(
            select(CopyRelationship).where(
                CopyRelationship.id == relationship_id,
                CopyRelationship.follower_user_id == follower_user_id,
            )
        )
        if relation is None:
            raise ValueError("Copy relationship not found")
        relation.status = "STOPPED"
        self.db.commit()
        self.db.refresh(relation)
        return relation

    def update_settings(self, relationship_id: int, follower_user_id: int, payload: UpdateCopySettingsRequest) -> CopyRelationship:
        relation = self.db.scalar(
            select(CopyRelationship).where(
                CopyRelationship.id == relationship_id,
                CopyRelationship.follower_user_id == follower_user_id,
            )
        )
        if relation is None:
            raise ValueError("Copy relationship not found")

        if payload.allocation_pct is not None:
            relation.allocation_pct = payload.allocation_pct
        if payload.max_loss_pct is not None:
            relation.max_loss_pct = payload.max_loss_pct
        if payload.risk_level is not None:
            relation.risk_level = payload.risk_level.upper()
        if payload.auto_stop_threshold is not None:
            relation.auto_stop_threshold = payload.auto_stop_threshold
        if payload.allowed_market_ids is not None:
            relation.allowed_markets_json = payload.allowed_market_ids

        self._save_snapshot(relation.id)
        self.db.commit()
        self.db.refresh(relation)
        return relation

    def list_relationships(self, follower_user_id: int) -> list[CopyRelationship]:
        return self.db.scalars(
            select(CopyRelationship)
            .where(CopyRelationship.follower_user_id == follower_user_id)
            .order_by(CopyRelationship.created_at.desc())
        ).all()

    def list_copied_trades(self, follower_user_id: int) -> list[CopiedTrade]:
        return self.db.scalars(
            select(CopiedTrade)
            .join(CopyRelationship, CopyRelationship.id == CopiedTrade.relationship_id)
            .where(CopyRelationship.follower_user_id == follower_user_id)
            .order_by(CopiedTrade.created_at.desc())
            .limit(200)
        ).all()

    def list_snapshots(self, relationship_id: int, follower_user_id: int) -> list[CopyPerformanceSnapshot]:
        relation = self.db.scalar(
            select(CopyRelationship).where(
                CopyRelationship.id == relationship_id,
                CopyRelationship.follower_user_id == follower_user_id,
            )
        )
        if relation is None:
            raise ValueError("Copy relationship not found")
        return self.db.scalars(
            select(CopyPerformanceSnapshot)
            .where(CopyPerformanceSnapshot.relationship_id == relationship_id)
            .order_by(CopyPerformanceSnapshot.timestamp.desc())
            .limit(60)
        ).all()[::-1]

    def portfolio_summary(self, follower_user_id: int) -> dict[str, Any]:
        relationships = self.list_relationships(follower_user_id)
        active = [item for item in relationships if item.status == "ACTIVE"]
        copied = self.list_copied_trades(follower_user_id)
        live_positions = sum(1 for trade in copied if trade.status in {"EXECUTED", "OPEN", "PENDING"})
        alerts = sum(1 for trade in copied if trade.status in {"REJECTED", "STOPPED", "SKIPPED"})
        performance_rows = []
        total_roi = 0.0

        for relation in active:
            source_trades = self.db.scalars(
                select(TradeOrder).where(TradeOrder.user_id == relation.source_user_id).order_by(TradeOrder.created_at.desc()).limit(30)
            ).all()
            source_pnl = sum((trade.collateral_amount * (1 if trade.side == "YES" else -1) * (trade.price - 0.5)) for trade in source_trades)
            exposure = sum(trade.copied_amount for trade in copied if trade.relationship_id == relation.id)
            roi = (source_pnl / exposure) if exposure > 0 else 0.0
            total_roi += roi
            performance_rows.append(
                {
                    "relationship_id": relation.id,
                    "source_user_id": relation.source_user_id,
                    "status": relation.status,
                    "roi": round(roi, 4),
                    "assets_copied": round(exposure, 2),
                }
            )

        avg_roi = (total_roi / len(active)) if active else 0.0
        return {
            "copied_traders": len(active),
            "live_copied_positions": live_positions,
            "copied_roi": round(avg_roi, 4),
            "active_alerts": alerts,
            "performance_by_trader": performance_rows,
        }

    def process_source_trade(self, source_trade: TradeOrder) -> list[CopiedTrade]:
        relationships = self.db.scalars(
            select(CopyRelationship)
            .where(
                CopyRelationship.source_user_id == source_trade.user_id,
                CopyRelationship.status == "ACTIVE",
            )
            .order_by(CopyRelationship.created_at.asc())
        ).all()

        copied_rows: list[CopiedTrade] = []
        for relation in relationships:
            row = self._copy_single_trade(relation, source_trade)
            copied_rows.append(row)

        self.db.commit()
        return copied_rows

    async def publish_copy_event(self, event_type: str, payload: dict[str, Any]) -> None:
        event = {
            "type": event_type,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            **payload,
        }
        await publish(settings.copy_websocket_channel, event)

    def _copy_single_trade(self, relation: CopyRelationship, source_trade: TradeOrder) -> CopiedTrade:
        if relation.allowed_markets_json and source_trade.market_id not in relation.allowed_markets_json:
            copied = CopiedTrade(
                relationship_id=relation.id,
                source_trade_id=source_trade.id,
                follower_trade_id=None,
                market_id=source_trade.market_id,
                copied_allocation=0,
                copied_amount=0,
                status="SKIPPED",
                reason="Market filtered by copy settings",
            )
            self.db.add(copied)
            return copied

        base_allocation = max(0, min(1, relation.allocation_pct))
        copied_amount = source_trade.collateral_amount * base_allocation

        global_rule = self.db.scalar(
            select(CopyAllocationRule).where(
                CopyAllocationRule.relationship_id == relation.id,
                CopyAllocationRule.market_id.is_(None),
                CopyAllocationRule.active.is_(True),
            )
        )

        market_rule = self.db.scalar(
            select(CopyAllocationRule).where(
                CopyAllocationRule.relationship_id == relation.id,
                CopyAllocationRule.market_id == source_trade.market_id,
                CopyAllocationRule.active.is_(True),
            )
        )

        rule = market_rule or global_rule
        if rule is not None:
            copied_amount = min(copied_amount, rule.per_market_cap)
            if copied_amount > rule.position_limit:
                copied_amount = rule.position_limit

        current_exposure = self.db.scalar(
            select(func.coalesce(func.sum(CopiedTrade.copied_amount), 0.0)).where(
                CopiedTrade.relationship_id == relation.id,
                CopiedTrade.status.in_(["EXECUTED", "OPEN", "PENDING"]),
            )
        )
        if (current_exposure + copied_amount) > relation.max_follower_exposure:
            copied = CopiedTrade(
                relationship_id=relation.id,
                source_trade_id=source_trade.id,
                follower_trade_id=None,
                market_id=source_trade.market_id,
                copied_allocation=base_allocation,
                copied_amount=0,
                status="REJECTED",
                reason="Max follower exposure exceeded",
            )
            self.db.add(copied)
            return copied

        if copied_amount <= 0:
            copied = CopiedTrade(
                relationship_id=relation.id,
                source_trade_id=source_trade.id,
                follower_trade_id=None,
                market_id=source_trade.market_id,
                copied_allocation=base_allocation,
                copied_amount=0,
                status="SKIPPED",
                reason="Zero copied amount after limits",
            )
            self.db.add(copied)
            return copied

        side = source_trade.side.upper()
        follower_trade = TradeOrder(
            user_id=relation.follower_user_id,
            market_id=source_trade.market_id,
            side=side,
            order_type=source_trade.order_type,
            collateral_amount=copied_amount,
            price=source_trade.price,
            shares=max(0.0, copied_amount / max(source_trade.price, 0.0001)),
            status="BROADCASTING" if source_trade.signed_payload else "PENDING_SIGNATURE",
            wallet_address=None,
            signed_payload=None,
            tx_hash=None,
            explorer_url=None,
            gas_estimate=source_trade.gas_estimate,
            gas_fee_native=source_trade.gas_fee_native,
            metadata_json={
                "copied_from_trade_id": source_trade.id,
                "copy_relationship_id": relation.id,
                "source_user_id": relation.source_user_id,
            },
        )
        self.db.add(follower_trade)
        self.db.flush()

        market = self.db.scalar(select(Market).where(Market.id == source_trade.market_id))
        follower_user = self.db.scalar(select(User).where(User.id == relation.follower_user_id))
        if market is not None:
            position = PortfolioPosition(
                user_id=relation.follower_user_id,
                market_id=market.id,
                side=side,
                size=max(0.0, copied_amount / max(source_trade.price, 0.0001)),
                avg_price=source_trade.price,
                mark_price=source_trade.price,
                realized_pnl=0,
                unrealized_pnl=0,
                pnl=0,
                status="OPEN",
            )
            self.db.add(position)
            self.db.add(
                TransactionRecord(
                    user_id=relation.follower_user_id,
                    trade_id=follower_trade.id,
                    transaction_type="COPY_TRADE",
                    asset_symbol=market.collateral_token or "USDC",
                    amount=copied_amount,
                    status=follower_trade.status,
                    tx_hash=follower_trade.tx_hash,
                    explorer_url=follower_trade.explorer_url,
                    gas_fee_native=follower_trade.gas_fee_native,
                    metadata_json={
                        "source_trade_id": source_trade.id,
                        "copy_relationship_id": relation.id,
                        "market_title": market.title,
                    },
                )
            )
            self.db.add(
                Notification(
                    user_id=relation.follower_user_id,
                    level="info",
                    category="copy",
                    message=f"Copied trade executed for {market.title}",
                    metadata_json={"source_trade_id": source_trade.id, "market_id": market.id},
                )
            )

        copied = CopiedTrade(
            relationship_id=relation.id,
            source_trade_id=source_trade.id,
            follower_trade_id=follower_trade.id,
            market_id=source_trade.market_id,
            copied_allocation=base_allocation,
            copied_amount=copied_amount,
            status="EXECUTED",
            reason=None,
            source_tx_hash=source_trade.tx_hash,
            follower_tx_hash=follower_trade.tx_hash,
            metadata_json={
                "slippage_bps": rule.slippage_bps if rule else 90,
                "stop_loss_pct": rule.stop_loss_pct if rule else relation.max_loss_pct,
            },
        )
        self.db.add(copied)
        self.db.flush()

        if follower_user and follower_user.wallet_address:
            self.db.add(
                ChainTransaction(
                    user_id=relation.follower_user_id,
                    market_id=source_trade.market_id,
                    tx_type="COPY_TRADE",
                    status="AWAITING_WALLET_SIGNATURE",
                    metadata_json={
                        "copied_trade_id": copied.id,
                        "follower_trade_id": follower_trade.id,
                        "market_id": source_trade.market_id,
                        "wallet_address": follower_user.wallet_address,
                    },
                )
            )

        self._save_snapshot(relation.id)
        self._enforce_auto_stop(relation)

        return copied

    def _save_snapshot(self, relationship_id: int) -> None:
        relation = self.db.scalar(select(CopyRelationship).where(CopyRelationship.id == relationship_id))
        if relation is None:
            return

        copied_rows = self.db.scalars(select(CopiedTrade).where(CopiedTrade.relationship_id == relationship_id)).all()
        executed = [row for row in copied_rows if row.status == "EXECUTED"]
        assets_copied = sum(item.copied_amount for item in executed)

        source_trades = self.db.scalars(
            select(TradeOrder)
            .where(TradeOrder.user_id == relation.source_user_id)
            .order_by(TradeOrder.created_at.desc())
            .limit(50)
        ).all()
        right_direction = sum(1 for trade in source_trades if (trade.side == "YES" and trade.price >= 0.5) or (trade.side == "NO" and trade.price <= 0.5))
        lifetime_accuracy = (right_direction / len(source_trades)) if source_trades else 0

        pnl = sum((trade.collateral_amount * (trade.price - 0.5)) for trade in source_trades)
        roi_7d = pnl / max(assets_copied, 1)
        roi_30d = roi_7d * 1.7
        drawdown = max(0.0, min(1.0, abs(min(roi_7d, 0.0)) * 2.5))

        followers = self.db.scalar(
            select(func.count(CopyRelationship.id)).where(
                CopyRelationship.source_user_id == relation.source_user_id,
                CopyRelationship.status == "ACTIVE",
            )
        )

        self.db.add(
            CopyPerformanceSnapshot(
                relationship_id=relationship_id,
                timestamp=datetime.now(timezone.utc),
                roi_7d=roi_7d,
                roi_30d=roi_30d,
                lifetime_accuracy=lifetime_accuracy,
                copied_followers=int(followers or 0),
                assets_copied=assets_copied,
                drawdown_pct=drawdown,
            )
        )

    def _enforce_auto_stop(self, relation: CopyRelationship) -> None:
        latest = self.db.scalar(
            select(CopyPerformanceSnapshot)
            .where(CopyPerformanceSnapshot.relationship_id == relation.id)
            .order_by(CopyPerformanceSnapshot.timestamp.desc())
        )
        if latest is None:
            return
        if latest.drawdown_pct > relation.auto_stop_threshold:
            relation.status = "STOPPED"

    def _require_relationship(self, follower_user_id: int, source_user_id: int) -> CopyRelationship:
        relation = self.db.scalar(
            select(CopyRelationship).where(
                CopyRelationship.follower_user_id == follower_user_id,
                CopyRelationship.source_user_id == source_user_id,
            )
        )
        if relation is None:
            raise ValueError("Copy relationship not found")
        return relation
