"""initial schema"""

from alembic import op
import sqlalchemy as sa


revision = "20260403_000001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("wallet_address", sa.String(length=120), nullable=True),
        sa.Column("role", sa.String(length=50), nullable=False),
        sa.Column("wallet_nonce", sa.String(length=120), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "markets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("slug", sa.String(length=120), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("category", sa.String(length=80), nullable=False),
        sa.Column("oracle_source", sa.String(length=255), nullable=False),
        sa.Column("expiry_at", sa.DateTime(), nullable=False),
        sa.Column("yes_probability", sa.Float(), nullable=False),
        sa.Column("no_probability", sa.Float(), nullable=False),
        sa.Column("ai_confidence", sa.Float(), nullable=False),
        sa.Column("volume", sa.Float(), nullable=False),
        sa.Column("liquidity", sa.Float(), nullable=False),
        sa.Column("resolved", sa.Boolean(), nullable=False),
        sa.Column("outcome", sa.String(length=20), nullable=False),
    )
    op.create_index("ix_markets_slug", "markets", ["slug"], unique=True)

    op.create_table(
        "portfolio_positions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=False),
        sa.Column("side", sa.String(length=10), nullable=False),
        sa.Column("size", sa.Float(), nullable=False),
        sa.Column("avg_price", sa.Float(), nullable=False),
        sa.Column("mark_price", sa.Float(), nullable=False),
        sa.Column("pnl", sa.Float(), nullable=False),
    )

    op.create_table(
        "agent_statuses",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("agent_key", sa.String(length=80), nullable=False),
        sa.Column("status", sa.String(length=40), nullable=False),
        sa.Column("interventions", sa.Integer(), nullable=False),
        sa.Column("pnl", sa.Float(), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("active_trades", sa.Integer(), nullable=False),
    )
    op.create_index("ix_agent_statuses_agent_key", "agent_statuses", ["agent_key"], unique=True)

    op.create_table(
        "disputes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=False),
        sa.Column("status", sa.String(length=40), nullable=False),
        sa.Column("evidence_url", sa.String(length=255), nullable=False),
        sa.Column("ai_summary", sa.Text(), nullable=False),
        sa.Column("juror_votes_yes", sa.Integer(), nullable=False),
        sa.Column("juror_votes_no", sa.Integer(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("disputes")
    op.drop_index("ix_agent_statuses_agent_key", table_name="agent_statuses")
    op.drop_table("agent_statuses")
    op.drop_table("portfolio_positions")
    op.drop_index("ix_markets_slug", table_name="markets")
    op.drop_table("markets")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
