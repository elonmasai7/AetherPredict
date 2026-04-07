from __future__ import annotations

import asyncio
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.core.config import settings
from app.models.entities import (
    ChainTransaction,
    CopiedTrade,
    Dispute,
    Market,
    PortfolioPosition,
    StrategyVault,
    TradeOrder,
    TransactionRecord,
)
from app.services.blockchain_service import BlockchainService
from app.services.redis_bus import publish


async def tx_receipt_worker() -> None:
    chain = BlockchainService()
    while True:
        db: Session = SessionLocal()
        try:
            pending = db.scalars(
                select(TradeOrder).where(TradeOrder.status.in_(["PENDING_CONFIRMATION", "BROADCASTING"]))
            ).all()
            for trade in pending:
                if not trade.tx_hash:
                    continue
                receipt = chain.get_receipt(trade.tx_hash)
                if receipt is None:
                    continue
                status = receipt.get("status", 0)
                block_number = receipt.get("blockNumber")
                gas_used = receipt.get("gasUsed")
                timestamp = datetime.now(timezone.utc)
                trade.status = "CONFIRMED" if status == 1 else "REVERTED"
                tx_row = db.scalar(
                    select(TransactionRecord).where(TransactionRecord.trade_id == trade.id)
                )
                if tx_row:
                    tx_row.status = trade.status
                    tx_row.block_number = block_number
                    tx_row.gas_used = gas_used
                    tx_row.confirmed_at = timestamp
                market = db.scalar(select(Market).where(Market.id == trade.market_id))
                if market and market.on_chain_address:
                    events = chain.parse_market_events(market.on_chain_address, receipt)
                    if tx_row:
                        tx_row.event_logs = {"events": events}
                    _apply_events(db, trade, market, events)
                db.commit()
                await publish(
                    settings.tx_websocket_channel,
                    {
                        "type": "tx",
                        "trade_id": trade.id,
                        "market_id": trade.market_id,
                        "status": trade.status,
                        "tx_hash": trade.tx_hash,
                        "timestamp": timestamp.isoformat(),
                    },
                )
            chain_txs = db.scalars(
                select(ChainTransaction).where(ChainTransaction.status == "PENDING_CONFIRMATION")
            ).all()
            for tx in chain_txs:
                if not tx.tx_hash:
                    continue
                receipt = chain.get_receipt(tx.tx_hash)
                if receipt is None:
                    continue
                tx.status = "CONFIRMED" if receipt.get("status", 0) == 1 else "REVERTED"
                tx.metadata_json = {**(tx.metadata_json or {}), "receipt": receipt}
                if tx.tx_type == "MARKET_CREATE":
                    events = chain.parse_factory_events(receipt)
                    if events and tx.market_id:
                        market = db.scalar(select(Market).where(Market.id == tx.market_id))
                        if market:
                            market.on_chain_address = events[0]["args"].get("market")
                    tx.metadata_json = {**(tx.metadata_json or {}), "event_logs": events}
                if tx.tx_type == "VAULT_CREATE":
                    events = chain.parse_vault_factory_events(receipt)
                    vault_id = (tx.metadata_json or {}).get("vault_id")
                    if events and vault_id:
                        vault = db.scalar(select(StrategyVault).where(StrategyVault.id == vault_id))
                        if vault:
                            vault.on_chain_address = events[0]["args"].get("vault")
                    tx.metadata_json = {**(tx.metadata_json or {}), "event_logs": events}
                if tx.tx_type == "DISPUTE" and tx.market_id:
                    market = db.scalar(select(Market).where(Market.id == tx.market_id))
                    if market:
                        market.resolved = False
                        if market.on_chain_address:
                            events = chain.parse_market_events(market.on_chain_address, receipt)
                            tx.metadata_json = {**(tx.metadata_json or {}), "event_logs": events}
                    if tx.status == "CONFIRMED":
                        db.add(
                            Dispute(
                                market_id=tx.market_id,
                                user_id=tx.user_id,
                                status="OPEN",
                                evidence_url=tx.metadata_json.get("evidence_uri", ""),
                                ai_summary="On-chain dispute submitted.",
                                juror_votes_yes=0,
                                juror_votes_no=0,
                            )
                        )
                db.commit()
                if tx.tx_type in {"VAULT_CREATE", "VAULT_DEPOSIT", "VAULT_WITHDRAW", "VAULT_EXECUTE", "VAULT_REBALANCE", "VAULT_DISTRIBUTE"}:
                    await publish(
                        settings.vault_websocket_channel,
                        {
                            "type": "vault_tx",
                            "tx_id": tx.id,
                            "status": tx.status,
                            "tx_hash": tx.tx_hash,
                            "vault_id": (tx.metadata_json or {}).get("vault_id"),
                            "timestamp": datetime.now(timezone.utc).isoformat(),
                        },
                    )
                if tx.tx_type == "COPY_TRADE":
                    copied_id = (tx.metadata_json or {}).get("copied_trade_id")
                    follower_trade_id = (tx.metadata_json or {}).get("follower_trade_id")
                    if follower_trade_id:
                        trade = db.scalar(select(TradeOrder).where(TradeOrder.id == follower_trade_id))
                        if trade:
                            trade.status = "CONFIRMED" if tx.status == "CONFIRMED" else "REVERTED"
                    if copied_id:
                        copied = db.scalar(select(CopiedTrade).where(CopiedTrade.id == copied_id))
                        if copied:
                            copied.status = "CONFIRMED" if tx.status == "CONFIRMED" else "REVERTED"
                    await publish(
                        settings.copy_websocket_channel,
                        {
                            "type": "copy_tx",
                            "tx_id": tx.id,
                            "status": tx.status,
                            "tx_hash": tx.tx_hash,
                            "timestamp": datetime.now(timezone.utc).isoformat(),
                        },
                    )
                await publish(
                    settings.tx_websocket_channel,
                    {
                        "type": "tx",
                        "tx_id": tx.id,
                        "market_id": tx.market_id,
                        "status": tx.status,
                        "tx_hash": tx.tx_hash,
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                    },
                )
        except Exception:
            db.rollback()
        finally:
            db.close()
        await asyncio.sleep(5)


def _apply_events(db: Session, trade: TradeOrder, market: Market, events: list[dict]) -> None:
    for event in events:
        if event["event"] == "PositionBought":
            collateral = float(event["args"].get("collateral", 0))
            minted = float(event["args"].get("minted", 0))
            market.volume += collateral
            market.liquidity += collateral
            position = db.scalar(
                select(PortfolioPosition).where(
                    PortfolioPosition.user_id == trade.user_id,
                    PortfolioPosition.market_id == trade.market_id,
                    PortfolioPosition.side == trade.side,
                )
            )
            if position:
                position.size += minted
                position.mark_price = trade.price
            else:
                db.add(
                    PortfolioPosition(
                        user_id=trade.user_id,
                        market_id=trade.market_id,
                        side=trade.side,
                        size=minted,
                        avg_price=trade.price,
                        mark_price=trade.price,
                        pnl=0,
                        status="OPEN",
                    )
                )
        if event["event"] == "PositionSold":
            collateral = float(event["args"].get("collateralReturned", 0))
            market.volume += collateral
        if event["event"] == "RewardsClaimed":
            market.liquidity = max(0, market.liquidity - float(event["args"].get("reward", 0)))
