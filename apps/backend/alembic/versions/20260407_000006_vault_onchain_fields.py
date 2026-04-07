"""vault on-chain fields"""

from alembic import op
import sqlalchemy as sa


revision = "20260407_000006"
down_revision = "20260407_000005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("strategy_vaults", sa.Column("on_chain_address", sa.String(length=120), nullable=True))
    op.add_column("strategy_vaults", sa.Column("share_token_address", sa.String(length=120), nullable=True))
    op.add_column("strategy_vaults", sa.Column("collateral_token_address", sa.String(length=120), nullable=True))
    op.create_index("ix_strategy_vaults_on_chain_address", "strategy_vaults", ["on_chain_address"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_strategy_vaults_on_chain_address", table_name="strategy_vaults")
    op.drop_column("strategy_vaults", "collateral_token_address")
    op.drop_column("strategy_vaults", "share_token_address")
    op.drop_column("strategy_vaults", "on_chain_address")
