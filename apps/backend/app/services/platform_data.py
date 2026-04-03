from collections import defaultdict


def sample_notifications() -> list[dict]:
    return [
        {"level": "probability", "category": "markets", "message": "BTC > $120k probability moved 6% in 10 minutes"},
        {"level": "warning", "category": "whales", "message": "Sentinel agent detected coordinated whale activity"},
        {"level": "info", "category": "disputes", "message": "HashKey TVL dispute received new evidence"},
        {"level": "hedge", "category": "portfolio", "message": "Auto-hedge recommends 20% NO protection on BTC market"},
    ]


def sample_leaderboard(kind: str) -> list[dict]:
    base = {
        "traders": [
            ("Quant Atlas", 91.0, 32.4, 74.0),
            ("Macro North", 88.0, 27.8, 69.0),
            ("Satoshi Vale", 84.0, 24.2, 67.0),
        ],
        "agents": [
            ("Liquidity Agent", 95.0, 18.4, 81.0),
            ("Arbitrage Agent", 90.0, 14.9, 79.0),
            ("Sentinel Agent", 86.0, 11.6, 76.0),
        ],
        "jurors": [
            ("Oracle Sage", 93.0, 0.0, 88.0),
            ("Delta Jury", 89.0, 0.0, 83.0),
            ("Axiom Review", 85.0, 0.0, 80.0),
        ],
    }
    return [
        {"rank": index + 1, "name": row[0], "score": row[1], "roi": row[2], "win_rate": row[3], "period": "all-time"}
        for index, row in enumerate(base[kind])
    ]


def sample_bundles() -> list[dict]:
    return [
        {
            "id": "btc-bull-basket",
            "name": "BTC Bull Basket",
            "description": "Momentum-heavy basket across BTC macro prediction markets.",
            "theme": "Crypto Momentum",
            "markets": ["btc-120k-2026", "eth-etf-volume"],
            "target_return": 24.0,
            "risk_level": "HIGH",
        },
        {
            "id": "hashkey-growth-basket",
            "name": "HashKey Growth Basket",
            "description": "Ecosystem growth bundle aligned to chain TVL and user expansion.",
            "theme": "Ecosystem Growth",
            "markets": ["hashkey-tvl-q3"],
            "target_return": 16.0,
            "risk_level": "MEDIUM",
        },
    ]


def sample_discussions() -> list[dict]:
    return [
        {
            "id": 1,
            "market_id": 1,
            "author": "AtlasResearch",
            "content": "ETF inflow momentum supports another confidence step-up into quarter close.",
            "evidence_url": "https://example.com/etf-note",
            "parent_id": None,
            "upvotes": 18,
        },
        {
            "id": 2,
            "market_id": 1,
            "author": "ChainWatcher",
            "content": "Whale wallet rotation is net positive, but I expect volatility before expiry.",
            "evidence_url": None,
            "parent_id": 1,
            "upvotes": 7,
        },
    ]


def build_exposure(markets: list, positions: list) -> list[dict]:
    exposure = defaultdict(float)
    market_map = {market.id: market for market in markets}
    total = sum(position.size * position.mark_price for position in positions) or 1
    for position in positions:
        market = market_map.get(position.market_id)
        category = market.category if market else "Other"
        exposure[category] += position.size * position.mark_price
    return [
        {"category": category, "allocation": round((value / total) * 100, 2)}
        for category, value in exposure.items()
    ]


def build_performance() -> list[dict]:
    return [
        {"label": "Mon", "pnl": 120},
        {"label": "Tue", "pnl": 180},
        {"label": "Wed", "pnl": 140},
        {"label": "Thu", "pnl": 240},
        {"label": "Fri", "pnl": 310},
    ]
