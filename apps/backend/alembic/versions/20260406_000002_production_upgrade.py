"""production upgrade schema"""

from alembic import op
import sqlalchemy as sa


revision = "20260406_000002"
down_revision = "20260403_000001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("display_name", sa.String(length=120), nullable=True))
    op.add_column("users", sa.Column("notification_preferences", sa.JSON(), nullable=False, server_default="{}"))
    op.add_column("users", sa.Column("account_preferences", sa.JSON(), nullable=False, server_default="{}"))
    op.add_column("users", sa.Column("workspace_preferences", sa.JSON(), nullable=False, server_default="{}"))
    op.create_index("ix_users_wallet_address", "users", ["wallet_address"], unique=False)

    op.add_column("markets", sa.Column("resolution_rules", sa.Text(), nullable=True))
    op.add_column("markets", sa.Column("collateral_token", sa.String(length=64), nullable=True))
    op.add_column("markets", sa.Column("on_chain_address", sa.String(length=120), nullable=True))
    op.add_column("markets", sa.Column("creator_user_id", sa.Integer(), nullable=True))
    op.add_column("markets", sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"))
    op.add_column("markets", sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")))
    op.add_column("markets", sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")))
    op.create_foreign_key("fk_markets_creator_user_id_users", "markets", "users", ["creator_user_id"], ["id"])

    op.add_column("portfolio_positions", sa.Column("realized_pnl", sa.Float(), nullable=False, server_default="0"))
    op.add_column("portfolio_positions", sa.Column("unrealized_pnl", sa.Float(), nullable=False, server_default="0"))
    op.add_column("portfolio_positions", sa.Column("status", sa.String(length=30), nullable=False, server_default="OPEN"))
    op.add_column("portfolio_positions", sa.Column("opened_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")))
    op.add_column("portfolio_positions", sa.Column("closed_at", sa.DateTime(), nullable=True))
    op.create_index("ix_portfolio_positions_user_id", "portfolio_positions", ["user_id"], unique=False)
    op.create_index("ix_portfolio_positions_market_id", "portfolio_positions", ["market_id"], unique=False)

    op.add_column("agent_statuses", sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")))

    op.add_column("disputes", sa.Column("user_id", sa.Integer(), nullable=True))
    op.add_column("disputes", sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")))
    op.create_index("ix_disputes_market_id", "disputes", ["market_id"], unique=False)
    op.create_foreign_key("fk_disputes_user_id_users", "disputes", "users", ["user_id"], ["id"])

    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("token_hash", sa.String(length=255), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("revoked_at", sa.DateTime(), nullable=True),
    )
    op.create_index("ix_refresh_tokens_user_id", "refresh_tokens", ["user_id"], unique=False)
    op.create_index("ix_refresh_tokens_token_hash", "refresh_tokens", ["token_hash"], unique=True)

    op.create_table(
        "trade_orders",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=False),
        sa.Column("side", sa.String(length=10), nullable=False),
        sa.Column("order_type", sa.String(length=20), nullable=False),
        sa.Column("collateral_amount", sa.Float(), nullable=False),
        sa.Column("price", sa.Float(), nullable=False),
        sa.Column("shares", sa.Float(), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False),
        sa.Column("wallet_address", sa.String(length=120), nullable=True),
        sa.Column("signed_payload", sa.Text(), nullable=True),
        sa.Column("tx_hash", sa.String(length=255), nullable=True),
        sa.Column("explorer_url", sa.String(length=255), nullable=True),
        sa.Column("gas_estimate", sa.Float(), nullable=True),
        sa.Column("gas_fee_native", sa.Float(), nullable=True),
        sa.Column("failure_reason", sa.Text(), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_trade_orders_user_id", "trade_orders", ["user_id"], unique=False)
    op.create_index("ix_trade_orders_market_id", "trade_orders", ["market_id"], unique=False)

    op.create_table(
        "transaction_records",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("trade_id", sa.Integer(), sa.ForeignKey("trade_orders.id"), nullable=True),
        sa.Column("transaction_type", sa.String(length=40), nullable=False),
        sa.Column("asset_symbol", sa.String(length=20), nullable=False),
        sa.Column("amount", sa.Float(), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False),
        sa.Column("tx_hash", sa.String(length=255), nullable=True),
        sa.Column("explorer_url", sa.String(length=255), nullable=True),
        sa.Column("gas_fee_native", sa.Float(), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_transaction_records_user_id", "transaction_records", ["user_id"], unique=False)
    op.create_index("ix_transaction_records_trade_id", "transaction_records", ["trade_id"], unique=False)

    op.create_table(
        "discussion_comments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=False),
        sa.Column("author", sa.String(length=120), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("evidence_url", sa.String(length=255), nullable=True),
        sa.Column("parent_id", sa.Integer(), sa.ForeignKey("discussion_comments.id"), nullable=True),
        sa.Column("upvotes", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_discussion_comments_market_id", "discussion_comments", ["market_id"], unique=False)

    op.create_table(
        "notifications",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("level", sa.String(length=30), nullable=False),
        sa.Column("category", sa.String(length=50), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("read", sa.Boolean(), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_notifications_user_id", "notifications", ["user_id"], unique=False)

    op.create_table(
        "device_tokens",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("token", sa.String(length=255), nullable=False),
        sa.Column("platform", sa.String(length=30), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("user_id", "token", name="uq_device_tokens_user_token"),
    )
    op.create_index("ix_device_tokens_user_id", "device_tokens", ["user_id"], unique=False)

    op.create_table(
        "watchlists",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_watchlists_user_id", "watchlists", ["user_id"], unique=False)

    op.create_table(
        "watchlist_items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("watchlist_id", sa.Integer(), sa.ForeignKey("watchlists.id"), nullable=False),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("watchlist_id", "market_id", name="uq_watchlist_market"),
    )
    op.create_index("ix_watchlist_items_watchlist_id", "watchlist_items", ["watchlist_id"], unique=False)
    op.create_index("ix_watchlist_items_market_id", "watchlist_items", ["market_id"], unique=False)

    op.create_table(
        "workspaces",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("layout_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("notes_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("chart_preferences", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_workspaces_user_id", "workspaces", ["user_id"], unique=False)

    op.create_table(
        "notes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=True),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_notes_user_id", "notes", ["user_id"], unique=False)
    op.create_index("ix_notes_market_id", "notes", ["market_id"], unique=False)

    op.create_table(
        "ai_signals",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("market_id", sa.Integer(), sa.ForeignKey("markets.id"), nullable=True),
        sa.Column("signal_type", sa.String(length=50), nullable=False),
        sa.Column("action", sa.String(length=50), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("risk", sa.String(length=30), nullable=False),
        sa.Column("reasoning", sa.Text(), nullable=False),
        sa.Column("payload_json", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_ai_signals_user_id", "ai_signals", ["user_id"], unique=False)
    op.create_index("ix_ai_signals_market_id", "ai_signals", ["market_id"], unique=False)

    op.create_table(
        "wallet_balances",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("wallet_address", sa.String(length=120), nullable=False),
        sa.Column("network", sa.String(length=40), nullable=False),
        sa.Column("symbol", sa.String(length=20), nullable=False),
        sa.Column("balance", sa.Float(), nullable=False),
        sa.Column("price_usd", sa.Float(), nullable=False),
        sa.Column("value_usd", sa.Float(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("user_id", "wallet_address", "network", "symbol", name="uq_wallet_balance"),
    )
    op.create_index("ix_wallet_balances_user_id", "wallet_balances", ["user_id"], unique=False)
    op.create_index("ix_wallet_balances_wallet_address", "wallet_balances", ["wallet_address"], unique=False)

    op.create_table(
        "asset_snapshots",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("symbol", sa.String(length=20), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("price_usd", sa.Float(), nullable=False),
        sa.Column("change_24h", sa.Float(), nullable=False),
        sa.Column("volume_24h", sa.Float(), nullable=False),
        sa.Column("market_cap", sa.Float(), nullable=False),
        sa.Column("high_24h", sa.Float(), nullable=False),
        sa.Column("low_24h", sa.Float(), nullable=False),
        sa.Column("volatility_pct", sa.Float(), nullable=False),
        sa.Column("order_flow_score", sa.Float(), nullable=False),
        sa.Column("source", sa.String(length=80), nullable=False),
        sa.Column("recorded_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("symbol", name="uq_asset_snapshot_symbol"),
    )
    op.create_index("ix_asset_snapshots_symbol", "asset_snapshots", ["symbol"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_asset_snapshots_symbol", table_name="asset_snapshots")
    op.drop_table("asset_snapshots")
    op.drop_index("ix_wallet_balances_wallet_address", table_name="wallet_balances")
    op.drop_index("ix_wallet_balances_user_id", table_name="wallet_balances")
    op.drop_table("wallet_balances")
    op.drop_index("ix_ai_signals_market_id", table_name="ai_signals")
    op.drop_index("ix_ai_signals_user_id", table_name="ai_signals")
    op.drop_table("ai_signals")
    op.drop_index("ix_notes_market_id", table_name="notes")
    op.drop_index("ix_notes_user_id", table_name="notes")
    op.drop_table("notes")
    op.drop_index("ix_workspaces_user_id", table_name="workspaces")
    op.drop_table("workspaces")
    op.drop_index("ix_watchlist_items_market_id", table_name="watchlist_items")
    op.drop_index("ix_watchlist_items_watchlist_id", table_name="watchlist_items")
    op.drop_table("watchlist_items")
    op.drop_index("ix_watchlists_user_id", table_name="watchlists")
    op.drop_table("watchlists")
    op.drop_index("ix_device_tokens_user_id", table_name="device_tokens")
    op.drop_table("device_tokens")
    op.drop_index("ix_notifications_user_id", table_name="notifications")
    op.drop_table("notifications")
    op.drop_index("ix_discussion_comments_market_id", table_name="discussion_comments")
    op.drop_table("discussion_comments")
    op.drop_index("ix_transaction_records_trade_id", table_name="transaction_records")
    op.drop_index("ix_transaction_records_user_id", table_name="transaction_records")
    op.drop_table("transaction_records")
    op.drop_index("ix_trade_orders_market_id", table_name="trade_orders")
    op.drop_index("ix_trade_orders_user_id", table_name="trade_orders")
    op.drop_table("trade_orders")
    op.drop_index("ix_refresh_tokens_token_hash", table_name="refresh_tokens")
    op.drop_index("ix_refresh_tokens_user_id", table_name="refresh_tokens")
    op.drop_table("refresh_tokens")
    op.drop_constraint("fk_disputes_user_id_users", "disputes", type_="foreignkey")
    op.drop_index("ix_disputes_market_id", table_name="disputes")
    op.drop_column("disputes", "created_at")
    op.drop_column("disputes", "user_id")
    op.drop_column("agent_statuses", "updated_at")
    op.drop_index("ix_portfolio_positions_market_id", table_name="portfolio_positions")
    op.drop_index("ix_portfolio_positions_user_id", table_name="portfolio_positions")
    op.drop_column("portfolio_positions", "closed_at")
    op.drop_column("portfolio_positions", "opened_at")
    op.drop_column("portfolio_positions", "status")
    op.drop_column("portfolio_positions", "unrealized_pnl")
    op.drop_column("portfolio_positions", "realized_pnl")
    op.drop_constraint("fk_markets_creator_user_id_users", "markets", type_="foreignkey")
    op.drop_column("markets", "updated_at")
    op.drop_column("markets", "created_at")
    op.drop_column("markets", "metadata_json")
    op.drop_column("markets", "creator_user_id")
    op.drop_column("markets", "on_chain_address")
    op.drop_column("markets", "collateral_token")
    op.drop_column("markets", "resolution_rules")
    op.drop_index("ix_users_wallet_address", table_name="users")
    op.drop_column("users", "workspace_preferences")
    op.drop_column("users", "account_preferences")
    op.drop_column("users", "notification_preferences")
    op.drop_column("users", "display_name")
