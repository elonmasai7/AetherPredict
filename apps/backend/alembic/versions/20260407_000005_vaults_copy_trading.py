"""strategy vaults and copy forecasts"""

from alembic import op
import sqlalchemy as sa


revision = "20260407_000005"
down_revision = "20260406_000004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "strategy_vaults",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=160), nullable=False),
        sa.Column("slug", sa.String(length=180), nullable=False),
        sa.Column("strategy_description", sa.Text(), nullable=False),
        sa.Column("risk_profile", sa.String(length=30), nullable=False, server_default="MEDIUM"),
        sa.Column("manager_type", sa.String(length=20), nullable=False, server_default="AI"),
        sa.Column("manager_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="ACTIVE"),
        sa.Column("target_markets_json", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("current_allocation_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("performance_history_json", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("ai_confidence_score", sa.Float(), nullable=False, server_default="0.5"),
        sa.Column("total_aum", sa.Float(), nullable=False, server_default="0"),
        sa.Column("nav_per_share", sa.Float(), nullable=False, server_default="1"),
        sa.Column("active_subscribers", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("roi_7d", sa.Float(), nullable=False, server_default="0"),
        sa.Column("roi_30d", sa.Float(), nullable=False, server_default="0"),
        sa.Column("win_rate", sa.Float(), nullable=False, server_default="0"),
        sa.Column("volatility", sa.Float(), nullable=False, server_default="0"),
        sa.Column("management_fee_bps", sa.Integer(), nullable=False, server_default="200"),
        sa.Column("performance_fee_bps", sa.Integer(), nullable=False, server_default="1500"),
        sa.Column("paused", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("archived", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_strategy_vaults_title", "strategy_vaults", ["title"], unique=False)
    op.create_index("ix_strategy_vaults_slug", "strategy_vaults", ["slug"], unique=True)
    op.create_index("ix_strategy_vaults_status", "strategy_vaults", ["status"], unique=False)
    op.create_index("ix_strategy_vaults_manager_user_id", "strategy_vaults", ["manager_user_id"], unique=False)

    op.create_table(
        "vault_markets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("vault_id", sa.Integer(), sa.ForeignKey("strategy_vaults.id"), nullable=False),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=False),
        sa.Column("weight", sa.Float(), nullable=False, server_default="0"),
        sa.Column("max_allocation_pct", sa.Float(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("vault_id", "market_id", name="uq_vault_market"),
    )
    op.create_index("ix_vault_markets_vault_id", "vault_markets", ["vault_id"], unique=False)
    op.create_index("ix_vault_markets_market_id", "vault_markets", ["market_id"], unique=False)

    op.create_table(
        "vault_subscriptions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("vault_id", sa.Integer(), sa.ForeignKey("strategy_vaults.id"), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("wallet_address", sa.String(length=120), nullable=False),
        sa.Column("deposited_amount", sa.Float(), nullable=False, server_default="0"),
        sa.Column("share_balance", sa.Float(), nullable=False, server_default="0"),
        sa.Column("realized_pnl", sa.Float(), nullable=False, server_default="0"),
        sa.Column("unrealized_pnl", sa.Float(), nullable=False, server_default="0"),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="ACTIVE"),
        sa.Column("auto_compound", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("vault_id", "user_id", name="uq_vault_subscription"),
    )
    op.create_index("ix_vault_subscriptions_vault_id", "vault_subscriptions", ["vault_id"], unique=False)
    op.create_index("ix_vault_subscriptions_user_id", "vault_subscriptions", ["user_id"], unique=False)
    op.create_index("ix_vault_subscriptions_wallet_address", "vault_subscriptions", ["wallet_address"], unique=False)

    op.create_table(
        "vault_trades",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("vault_id", sa.Integer(), sa.ForeignKey("strategy_vaults.id"), nullable=False),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=False),
        sa.Column("side", sa.String(length=10), nullable=False),
        sa.Column("allocation", sa.Float(), nullable=False, server_default="0"),
        sa.Column("amount", sa.Float(), nullable=False, server_default="0"),
        sa.Column("price", sa.Float(), nullable=False, server_default="0"),
        sa.Column("confidence", sa.Float(), nullable=False, server_default="0"),
        sa.Column("reasoning", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="EXECUTED"),
        sa.Column("tx_hash", sa.String(length=255), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_vault_trades_vault_id", "vault_trades", ["vault_id"], unique=False)
    op.create_index("ix_vault_trades_market_id", "vault_trades", ["market_id"], unique=False)

    op.create_table(
        "vault_performance_snapshots",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("vault_id", sa.Integer(), sa.ForeignKey("strategy_vaults.id"), nullable=False),
        sa.Column("timestamp", sa.DateTime(), nullable=False),
        sa.Column("nav_per_share", sa.Float(), nullable=False, server_default="1"),
        sa.Column("aum", sa.Float(), nullable=False, server_default="0"),
        sa.Column("roi_period", sa.Float(), nullable=False, server_default="0"),
        sa.Column("win_rate", sa.Float(), nullable=False, server_default="0"),
        sa.Column("volatility", sa.Float(), nullable=False, server_default="0"),
        sa.Column("confidence", sa.Float(), nullable=False, server_default="0"),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
    )
    op.create_index("ix_vault_performance_snapshots_vault_id", "vault_performance_snapshots", ["vault_id"], unique=False)
    op.create_index("ix_vault_performance_snapshots_timestamp", "vault_performance_snapshots", ["timestamp"], unique=False)

    op.create_table(
        "copy_relationships",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("follower_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("source_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("source_type", sa.String(length=30), nullable=False, server_default="TRADER"),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="ACTIVE"),
        sa.Column("allocation_pct", sa.Float(), nullable=False, server_default="0.1"),
        sa.Column("max_loss_pct", sa.Float(), nullable=False, server_default="0.1"),
        sa.Column("risk_level", sa.String(length=20), nullable=False, server_default="MEDIUM"),
        sa.Column("auto_stop_threshold", sa.Float(), nullable=False, server_default="0.08"),
        sa.Column("max_follower_exposure", sa.Float(), nullable=False, server_default="5000"),
        sa.Column("trader_commission_bps", sa.Integer(), nullable=False, server_default="1500"),
        sa.Column("platform_fee_bps", sa.Integer(), nullable=False, server_default="200"),
        sa.Column("allowed_markets_json", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("follower_user_id", "source_user_id", name="uq_copy_relationship"),
    )
    op.create_index("ix_copy_relationships_follower_user_id", "copy_relationships", ["follower_user_id"], unique=False)
    op.create_index("ix_copy_relationships_source_user_id", "copy_relationships", ["source_user_id"], unique=False)

    op.create_table(
        "copy_allocation_rules",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("relationship_id", sa.Integer(), sa.ForeignKey("copy_relationships.id"), nullable=False),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=True),
        sa.Column("allocation_pct", sa.Float(), nullable=False, server_default="0.1"),
        sa.Column("per_market_cap", sa.Float(), nullable=False, server_default="1000"),
        sa.Column("position_limit", sa.Float(), nullable=False, server_default="5000"),
        sa.Column("slippage_bps", sa.Integer(), nullable=False, server_default="75"),
        sa.Column("stop_loss_pct", sa.Float(), nullable=False, server_default="0.08"),
        sa.Column("active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_copy_allocation_rules_relationship_id", "copy_allocation_rules", ["relationship_id"], unique=False)
    op.create_index("ix_copy_allocation_rules_market_id", "copy_allocation_rules", ["market_id"], unique=False)

    op.create_table(
        "copied_trades",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("relationship_id", sa.Integer(), sa.ForeignKey("copy_relationships.id"), nullable=False),
        sa.Column("source_trade_id", sa.Integer(), sa.ForeignKey("trade_orders.id"), nullable=False),
        sa.Column("follower_trade_id", sa.Integer(), sa.ForeignKey("trade_orders.id"), nullable=True),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=False),
        sa.Column("copied_allocation", sa.Float(), nullable=False, server_default="0"),
        sa.Column("copied_amount", sa.Float(), nullable=False, server_default="0"),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="EXECUTED"),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("source_tx_hash", sa.String(length=255), nullable=True),
        sa.Column("follower_tx_hash", sa.String(length=255), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_copied_trades_relationship_id", "copied_trades", ["relationship_id"], unique=False)
    op.create_index("ix_copied_trades_source_trade_id", "copied_trades", ["source_trade_id"], unique=False)
    op.create_index("ix_copied_trades_follower_trade_id", "copied_trades", ["follower_trade_id"], unique=False)
    op.create_index("ix_copied_trades_market_id", "copied_trades", ["market_id"], unique=False)

    op.create_table(
        "copy_performance_snapshots",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("relationship_id", sa.Integer(), sa.ForeignKey("copy_relationships.id"), nullable=False),
        sa.Column("timestamp", sa.DateTime(), nullable=False),
        sa.Column("roi_7d", sa.Float(), nullable=False, server_default="0"),
        sa.Column("roi_30d", sa.Float(), nullable=False, server_default="0"),
        sa.Column("lifetime_accuracy", sa.Float(), nullable=False, server_default="0"),
        sa.Column("copied_followers", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("assets_copied", sa.Float(), nullable=False, server_default="0"),
        sa.Column("drawdown_pct", sa.Float(), nullable=False, server_default="0"),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
    )
    op.create_index("ix_copy_performance_snapshots_relationship_id", "copy_performance_snapshots", ["relationship_id"], unique=False)
    op.create_index("ix_copy_performance_snapshots_timestamp", "copy_performance_snapshots", ["timestamp"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_copy_performance_snapshots_timestamp", table_name="copy_performance_snapshots")
    op.drop_index("ix_copy_performance_snapshots_relationship_id", table_name="copy_performance_snapshots")
    op.drop_table("copy_performance_snapshots")

    op.drop_index("ix_copied_trades_market_id", table_name="copied_trades")
    op.drop_index("ix_copied_trades_follower_trade_id", table_name="copied_trades")
    op.drop_index("ix_copied_trades_source_trade_id", table_name="copied_trades")
    op.drop_index("ix_copied_trades_relationship_id", table_name="copied_trades")
    op.drop_table("copied_trades")

    op.drop_index("ix_copy_allocation_rules_market_id", table_name="copy_allocation_rules")
    op.drop_index("ix_copy_allocation_rules_relationship_id", table_name="copy_allocation_rules")
    op.drop_table("copy_allocation_rules")

    op.drop_index("ix_copy_relationships_source_user_id", table_name="copy_relationships")
    op.drop_index("ix_copy_relationships_follower_user_id", table_name="copy_relationships")
    op.drop_table("copy_relationships")

    op.drop_index("ix_vault_performance_snapshots_timestamp", table_name="vault_performance_snapshots")
    op.drop_index("ix_vault_performance_snapshots_vault_id", table_name="vault_performance_snapshots")
    op.drop_table("vault_performance_snapshots")

    op.drop_index("ix_vault_trades_market_id", table_name="vault_trades")
    op.drop_index("ix_vault_trades_vault_id", table_name="vault_trades")
    op.drop_table("vault_trades")

    op.drop_index("ix_vault_subscriptions_wallet_address", table_name="vault_subscriptions")
    op.drop_index("ix_vault_subscriptions_user_id", table_name="vault_subscriptions")
    op.drop_index("ix_vault_subscriptions_vault_id", table_name="vault_subscriptions")
    op.drop_table("vault_subscriptions")

    op.drop_index("ix_vault_markets_market_id", table_name="vault_markets")
    op.drop_index("ix_vault_markets_vault_id", table_name="vault_markets")
    op.drop_table("vault_markets")

    op.drop_index("ix_strategy_vaults_manager_user_id", table_name="strategy_vaults")
    op.drop_index("ix_strategy_vaults_status", table_name="strategy_vaults")
    op.drop_index("ix_strategy_vaults_slug", table_name="strategy_vaults")
    op.drop_index("ix_strategy_vaults_title", table_name="strategy_vaults")
    op.drop_table("strategy_vaults")
