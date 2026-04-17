from datetime import datetime
import io
from pathlib import Path
import tarfile
import zipfile

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.db.session import Base
from app.models.entities import (
    AgentStatus,
    Market,
    StrategyEngineExport,
    StrategyEngineLog,
    StrategyEngineRanking,
    StrategyEngineRun,
    StrategyEngineStrategy,
    User,
)
from app.services.strategy_engine_service import StrategyEngineService


TEST_DB_PATH = Path("/tmp/aetherpredict_strategy_engine_test.db")
if TEST_DB_PATH.exists():
    TEST_DB_PATH.unlink()

engine = create_engine(
    f"sqlite:///{TEST_DB_PATH}",
    connect_args={"check_same_thread": False},
)
TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base.metadata.create_all(bind=engine)


def _seed_data(db: Session) -> User:
    user = User(
        email="strategy@example.com",
        password_hash="hashed",
        workspace_preferences={},
        notification_preferences={},
        account_preferences={},
    )
    db.add(user)
    db.add(
        Market(
            slug="btc-120k",
            title="BTC > 120k before Dec 2026",
            description="BTC prediction market",
            category="crypto",
            oracle_source="oracle",
            expiry_at=datetime(2026, 12, 31, 0, 0, 0),
        )
    )
    db.add(
        AgentStatus(
            agent_key="strategy-architect-agent",
            status="ACTIVE",
            interventions=12,
            pnl=0,
            summary="Forecasting workflow architect",
            active_trades=0,
        )
    )
    db.commit()
    db.refresh(user)
    return user

def setup_module():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    if not db.query(User).filter(User.email == "strategy@example.com").first():
        _seed_data(db)
    db.close()


def test_strategy_engine_build_and_canon_flow():
    db = TestingSessionLocal()
    try:
        user = db.query(User).filter(User.email == "strategy@example.com").one()
        service = StrategyEngineService(db)

        state = service.get_state(user)
        assert state.metrics.active_strategies == 0

        build = service.build_from_prompt(
            user,
            "Build an arbitrage detection model across related BTC prediction markets using ETF flows and sentiment.",
        )
        assert build.strategy.template_name == "Sentiment-Based Forecast Engine"
        assert build.project_files[0].path == "canon.json"
        assert "arbitrage-detection" in build.project_files[0].content
        assert db.query(StrategyEngineStrategy).count() == 1
        assert db.query(StrategyEngineRun).count() == 1
        assert db.query(StrategyEngineLog).count() >= 2

        strategy_id = build.strategy.id

        start = service.run_canon_action(user, strategy_id, "start")
        assert start.strategy.stage == "Simulation"
        assert db.query(StrategyEngineRun).count() == 2

        deploy = service.run_canon_action(user, strategy_id, "deploy")
        assert deploy.strategy.stage == "Live deployment"
        assert db.query(StrategyEngineRun).count() == 3

        ranking = service.ranking(user)
        assert ranking.entries[0].status == "Registered"
        assert db.query(StrategyEngineRanking).count() == 1

        monitor = service.monitor(user)
        assert any(item.stage == "canon deploy" for item in monitor.logs)

        export = service.export_project(user, strategy_id)
        assert export.project_name
        assert len(export.files) >= 4
        assert db.query(StrategyEngineExport).count() == 1

        zip_name, zip_media_type, zip_payload = service.export_project_archive(
            user, strategy_id, "zip"
        )
        assert zip_name.endswith(".zip")
        assert zip_media_type == "application/zip"
        with zipfile.ZipFile(io.BytesIO(zip_payload), "r") as archive:
            names = archive.namelist()
            assert any(name.endswith("/canon.json") for name in names)

        tar_name, tar_media_type, tar_payload = service.export_project_archive(
            user, strategy_id, "tar"
        )
        assert tar_name.endswith(".tar")
        assert tar_media_type == "application/x-tar"
        with tarfile.open(fileobj=io.BytesIO(tar_payload), mode="r") as archive:
            names = archive.getnames()
            assert any(name.endswith("/README.md") for name in names)
        assert db.query(StrategyEngineExport).count() == 3
    finally:
        db.close()
