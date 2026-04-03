from datetime import datetime


def demo_markets():
    return [
        {
            "id": 1,
            "slug": "btc-120k-2026",
            "title": "Will BTC exceed $120k before Dec 31 2026?",
            "description": "Resolves YES if BTC exceeds 120,000 USD on tracked exchanges before year end 2026.",
            "category": "Crypto",
            "oracle_source": "HashKey oracle mesh",
            "expiry_at": datetime.fromisoformat("2026-12-31T23:59:00"),
            "yes_probability": 0.74,
            "no_probability": 0.26,
            "ai_confidence": 0.91,
            "volume": 842300.0,
            "liquidity": 320000.0,
            "resolved": False,
            "outcome": "PENDING",
        },
        {
            "id": 2,
            "slug": "hashkey-tvl-q3",
            "title": "Will HashKey Chain TVL exceed $50M by Q3?",
            "description": "Resolves YES if HashKey Chain TVL exceeds 50M USD by Q3 close.",
            "category": "Ecosystem",
            "oracle_source": "TVL oracle bridge",
            "expiry_at": datetime.fromisoformat("2026-09-30T23:59:00"),
            "yes_probability": 0.58,
            "no_probability": 0.42,
            "ai_confidence": 0.79,
            "volume": 265800.0,
            "liquidity": 180000.0,
            "resolved": False,
            "outcome": "PENDING",
        },
        {
            "id": 3,
            "slug": "eth-etf-volume",
            "title": "Will ETH ETF volume double by year end?",
            "description": "Resolves YES if regulated ETH ETF volume doubles against Jan 1 baseline.",
            "category": "Macro",
            "oracle_source": "Institutional ETF reporting oracle",
            "expiry_at": datetime.fromisoformat("2026-12-31T23:59:00"),
            "yes_probability": 0.63,
            "no_probability": 0.37,
            "ai_confidence": 0.84,
            "volume": 410500.0,
            "liquidity": 245000.0,
            "resolved": False,
            "outcome": "PENDING",
        },
    ]


def demo_positions():
    return [
        {
            "market_title": "Will BTC exceed $120k before Dec 31 2026?",
            "side": "YES",
            "size": 4200.0,
            "avg_price": 0.61,
            "mark_price": 0.74,
            "pnl": 546.0,
        },
        {
            "market_title": "Will HashKey Chain TVL exceed $50M by Q3?",
            "side": "YES",
            "size": 1900.0,
            "avg_price": 0.52,
            "mark_price": 0.58,
            "pnl": 114.0,
        },
    ]


def demo_agents():
    return [
        {
            "agent": "Liquidity Agent",
            "status": "INTERVENING",
            "pnl": 18420,
            "interventions": 21,
            "summary": "Injecting depth into high-volatility markets ahead of macro catalysts.",
        },
        {
            "agent": "Sentinel Agent",
            "status": "WATCHING",
            "pnl": 0,
            "interventions": 7,
            "summary": "Monitoring suspicious wallet clusters and abnormal volume spikes.",
        },
    ]
