from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.entities import Market, Notification, PortfolioPosition, TradeOrder, TransactionRecord, User


class ExecutionService:
    def __init__(self, db: Session):
        self.db = db

    def execute_prediction(
        self,
        *,
        user: User,
        market: Market,
        side: str,
        collateral_amount: float,
        price: float,
        wallet_address: str | None,
        order_type: str = "MARKET",
        signed_payload: str | None = None,
        liquidity_preview: dict | None = None,
    ) -> TradeOrder:
        shares = round(collateral_amount / max(price, 0.01), 6)
        status = "PENDING_CONFIRMATION" if signed_payload else "SUBMITTED"
        trade = TradeOrder(
            user_id=user.id,
            market_id=market.id,
            side=side,
            order_type=order_type,
            collateral_amount=collateral_amount,
            price=price,
            shares=shares,
            status=status,
            wallet_address=wallet_address,
            signed_payload=signed_payload,
            metadata_json={
                "liquidity_preview": liquidity_preview or {},
                "execution_mode": "on_chain" if signed_payload else "server_book",
                "confidence_label": (market.metadata_json or {}).get("confidence_label", "Actionable"),
            },
        )
        self.db.add(trade)

        position = PortfolioPosition(
            user_id=user.id,
            market_id=market.id,
            side=side,
            size=shares,
            avg_price=price,
            mark_price=price,
            realized_pnl=0,
            unrealized_pnl=0,
            pnl=0,
            status="OPEN",
        )
        self.db.add(position)

        self.db.add(
            TransactionRecord(
                user_id=user.id,
                trade=trade,
                transaction_type="PREDICTION",
                asset_symbol=market.collateral_token or "USDC",
                amount=collateral_amount,
                status=status,
                tx_hash=None,
                explorer_url=None,
                metadata_json={
                    "market_title": market.title,
                    "side": side,
                    "execution_mode": "server_book" if not signed_payload else "signed",
                },
            )
        )
        self.db.add(
            Notification(
                user_id=user.id,
                level="info",
                category="prediction",
                message=f"{side} prediction queued for {market.title}",
                metadata_json={"market_id": market.id, "side": side, "status": status},
            )
        )
        impact = min(0.025, collateral_amount / max(market.liquidity * 40, 1))
        if side == "YES":
            market.yes_probability = min(0.99, round(market.yes_probability + impact, 4))
        else:
            market.yes_probability = max(0.01, round(market.yes_probability - impact, 4))
        market.no_probability = round(1 - market.yes_probability, 4)
        market.volume += collateral_amount
        self.db.commit()
        self.db.refresh(trade)
        return trade
