"""production-grade strategy engine tables

Revision ID: 20260417_000008
Revises: 20260407_000007
Create Date: 2026-04-17
"""

from __future__ import annotations

from datetime import datetime
from uuid import uuid4

from alembic import op
import sqlalchemy as sa


revision = "20260417_000008"
down_revision = "20260407_000007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "strategy_engine_strategies",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("public_id", sa.String(length=32), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("prompt", sa.Text(), nullable=False),
        sa.Column("template_key", sa.String(length=80), nullable=False),
        sa.Column("template_name", sa.String(length=160), nullable=False),
        sa.Column("stage", sa.String(length=80), nullable=False, server_default="Scaffolded"),
        sa.Column("market", sa.String(length=255), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False, server_default="0.5"),
        sa.Column("owner", sa.String(length=160), nullable=False),
        sa.Column("status", sa.String(length=40), nullable=False, server_default="Draft"),
        sa.Column("project_name", sa.String(length=180), nullable=False),
        sa.Column("project_path", sa.String(length=255), nullable=False),
        sa.Column("automation_modes_json", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_strategy_engine_strategies_public_id", "strategy_engine_strategies", ["public_id"], unique=True)
    op.create_index("ix_strategy_engine_strategies_user_id", "strategy_engine_strategies", ["user_id"], unique=False)
    op.create_index("ix_strategy_engine_strategies_template_key", "strategy_engine_strategies", ["template_key"], unique=False)
    op.create_index("ix_strategy_engine_strategies_stage", "strategy_engine_strategies", ["stage"], unique=False)
    op.create_index("ix_strategy_engine_strategies_status", "strategy_engine_strategies", ["status"], unique=False)

    op.create_table(
        "strategy_engine_runs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("strategy_id", sa.Integer(), sa.ForeignKey("strategy_engine_strategies.id"), nullable=False),
        sa.Column("run_type", sa.String(length=60), nullable=False),
        sa.Column("stage", sa.String(length=80), nullable=False),
        sa.Column("status", sa.String(length=40), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False, server_default="0.5"),
        sa.Column("is_current", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("pipeline_json", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("project_files_json", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_strategy_engine_runs_strategy_id", "strategy_engine_runs", ["strategy_id"], unique=False)
    op.create_index("ix_strategy_engine_runs_run_type", "strategy_engine_runs", ["run_type"], unique=False)
    op.create_index("ix_strategy_engine_runs_is_current", "strategy_engine_runs", ["is_current"], unique=False)

    op.create_table(
        "strategy_engine_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("strategy_id", sa.Integer(), sa.ForeignKey("strategy_engine_strategies.id"), nullable=False),
        sa.Column("run_id", sa.Integer(), sa.ForeignKey("strategy_engine_runs.id"), nullable=True),
        sa.Column("timestamp", sa.DateTime(), nullable=False),
        sa.Column("stage", sa.String(length=80), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=40), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False, server_default="0.5"),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
    )
    op.create_index("ix_strategy_engine_logs_strategy_id", "strategy_engine_logs", ["strategy_id"], unique=False)
    op.create_index("ix_strategy_engine_logs_run_id", "strategy_engine_logs", ["run_id"], unique=False)
    op.create_index("ix_strategy_engine_logs_timestamp", "strategy_engine_logs", ["timestamp"], unique=False)
    op.create_index("ix_strategy_engine_logs_stage", "strategy_engine_logs", ["stage"], unique=False)

    op.create_table(
        "strategy_engine_exports",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("strategy_id", sa.Integer(), sa.ForeignKey("strategy_engine_strategies.id"), nullable=False),
        sa.Column("export_label", sa.String(length=255), nullable=False),
        sa.Column("archive_format", sa.String(length=20), nullable=True),
        sa.Column("file_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("file_manifest_json", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_strategy_engine_exports_strategy_id", "strategy_engine_exports", ["strategy_id"], unique=False)
    op.create_index("ix_strategy_engine_exports_export_label", "strategy_engine_exports", ["export_label"], unique=False)
    op.create_index("ix_strategy_engine_exports_created_at", "strategy_engine_exports", ["created_at"], unique=False)

    op.create_table(
        "strategy_engine_rankings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("strategy_id", sa.Integer(), sa.ForeignKey("strategy_engine_strategies.id"), nullable=False),
        sa.Column("rank", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("accuracy", sa.Float(), nullable=False, server_default="0"),
        sa.Column("pnl", sa.Float(), nullable=False, server_default="0"),
        sa.Column("consistency", sa.Float(), nullable=False, server_default="0"),
        sa.Column("calibration", sa.Float(), nullable=False, server_default="0"),
        sa.Column("risk_adjusted_performance", sa.Float(), nullable=False, server_default="0"),
        sa.Column("status", sa.String(length=40), nullable=False, server_default="Draft"),
        sa.Column("last_registered_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("strategy_id", name="uq_strategy_engine_rankings_strategy_id"),
    )
    op.create_index("ix_strategy_engine_rankings_strategy_id", "strategy_engine_rankings", ["strategy_id"], unique=True)
    op.create_index("ix_strategy_engine_rankings_rank", "strategy_engine_rankings", ["rank"], unique=False)
    op.create_index("ix_strategy_engine_rankings_status", "strategy_engine_rankings", ["status"], unique=False)

    _backfill_legacy_workspace_state()


def downgrade() -> None:
    op.drop_index("ix_strategy_engine_rankings_status", table_name="strategy_engine_rankings")
    op.drop_index("ix_strategy_engine_rankings_rank", table_name="strategy_engine_rankings")
    op.drop_index("ix_strategy_engine_rankings_strategy_id", table_name="strategy_engine_rankings")
    op.drop_table("strategy_engine_rankings")

    op.drop_index("ix_strategy_engine_exports_created_at", table_name="strategy_engine_exports")
    op.drop_index("ix_strategy_engine_exports_export_label", table_name="strategy_engine_exports")
    op.drop_index("ix_strategy_engine_exports_strategy_id", table_name="strategy_engine_exports")
    op.drop_table("strategy_engine_exports")

    op.drop_index("ix_strategy_engine_logs_stage", table_name="strategy_engine_logs")
    op.drop_index("ix_strategy_engine_logs_timestamp", table_name="strategy_engine_logs")
    op.drop_index("ix_strategy_engine_logs_run_id", table_name="strategy_engine_logs")
    op.drop_index("ix_strategy_engine_logs_strategy_id", table_name="strategy_engine_logs")
    op.drop_table("strategy_engine_logs")

    op.drop_index("ix_strategy_engine_runs_is_current", table_name="strategy_engine_runs")
    op.drop_index("ix_strategy_engine_runs_run_type", table_name="strategy_engine_runs")
    op.drop_index("ix_strategy_engine_runs_strategy_id", table_name="strategy_engine_runs")
    op.drop_table("strategy_engine_runs")

    op.drop_index("ix_strategy_engine_strategies_status", table_name="strategy_engine_strategies")
    op.drop_index("ix_strategy_engine_strategies_stage", table_name="strategy_engine_strategies")
    op.drop_index("ix_strategy_engine_strategies_template_key", table_name="strategy_engine_strategies")
    op.drop_index("ix_strategy_engine_strategies_user_id", table_name="strategy_engine_strategies")
    op.drop_index("ix_strategy_engine_strategies_public_id", table_name="strategy_engine_strategies")
    op.drop_table("strategy_engine_strategies")


def _backfill_legacy_workspace_state() -> None:
    connection = op.get_bind()
    users = sa.table(
        "users",
        sa.column("id", sa.Integer()),
        sa.column("workspace_preferences", sa.JSON()),
    )
    strategies = sa.table(
        "strategy_engine_strategies",
        sa.column("id", sa.Integer()),
        sa.column("public_id", sa.String()),
        sa.column("user_id", sa.Integer()),
        sa.column("name", sa.String()),
        sa.column("prompt", sa.Text()),
        sa.column("template_key", sa.String()),
        sa.column("template_name", sa.String()),
        sa.column("stage", sa.String()),
        sa.column("market", sa.String()),
        sa.column("confidence", sa.Float()),
        sa.column("owner", sa.String()),
        sa.column("status", sa.String()),
        sa.column("project_name", sa.String()),
        sa.column("project_path", sa.String()),
        sa.column("automation_modes_json", sa.JSON()),
        sa.column("metadata_json", sa.JSON()),
        sa.column("created_at", sa.DateTime()),
        sa.column("updated_at", sa.DateTime()),
    )
    runs = sa.table(
        "strategy_engine_runs",
        sa.column("id", sa.Integer()),
        sa.column("strategy_id", sa.Integer()),
        sa.column("run_type", sa.String()),
        sa.column("stage", sa.String()),
        sa.column("status", sa.String()),
        sa.column("confidence", sa.Float()),
        sa.column("is_current", sa.Boolean()),
        sa.column("pipeline_json", sa.JSON()),
        sa.column("project_files_json", sa.JSON()),
        sa.column("metadata_json", sa.JSON()),
        sa.column("created_at", sa.DateTime()),
        sa.column("updated_at", sa.DateTime()),
    )
    logs = sa.table(
        "strategy_engine_logs",
        sa.column("strategy_id", sa.Integer()),
        sa.column("run_id", sa.Integer()),
        sa.column("timestamp", sa.DateTime()),
        sa.column("stage", sa.String()),
        sa.column("message", sa.Text()),
        sa.column("status", sa.String()),
        sa.column("confidence", sa.Float()),
        sa.column("metadata_json", sa.JSON()),
    )

    result = connection.execute(sa.select(users.c.id, users.c.workspace_preferences)).mappings()
    for row in result:
        workspace = row["workspace_preferences"] or {}
        legacy = workspace.get("strategy_engine", {})
        legacy_strategies = legacy.get("strategies", [])
        if not isinstance(legacy_strategies, list):
            continue
        for item in legacy_strategies:
            created_at = _parse_datetime(item.get("created_at"))
            updated_at = _parse_datetime(item.get("updated_at"))
            strategy_id = connection.execute(
                strategies.insert().returning(strategies.c.id).values(
                    public_id=item.get("id") or uuid4().hex[:10],
                    user_id=row["id"],
                    name=item.get("name", "Imported Strategy"),
                    prompt=item.get("prompt", "Imported legacy strategy"),
                    template_key=item.get("template_key", "event-forecasting"),
                    template_name=item.get("template_name", "Event Probability Model"),
                    stage=item.get("stage", "Scaffolded"),
                    market=item.get("market", "Custom prediction market"),
                    confidence=float(item.get("confidence", 0.5)),
                    owner=item.get("owner", "Strategy Architect Agent"),
                    status=item.get("status", "Draft"),
                    project_name=item.get("project_name", "imported-strategy"),
                    project_path=item.get("project_path", "canon_projects/imported-strategy"),
                    automation_modes_json=[],
                    metadata_json={"imported_from_workspace_preferences": True},
                    created_at=created_at,
                    updated_at=updated_at,
                )
            ).scalar_one()
            run_id = connection.execute(
                runs.insert().returning(runs.c.id).values(
                    strategy_id=strategy_id,
                    run_type="legacy-import",
                    stage=item.get("stage", "Scaffolded"),
                    status=item.get("status", "Draft"),
                    confidence=float(item.get("confidence", 0.5)),
                    is_current=True,
                    pipeline_json=item.get("pipeline", []),
                    project_files_json=item.get("project_files", []),
                    metadata_json={"imported_from_workspace_preferences": True},
                    created_at=created_at,
                    updated_at=updated_at,
                )
            ).scalar_one()
            for log in item.get("logs", []):
                connection.execute(
                    logs.insert().values(
                        strategy_id=strategy_id,
                        run_id=run_id,
                        timestamp=_parse_datetime(log.get("timestamp")),
                        stage=log.get("stage", "legacy-import"),
                        message=log.get("message", "Imported legacy log."),
                        status=log.get("status", "Completed"),
                        confidence=float(log.get("confidence", item.get("confidence", 0.5))),
                        metadata_json={"imported_from_workspace_preferences": True},
                    )
                )


def _parse_datetime(value: str | None) -> datetime:
    if not value:
        return datetime.utcnow()
    return datetime.fromisoformat(value)
