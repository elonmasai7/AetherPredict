from datetime import datetime, timedelta, timezone

from liquidity import dynamic_spread_cents, implied_yes_probability, order_book_from_mid, simulate_slippage
from models import Market


def test_probability_is_normalized():
    probability = implied_yes_probability(1200, 900, 1800)
    assert 0.5 < probability < 1.0


def test_spread_tightens_with_liquidity():
    now = datetime.now(timezone.utc) + timedelta(days=5)
    tight = dynamic_spread_cents(0.52, 18000, 0.01, now, "election")
    wide = dynamic_spread_cents(0.52, 900, 0.03, now, "small event")
    assert tight < wide


def test_slippage_for_retail_size_is_reasonable():
    market = Market(
        title="Test",
        event="Test",
        end_ts=datetime.now(timezone.utc) + timedelta(days=2),
        yes_price=0.55,
        no_price=0.45,
        implied_probability=0.55,
        liquidity_usd=5000,
        spread_cents=2,
        order_book_json=order_book_from_mid(0.55, 2, 5000),
    )
    preview = simulate_slippage(50, "BUY_YES", market)
    assert preview.execution_price > 0
    assert preview.slippage_pct < 8
