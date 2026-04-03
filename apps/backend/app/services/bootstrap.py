from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import AgentStatus, Dispute, Market, PortfolioPosition, User
from app.services.security import hash_password


def seed_demo_data(db: Session) -> None:
    has_market = db.scalar(select(Market.id).limit(1))
    if has_market:
        return

    user = User(
        email="demo@aetherpredict.ai",
        password_hash=hash_password("DemoPass123!"),
        wallet_address="0xA37HEr0000000000000000000000000000000001",
        wallet_nonce="demo-nonce",
        role="admin",
    )
    db.add(user)
    db.flush()

    markets = [
        Market(
            slug="btc-120k-2026",
            title="Will BTC exceed $120k before Dec 31 2026?",
            description="Resolves YES if BTC exceeds 120,000 USD on tracked exchanges before year end 2026.",
            category="Crypto",
            oracle_source="HashKey oracle mesh",
            expiry_at=datetime.fromisoformat("2026-12-31T23:59:00"),
            yes_probability=0.74,
            no_probability=0.26,
            ai_confidence=0.91,
            volume=842300.0,
            liquidity=320000.0,
            resolved=False,
            outcome="PENDING",
        ),
        Market(
            slug="hashkey-tvl-q3",
            title="Will HashKey Chain TVL exceed $50M by Q3?",
            description="Resolves YES if HashKey Chain TVL exceeds 50M USD by Q3 close.",
            category="Ecosystem",
            oracle_source="TVL oracle bridge",
            expiry_at=datetime.fromisoformat("2026-09-30T23:59:00"),
            yes_probability=0.58,
            no_probability=0.42,
            ai_confidence=0.79,
            volume=265800.0,
            liquidity=180000.0,
            resolved=False,
            outcome="PENDING",
        ),
        Market(
            slug="eth-etf-volume",
            title="Will ETH ETF volume double by year end?",
            description="Resolves YES if regulated ETH ETF volume doubles against Jan 1 baseline.",
            category="Macro",
            oracle_source="Institutional ETF reporting oracle",
            expiry_at=datetime.fromisoformat("2026-12-31T23:59:00"),
            yes_probability=0.63,
            no_probability=0.37,
            ai_confidence=0.84,
            volume=410500.0,
            liquidity=245000.0,
            resolved=False,
            outcome="PENDING",
        ),
    ]
    db.add_all(markets)
    db.flush()

    db.add_all(
        [
            PortfolioPosition(
                user_id=user.id,
                market_id=markets[0].id,
                side="YES",
                size=4200.0,
                avg_price=0.61,
                mark_price=0.74,
                pnl=546.0,
            ),
            PortfolioPosition(
                user_id=user.id,
                market_id=markets[1].id,
                side="YES",
                size=1900.0,
                avg_price=0.52,
                mark_price=0.58,
                pnl=114.0,
            ),
        ]
    )
    db.add_all(
        [
            AgentStatus(
                agent_key="lp-agent",
                status="INTERVENING",
                pnl=18420,
                interventions=21,
                summary="Injecting depth into high-volatility markets ahead of macro catalysts.",
                active_trades=3,
            ),
            AgentStatus(
                agent_key="sentinel-agent",
                status="WATCHING",
                pnl=0,
                interventions=7,
                summary="Monitoring suspicious wallet clusters and abnormal volume spikes.",
                active_trades=1,
            ),
        ]
    )
    db.add(
        Dispute(
            market_id=markets[1].id,
            status="OPEN",
            evidence_url="https://example.com/evidence/hashkey-q3",
            ai_summary="Supporting evidence remains mixed; review mirrored TVL feeds and oracle delay.",
            juror_votes_yes=14,
            juror_votes_no=6,
        )
    )
    db.commit()
