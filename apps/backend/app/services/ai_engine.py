from __future__ import annotations

from collections import Counter

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import AISignal, AssetSnapshot, Market, Notification, PortfolioPosition, TradeOrder, WalletBalance


def build_signal(db: Session, market_id: int, wallet_address: str | None = None) -> AISignal:
    market = db.scalar(select(Market).where(Market.id == market_id))
    if market is None:
        raise ValueError("Market not found")

    asset = db.scalar(select(AssetSnapshot).where(AssetSnapshot.symbol == _infer_symbol(market.title)))
    positions = db.scalars(select(PortfolioPosition).where(PortfolioPosition.market_id == market_id)).all()
    trade_count = db.scalars(select(TradeOrder).where(TradeOrder.market_id == market_id)).all()

    momentum = asset.change_24h if asset else 0
    volatility = asset.volatility_pct if asset else 0
    exposure = sum(position.size * position.mark_price for position in positions)
    confidence = max(0.05, min(0.99, 0.55 + (momentum / 100) - (volatility / 500)))
    action = "BUY_YES" if momentum >= 0 else "BUY_NO"
    risk = "HIGH" if volatility >= 10 else "MEDIUM" if volatility >= 4 else "LOW"
    reasoning = (
        f"{market.title} is tracking {asset.symbol if asset else 'market'} momentum "
        f"({momentum:.2f}% 24h) with volatility {volatility:.2f}% and {len(trade_count)} recorded trades."
    )
    signal = AISignal(
        market_id=market.id,
        signal_type="signal",
        action=action,
        confidence=round(confidence, 4),
        risk=risk,
        reasoning=reasoning,
        payload_json={
            "wallet_address": wallet_address,
            "momentum_24h": momentum,
            "volatility_pct": volatility,
            "open_exposure_usd": round(exposure, 2),
        },
    )
    db.add(signal)
    db.add(
        Notification(
            level="info",
            category="ai",
            message=f"AI signal updated for {market.title}: {action} ({confidence * 100:.1f}% confidence)",
            metadata_json={"market_id": market.id},
        )
    )
    db.commit()
    db.refresh(signal)
    return signal


def build_risk_analysis(db: Session, wallet_address: str) -> dict:
    balances = db.scalars(select(WalletBalance).where(WalletBalance.wallet_address == wallet_address)).all()
    total_value = sum(balance.value_usd for balance in balances)
    symbol_count = Counter(balance.symbol for balance in balances)
    concentration = max((balance.value_usd for balance in balances), default=0)
    return {
        "wallet_address": wallet_address,
        "total_value_usd": round(total_value, 2),
        "asset_count": len(symbol_count),
        "largest_position_usd": round(concentration, 2),
        "risk_level": "HIGH" if concentration > total_value * 0.6 else "MEDIUM" if concentration else "LOW",
    }


def _infer_symbol(title: str) -> str:
    upper = title.upper()
    if "BTC" in upper:
        return "BTC"
    if "ETH" in upper:
        return "ETH"
    if "SOL" in upper:
        return "SOL"
    if "HASHKEY" in upper or "HSK" in upper:
        return "HSK"
    return "BTC"
