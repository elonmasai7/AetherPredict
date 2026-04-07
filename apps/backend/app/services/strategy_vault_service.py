from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from decimal import Decimal, ROUND_DOWN
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.entities import (
    ChainTransaction,
    Market,
    Notification,
    StrategyVault,
    User,
    VaultMarket,
    VaultPerformanceSnapshot,
    VaultSubscription,
    VaultTrade,
)
from app.schemas.vault import ExecuteVaultStrategyRequest, ExecuteVaultStrategyResponse, VaultCreateRequest
from app.services.redis_bus import publish
from app.services.blockchain_service import BlockchainService


class StrategyVaultService:
    def __init__(self, db: Session):
        self.db = db

    def create_vault(self, manager_user_id: int | None, payload: VaultCreateRequest) -> StrategyVault:
        slug = self._slugify(payload.title)
        existing = self.db.scalar(select(StrategyVault).where(StrategyVault.slug == slug))
        if existing is not None:
            slug = f"{slug}-{int(datetime.now(timezone.utc).timestamp())}"

        auto_execute_enabled = payload.auto_execute_enabled
        if auto_execute_enabled is None:
            auto_execute_enabled = slug in settings.vault_auto_execute_default_slugs
        collateral_decimals = payload.collateral_token_decimals
        if collateral_decimals is None and payload.collateral_token_address:
            try:
                chain = BlockchainService()
                collateral_decimals = chain.get_erc20_decimals(payload.collateral_token_address)
            except Exception:
                collateral_decimals = 18
        collateral_decimals = collateral_decimals or 18

        vault = StrategyVault(
            title=payload.title,
            slug=slug,
            strategy_description=payload.strategy_description,
            risk_profile=payload.risk_profile.upper(),
            manager_type=payload.manager_type.upper(),
            manager_user_id=manager_user_id,
            collateral_token_address=payload.collateral_token_address,
            collateral_token_decimals=collateral_decimals,
            auto_execute_enabled=auto_execute_enabled,
            target_markets_json=[],
            current_allocation_json={},
            performance_history_json=[],
            ai_confidence_score=payload.ai_confidence_score,
            management_fee_bps=payload.management_fee_bps,
            performance_fee_bps=payload.performance_fee_bps,
            status="ACTIVE",
        )
        self.db.add(vault)
        self.db.flush()

        target_markets: list[str] = []
        if payload.target_market_ids:
            markets = self.db.scalars(select(Market).where(Market.id.in_(payload.target_market_ids))).all()
            for market in markets:
                self.db.add(VaultMarket(vault_id=vault.id, market_id=market.id, weight=1 / max(len(markets), 1)))
                target_markets.append(market.slug)
            vault.target_markets_json = target_markets

        snapshot = VaultPerformanceSnapshot(
            vault_id=vault.id,
            nav_per_share=vault.nav_per_share,
            aum=vault.total_aum,
            roi_period=0,
            win_rate=0,
            volatility=0,
            confidence=vault.ai_confidence_score,
        )
        self.db.add(snapshot)
        self.db.commit()
        self.db.refresh(vault)
        return vault

    def list_vaults(self, category: str | None = None) -> list[StrategyVault]:
        query = select(StrategyVault).where(StrategyVault.archived.is_(False))
        if category == "low-risk":
            query = query.where(StrategyVault.risk_profile == "LOW")
        elif category == "ai-managed":
            query = query.where(StrategyVault.manager_type == "AI")
        elif category == "human-managed":
            query = query.where(StrategyVault.manager_type == "HUMAN")
        elif category == "top-performing":
            query = query.order_by(StrategyVault.roi_30d.desc())

        if category != "top-performing":
            query = query.order_by(StrategyVault.total_aum.desc(), StrategyVault.roi_7d.desc())

        return self.db.scalars(query.limit(100)).all()

    def get_vault(self, vault_id: int) -> StrategyVault | None:
        return self.db.scalar(select(StrategyVault).where(StrategyVault.id == vault_id))

    def pause_vault(self, vault_id: int, paused: bool) -> StrategyVault:
        vault = self._require_vault(vault_id)
        vault.paused = paused
        vault.status = "PAUSED" if paused else "ACTIVE"
        self.db.commit()
        self.db.refresh(vault)
        return vault

    def archive_vault(self, vault_id: int) -> StrategyVault:
        vault = self._require_vault(vault_id)
        vault.archived = True
        vault.status = "ARCHIVED"
        self.db.commit()
        self.db.refresh(vault)
        return vault

    def deposit(self, vault_id: int, user_id: int, wallet_address: str, amount: float) -> VaultSubscription:
        vault = self._require_vault(vault_id)
        self._check_vault_live(vault)

        subscription = self.db.scalar(
            select(VaultSubscription).where(
                VaultSubscription.vault_id == vault_id,
                VaultSubscription.user_id == user_id,
            )
        )
        if subscription is None:
            subscription = VaultSubscription(
                vault_id=vault_id,
                user_id=user_id,
                wallet_address=wallet_address,
                deposited_amount=0,
                share_balance=0,
                status="ACTIVE",
            )
            self.db.add(subscription)
            vault.active_subscribers += 1

        share_price = max(vault.nav_per_share, 0.0001)
        minted_shares = amount / share_price

        subscription.deposited_amount += amount
        subscription.share_balance += minted_shares
        vault.total_aum += amount

        self._update_vault_metrics(vault)
        self.db.add(
            Notification(
                user_id=user_id,
                level="info",
                category="vault",
                message=f"Deposited ${amount:,.2f} into {vault.title}",
                metadata_json={"vault_id": vault.id, "amount": amount},
            )
        )
        self.db.commit()
        self.db.refresh(subscription)
        return subscription

    def withdraw(self, vault_id: int, user_id: int, amount: float) -> VaultSubscription:
        vault = self._require_vault(vault_id)
        subscription = self.db.scalar(
            select(VaultSubscription).where(
                VaultSubscription.vault_id == vault_id,
                VaultSubscription.user_id == user_id,
            )
        )
        if subscription is None:
            raise ValueError("Vault subscription not found")

        if amount <= 0:
            raise ValueError("Withdraw amount must be positive")

        nav = max(vault.nav_per_share, 0.0001)
        burned_shares = amount / nav
        if subscription.share_balance < burned_shares:
            raise ValueError("Insufficient vault shares")

        subscription.share_balance -= burned_shares
        subscription.deposited_amount = max(subscription.deposited_amount - amount, 0)
        vault.total_aum = max(vault.total_aum - amount, 0)

        if subscription.share_balance <= 0.000001:
            subscription.status = "INACTIVE"
            vault.active_subscribers = max(vault.active_subscribers - 1, 0)

        self._update_vault_metrics(vault)
        self.db.commit()
        self.db.refresh(subscription)
        return subscription

    def execute_trade(
        self,
        vault_id: int,
        market_id: int,
        side: str,
        allocation: float,
        confidence: float,
        reasoning: str,
        tx_hash: str | None = None,
        queue_chain_tx: bool = False,
    ) -> VaultTrade:
        vault = self._require_vault(vault_id)
        self._check_vault_live(vault)

        market = self.db.scalar(select(Market).where(Market.id == market_id))
        if market is None:
            raise ValueError("Market not found")

        self._enforce_risk_limits(vault, market_id, allocation)

        side_norm = side.upper()
        if side_norm not in {"BUY_YES", "BUY_NO", "HOLD", "SELL_YES", "SELL_NO"}:
            raise ValueError("Unsupported vault action")

        amount = max(0.0, vault.total_aum * allocation)
        price = market.yes_probability if "YES" in side_norm else market.no_probability
        trade = VaultTrade(
            vault_id=vault.id,
            market_id=market.id,
            side=side_norm,
            allocation=allocation,
            amount=amount,
            price=price,
            confidence=confidence,
            reasoning=reasoning,
            tx_hash=tx_hash,
            status="EXECUTED",
        )
        self.db.add(trade)

        allocation_state = dict(vault.current_allocation_json)
        allocation_state[str(market.id)] = round(allocation_state.get(str(market.id), 0) + allocation, 4)
        vault.current_allocation_json = allocation_state

        self.db.commit()
        self.db.refresh(trade)
        if queue_chain_tx:
            self._queue_vault_chain_tx(vault, market, trade)
        return trade

    def rebalance(self, vault_id: int) -> StrategyVault:
        vault = self._require_vault(vault_id)
        self._check_vault_live(vault)

        trades = self.db.scalars(select(VaultTrade).where(VaultTrade.vault_id == vault_id)).all()
        if not trades:
            return vault

        by_market: dict[str, float] = {}
        total_amount = sum(max(0.0, trade.amount) for trade in trades)
        if total_amount <= 0:
            return vault

        for trade in trades:
            key = str(trade.market_id)
            by_market[key] = by_market.get(key, 0.0) + trade.amount

        vault.current_allocation_json = {k: round(v / total_amount, 4) for k, v in by_market.items()}
        self._update_vault_metrics(vault)
        self.db.commit()
        self.db.refresh(vault)
        return vault

    def distribute_returns(self, vault_id: int, gross_return: float) -> dict[str, float]:
        vault = self._require_vault(vault_id)
        self._check_vault_live(vault)

        gross_return = float(gross_return)
        if gross_return == 0:
            return {"distributed": 0.0, "manager_fee": 0.0, "platform_fee": 0.0}

        performance_fee = max(0.0, gross_return * (vault.performance_fee_bps / 10000))
        management_fee = max(0.0, vault.total_aum * (vault.management_fee_bps / 10000) / 365)
        distributed = gross_return - performance_fee - management_fee
        vault.total_aum = max(0.0, vault.total_aum + distributed)

        self._update_vault_metrics(vault)
        self.db.commit()
        return {
            "distributed": round(distributed, 4),
            "manager_fee": round(performance_fee, 4),
            "platform_fee": round(management_fee, 4),
        }

    def get_performance(self, vault_id: int) -> list[VaultPerformanceSnapshot]:
        return self.db.scalars(
            select(VaultPerformanceSnapshot)
            .where(VaultPerformanceSnapshot.vault_id == vault_id)
            .order_by(VaultPerformanceSnapshot.timestamp.desc())
            .limit(90)
        ).all()[::-1]

    def execute_strategy(self, payload: ExecuteVaultStrategyRequest) -> ExecuteVaultStrategyResponse:
        market_data = payload.market_data or {}
        portfolio_state = payload.portfolio_state or {}

        momentum = float(market_data.get("momentum", 0.0))
        sentiment = float(market_data.get("sentiment", 0.0))
        volatility = float(market_data.get("volatility", 0.0))
        drawdown = float(portfolio_state.get("drawdown", 0.0))

        confidence = max(0.05, min(0.99, 0.62 + momentum * 0.2 + sentiment * 0.15 - volatility * 0.2 - drawdown * 0.1))
        market = str(market_data.get("market", "btc_120k"))

        if volatility > 0.7 or drawdown > 0.15:
            action = "BUY_NO"
            reasoning = "Risk-off hedge triggered by elevated volatility/drawdown"
            allocation = 0.08
        elif momentum >= 0.1:
            action = "BUY_YES"
            reasoning = "Momentum breakout signal"
            allocation = 0.15
        elif sentiment <= -0.2:
            action = "BUY_NO"
            reasoning = "Negative sentiment regime with downside skew"
            allocation = 0.12
        else:
            action = "HOLD"
            reasoning = "No dominant edge after confidence normalization"
            allocation = 0.0

        response = ExecuteVaultStrategyResponse(
            action=action,
            market=market,
            allocation=allocation,
            confidence=round(confidence, 4),
            reasoning=reasoning,
        )
        auto_execute = portfolio_state.get("auto_execute")
        if auto_execute is None:
            auto_execute = self._vault_auto_execute_default(payload.vault_id)
        if auto_execute:
            self._auto_execute_strategy(payload, response)
        return response

    def is_auto_execute_allowed(self, vault_id: int) -> bool:
        vault = self.get_vault(vault_id)
        if vault is None:
            raise ValueError("Vault not found")
        return self._auto_execute_allowed(vault)

    def _vault_auto_execute_default(self, vault_id: str) -> bool:
        try:
            resolved_id = int(vault_id)
        except (TypeError, ValueError):
            return False
        vault = self.get_vault(resolved_id)
        if vault is None:
            return False
        return bool(vault.auto_execute_enabled)

    def _auto_execute_strategy(
        self,
        payload: ExecuteVaultStrategyRequest,
        response: ExecuteVaultStrategyResponse,
    ) -> None:
        if response.action == "HOLD" or response.allocation <= 0:
            return
        try:
            vault_id = int(payload.vault_id)
        except (TypeError, ValueError):
            return

        vault = self.get_vault(vault_id)
        if vault is None:
            raise ValueError("Vault not found")
        self._check_vault_live(vault)
        if not self._auto_execute_allowed(vault):
            raise ValueError("Vault not allowlisted for auto execution")

        market_data = payload.market_data or {}
        market_id = market_data.get("market_id")
        market = None
        if market_id:
            try:
                market = self.db.scalar(select(Market).where(Market.id == int(market_id)))
            except (TypeError, ValueError):
                market = None
        if market is None:
            market_slug = str(market_data.get("market", "")).strip()
            if not market_slug:
                raise ValueError("market_id or market slug required for auto execute")
            market = self.db.scalar(select(Market).where(Market.slug == market_slug))
        if market is None:
            raise ValueError("Market not found")

        self.execute_trade(
            vault_id=vault.id,
            market_id=market.id,
            side=response.action,
            allocation=response.allocation,
            confidence=response.confidence,
            reasoning=response.reasoning,
            queue_chain_tx=True,
        )

    def _auto_execute_allowed(self, vault: StrategyVault) -> bool:
        if not vault.auto_execute_enabled:
            return False
        allow_ids = set(settings.vault_auto_execute_allowlist_ids or [])
        allow_roles = {role.lower() for role in (settings.vault_auto_execute_allowlist_manager_roles or [])}
        if not allow_ids and not allow_roles:
            return False
        if allow_ids and vault.id in allow_ids:
            return True
        if allow_roles and vault.manager_user_id:
            manager = self.db.scalar(select(User).where(User.id == vault.manager_user_id))
            if manager and manager.role and manager.role.lower() in allow_roles:
                return True
        return False

    def _queue_vault_chain_tx(self, vault: StrategyVault, market: Market, trade: VaultTrade) -> None:
        if not vault.on_chain_address or not market.on_chain_address:
            return
        if not vault.manager_user_id:
            return
        manager = self.db.scalar(select(User).where(User.id == vault.manager_user_id))
        if manager is None or not manager.wallet_address:
            return
        amount_wei = self._amount_to_wei(trade.amount, vault.collateral_token_decimals)

        tx = ChainTransaction(
            user_id=manager.id,
            market_id=market.id,
            tx_type="VAULT_EXECUTE",
            status="AWAITING_WALLET_SIGNATURE",
            metadata_json={
                "vault_id": vault.id,
                "vault_address": vault.on_chain_address,
                "market_id": market.id,
                "market_address": market.on_chain_address,
                "action": trade.side,
                "amount_wei": amount_wei,
                "wallet_address": manager.wallet_address,
            },
        )
        self.db.add(tx)
        self.db.commit()
        trade.metadata_json = {**(trade.metadata_json or {}), "chain_tx_id": tx.id}
        self.db.commit()
        asyncio.create_task(
            self.publish_vault_event(
                "vault_execute_chain_tx",
                {"vault_id": vault.id, "trade_id": trade.id, "chain_tx_id": tx.id},
            )
        )

    @staticmethod
    def _amount_to_wei(amount: float, decimals: int | None) -> int:
        safe_decimals = max(int(decimals or 0), 0)
        factor = Decimal(10) ** safe_decimals
        return int((Decimal(str(amount)) * factor).to_integral_value(rounding=ROUND_DOWN))

    async def publish_vault_event(self, event_type: str, payload: dict[str, Any]) -> None:
        event = {
            "type": event_type,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            **payload,
        }
        await publish(settings.vault_websocket_channel, event)

    def _require_vault(self, vault_id: int) -> StrategyVault:
        vault = self.get_vault(vault_id)
        if vault is None:
            raise ValueError("Vault not found")
        return vault

    def _check_vault_live(self, vault: StrategyVault) -> None:
        if vault.archived:
            raise ValueError("Vault archived")
        if vault.paused:
            raise ValueError("Vault paused")

    def _enforce_risk_limits(self, vault: StrategyVault, market_id: int, allocation: float) -> None:
        if allocation < 0 or allocation > 1:
            raise ValueError("Allocation must be between 0 and 1")

        market_caps = self.db.scalars(
            select(func.coalesce(func.sum(VaultTrade.allocation), 0.0))
            .where(VaultTrade.vault_id == vault.id, VaultTrade.market_id == market_id)
        ).one()
        if market_caps + allocation > 0.45:
            raise ValueError("Per-market cap exceeded (45%)")

        if vault.total_aum * allocation > max(vault.total_aum * 0.5, 1_000_000):
            raise ValueError("Position limit exceeded")

    def _update_vault_metrics(self, vault: StrategyVault) -> None:
        subscriptions = self.db.scalars(select(VaultSubscription).where(VaultSubscription.vault_id == vault.id)).all()
        total_shares = sum(item.share_balance for item in subscriptions)
        vault.nav_per_share = (vault.total_aum / total_shares) if total_shares > 0 else 1.0

        previous = self.db.scalar(
            select(VaultPerformanceSnapshot)
            .where(VaultPerformanceSnapshot.vault_id == vault.id)
            .order_by(VaultPerformanceSnapshot.timestamp.desc())
        )
        previous_nav = previous.nav_per_share if previous else 1.0
        roi_period = ((vault.nav_per_share - previous_nav) / previous_nav) if previous_nav > 0 else 0

        recent_trades = self.db.scalars(
            select(VaultTrade).where(VaultTrade.vault_id == vault.id).order_by(VaultTrade.created_at.desc()).limit(40)
        ).all()

        wins = sum(1 for trade in recent_trades if (trade.side == "BUY_YES" and trade.price >= 0.5) or (trade.side == "BUY_NO" and trade.price < 0.5))
        win_rate = wins / len(recent_trades) if recent_trades else 0
        volatility = min(1.0, abs(roi_period) * 8 + (len(recent_trades) / 400))

        vault.win_rate = round(win_rate, 4)
        vault.volatility = round(volatility, 4)
        vault.roi_7d = round(roi_period * 7, 4)
        vault.roi_30d = round(roi_period * 30, 4)

        history = list(vault.performance_history_json)
        history.append(
            {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "nav_per_share": round(vault.nav_per_share, 6),
                "aum": round(vault.total_aum, 4),
                "roi": round(roi_period, 6),
            }
        )
        vault.performance_history_json = history[-180:]

        self.db.add(
            VaultPerformanceSnapshot(
                vault_id=vault.id,
                timestamp=datetime.now(timezone.utc),
                nav_per_share=vault.nav_per_share,
                aum=vault.total_aum,
                roi_period=roi_period,
                win_rate=vault.win_rate,
                volatility=vault.volatility,
                confidence=vault.ai_confidence_score,
            )
        )

    def _slugify(self, value: str) -> str:
        cleaned = "-".join(part for part in value.lower().replace("_", "-").split(" ") if part)
        return "".join(ch for ch in cleaned if ch.isalnum() or ch == "-")[:170] or "vault"
