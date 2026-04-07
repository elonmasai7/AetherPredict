"""Add auto execute and collateral decimals to vaults.

Revision ID: 20260407_000007
Revises: 20260407_000006
Create Date: 2026-04-07
"""

from alembic import op
import sqlalchemy as sa

revision = "20260407_000007"
down_revision = "20260407_000006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("strategy_vaults", sa.Column("collateral_token_decimals", sa.Integer(), nullable=False, server_default="18"))
    op.add_column("strategy_vaults", sa.Column("auto_execute_enabled", sa.Boolean(), nullable=False, server_default=sa.text("false")))
    op.alter_column("strategy_vaults", "collateral_token_decimals", server_default=None)
    op.alter_column("strategy_vaults", "auto_execute_enabled", server_default=None)


def downgrade() -> None:
    op.drop_column("strategy_vaults", "auto_execute_enabled")
    op.drop_column("strategy_vaults", "collateral_token_decimals")
