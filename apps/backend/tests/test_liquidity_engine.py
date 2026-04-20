from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.session import Base
from app.models.entities import Market, TradeOrder, User, VaultSubscription
from app.services.liquidity_engine import LiquidityIntelligenceService


TEST_DB_PATH = Path("/tmp/aetherpredict_liquidity_test.db")
if TEST_DB_PATH.exists():
    TEST_DB_PATH.unlink()

engine = create_engine(
    f"sqlite:///{TEST_DB_PATH}",
    connect_args={"check_same_thread": False},
)
TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base.metadata.create_all(bind=engine)


def setup_module():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def test_prediction_market_liquidity_snapshot_and_dashboard():
    db = TestingSessionLocal()
    try:
        user = User(
            email="liquidity@example.com",
            password_hash="hashed",
            workspace_preferences={},
            notification_preferences={},
            account_preferences={},
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        market = Market(
            slug="btc-150k-2026",
            title="Will BTC exceed $150k after the next ETF decision?",
            description="Prediction market for a BTC regulatory catalyst.",
            category="Macro",
            oracle_source="oracle",
            expiry_at=datetime.now(UTC) + timedelta(days=10),
            yes_probability=0.64,
            no_probability=0.36,
            ai_confidence=0.71,
            volume=1_250_000,
            liquidity=2_400_000,
            metadata_json={"probability_points": [0.48, 0.52, 0.58, 0.64]},
        )
        db.add(market)
        db.commit()
        db.refresh(market)

        db.add_all(
            [
                TradeOrder(
                    user_id=user.id,
                    market_id=market.id,
                    side="YES",
                    order_type="MARKET",
                    collateral_amount=1250,
                    price=0.62,
                    shares=2016,
                    status="CONFIRMED",
                ),
                TradeOrder(
                    user_id=user.id,
                    market_id=market.id,
                    side="NO",
                    order_type="MARKET",
                    collateral_amount=650,
                    price=0.39,
                    shares=1666,
                    status="CONFIRMED",
                ),
                VaultSubscription(
                    vault_id=1,
                    user_id=user.id,
                    wallet_address="0xabc",
                    deposited_amount=20000,
                    share_balance=20000,
                    metadata_json={},
                ),
            ]
        )
        db.commit()

        service = LiquidityIntelligenceService(db)
        snapshot = service.build_market_snapshot(market)
        preview = service.build_slippage_preview(market, "YES", 50)
        dashboard = service.build_dashboard()

        assert snapshot.summary["spread_width_cents"] >= 1
        assert snapshot.summary["liquidity_label"] in {
            "High Liquidity",
            "Moderate Liquidity",
            "Low Liquidity",
            "Illiquid",
        }
        assert snapshot.detail["depth"]["yes_depth_total"] > 0
        assert "Top 3 LPs provide" in snapshot.detail["concentration"]["summary"]
        assert snapshot.detail["market_maker"]["agent_name"] == "Aether MM-01"
        assert preview["expected_execution_price"] > 0
        assert preview["slippage_pct"] >= 0.2
        assert dashboard["market_count"] >= 1
        assert dashboard["market_rankings"][0]["market_id"] == market.id
    finally:
        db.close()
