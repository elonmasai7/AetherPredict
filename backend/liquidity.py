from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from math import exp

from models import Market


def clamp(value: float, minimum: float, maximum: float) -> float:
    return max(minimum, min(maximum, value))


def implied_yes_probability(yes_shares: float, no_shares: float, b_param: float) -> float:
    yes = exp(yes_shares / max(b_param, 1.0))
    no = exp(no_shares / max(b_param, 1.0))
    return clamp(yes / (yes + no), 0.01, 0.99)


def realized_volatility(history: list[float]) -> float:
    if len(history) < 2:
        return 0.0
    deltas = [abs(history[idx] - history[idx - 1]) for idx in range(1, len(history))]
    return sum(deltas) / len(deltas)


def spread_tier(spread_cents: int) -> str:
    if spread_cents <= 2:
        return "High Liquidity"
    if spread_cents <= 5:
        return "Moderate Liquidity"
    if spread_cents <= 10:
        return "Low Liquidity"
    return "Illiquid"


def dynamic_spread_cents(
    probability: float,
    liquidity_usd: float,
    volatility: float,
    end_ts: datetime,
    event_tag: str = "",
) -> int:
    now = datetime.now(timezone.utc)
    hours_left = max((end_ts - now).total_seconds() / 3600, 0)
    event_bonus = -1.0 if any(token in event_tag.lower() for token in ("election", "fed", "rates", "trump")) else 0.0
    liquidity_factor = 4.8 - min(liquidity_usd / 15000, 3.0)
    volatility_factor = volatility * 120
    time_factor = 3.0 if hours_left < 24 else 1.5 if hours_left < 72 else 0.0
    probability_factor = abs(probability - 0.5) * 4
    raw = 1.5 + liquidity_factor + volatility_factor + time_factor + probability_factor + event_bonus
    return max(1, int(round(raw)))


def order_book_from_mid(mid: float, spread_cents: int, liquidity_usd: float) -> dict:
    step = max(0.005, spread_cents / 200)
    yes_bids = []
    yes_asks = []
    no_bids = []
    no_asks = []
    base_size = max(12.0, liquidity_usd / 2400)
    for level in range(6):
        depth_multiplier = max(0.2, 1 - (level * 0.12))
        bid = clamp(mid - (step * (level + 0.5)), 0.01, 0.99)
        ask = clamp(mid + (step * (level + 0.5)), 0.01, 0.99)
        size = round(base_size * depth_multiplier, 2)
        yes_bids.append({"price": round(bid, 4), "shares": size})
        yes_asks.append({"price": round(ask, 4), "shares": size})
        no_bid = clamp(1 - ask, 0.01, 0.99)
        no_ask = clamp(1 - bid, 0.01, 0.99)
        no_bids.append({"price": round(no_bid, 4), "shares": size})
        no_asks.append({"price": round(no_ask, 4), "shares": size})
    return {
        "yes_bids": yes_bids,
        "yes_asks": yes_asks,
        "no_bids": no_bids,
        "no_asks": no_asks,
        "best_yes_bid": yes_bids[0]["price"],
        "best_yes_ask": yes_asks[0]["price"],
        "best_no_bid": no_bids[0]["price"],
        "best_no_ask": no_asks[0]["price"],
    }


@dataclass
class SlippagePreview:
    execution_price: float
    slippage_pct: float
    price_impact: float


def simulate_slippage(notional: float, side: str, market: Market) -> SlippagePreview:
    order_book = market.order_book_json or order_book_from_mid(market.yes_price, market.spread_cents, market.liquidity_usd)
    levels = order_book["yes_asks"] if side.upper() == "BUY_YES" else order_book["no_asks"] if side.upper() == "BUY_NO" else order_book["yes_bids"] if side.upper() == "SELL_YES" else order_book["no_bids"]
    shares_remaining = max(notional / max(market.yes_price if "YES" in side else market.no_price, 0.01), 1)
    filled_value = 0.0
    consumed = 0.0
    for level in levels:
        fill = min(shares_remaining, level["shares"])
        filled_value += fill * level["price"]
        consumed += fill
        shares_remaining -= fill
        if shares_remaining <= 0:
            break
    if shares_remaining > 0:
        fallback_price = clamp((levels[-1]["price"] if levels else market.yes_price) + 0.02, 0.01, 0.99)
        filled_value += shares_remaining * fallback_price
        consumed += shares_remaining
    execution_price = filled_value / max(consumed, 1)
    reference = levels[0]["price"] if levels else (market.yes_price if "YES" in side else market.no_price)
    slippage_pct = abs(execution_price - reference) / max(reference, 0.01) * 100
    return SlippagePreview(
        execution_price=round(execution_price, 4),
        slippage_pct=round(slippage_pct, 2),
        price_impact=round(slippage_pct * 0.9, 2),
    )


def liquidity_snapshot(market: Market) -> dict:
    order_book = market.order_book_json or order_book_from_mid(market.yes_price, market.spread_cents, market.liquidity_usd)
    spread = int(round((order_book["best_yes_ask"] - order_book["best_yes_bid"]) * 100))
    return {
        "market_id": market.id,
        "yes_price": round(market.yes_price, 4),
        "no_price": round(market.no_price, 4),
        "implied_probability": round(market.implied_probability, 4),
        "bid_ask_spread_cents": spread,
        "spread_tier": spread_tier(spread),
        "order_book": order_book,
        "depth_usd": {
            "yes": round(sum(level["shares"] * level["price"] for level in order_book["yes_bids"]), 2),
            "no": round(sum(level["shares"] * level["price"] for level in order_book["no_bids"]), 2),
        },
        "maker_concentration": round(market.maker_concentration, 2),
        "liquidity_usd": round(market.liquidity_usd, 2),
        "volume_usd": round(market.total_volume, 2),
    }
