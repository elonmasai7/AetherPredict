"""chain transactions table"""

from alembic import op
import sqlalchemy as sa


revision = "20260406_000004"
down_revision = "20260406_000003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "chain_transactions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=True),
        sa.Column("tx_type", sa.String(length=40), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False),
        sa.Column("tx_hash", sa.String(length=255), nullable=True),
        sa.Column("explorer_url", sa.String(length=255), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_chain_transactions_user_id", "chain_transactions", ["user_id"], unique=False)
    op.create_index("ix_chain_transactions_market_id", "chain_transactions", ["market_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_chain_transactions_market_id", table_name="chain_transactions")
    op.drop_index("ix_chain_transactions_user_id", table_name="chain_transactions")
    op.drop_table("chain_transactions")
