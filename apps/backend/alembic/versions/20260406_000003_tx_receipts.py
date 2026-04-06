"""tx receipt fields"""

from alembic import op
import sqlalchemy as sa


revision = "20260406_000003"
down_revision = "20260406_000002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("transaction_records", sa.Column("block_number", sa.Integer(), nullable=True))
    op.add_column("transaction_records", sa.Column("gas_used", sa.Integer(), nullable=True))
    op.add_column("transaction_records", sa.Column("confirmed_at", sa.DateTime(), nullable=True))
    op.add_column("transaction_records", sa.Column("event_logs", sa.JSON(), nullable=False, server_default="{}"))


def downgrade() -> None:
    op.drop_column("transaction_records", "event_logs")
    op.drop_column("transaction_records", "confirmed_at")
    op.drop_column("transaction_records", "gas_used")
    op.drop_column("transaction_records", "block_number")
