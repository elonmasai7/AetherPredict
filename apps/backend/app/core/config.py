from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "AetherPredict API"
    app_env: str = "development"
    backend_host: str = "0.0.0.0"
    backend_port: int = 8000
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/aetherpredict"
    redis_url: str = "redis://localhost:6379/0"
    jwt_secret: str = "change-me"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60
    jwt_refresh_expire_days: int = 14
    ai_service_url: str = "http://localhost:8010"
    coingecko_api_url: str = "https://api.coingecko.com/api/v3"
    market_poll_interval_seconds: int = 30
    price_alert_threshold_pct: float = 5.0
    hashkey_rpc_url: str = ""
    hashkey_rpc_fallbacks: list[str] = []
    hashkey_chain_id: int = 133
    hashkey_private_key: str = ""
    treasury_address: str = ""
    hashkey_prediction_factory_address: str = ""
    hashkey_factory_address: str = ""
    hashkey_outcome_token_factory_address: str = ""
    hashkey_outcome_factory_address: str = ""
    hashkey_aeth_token_address: str = ""
    hashkey_governance_staking_address: str = ""
    hashkey_liquidity_vault_address: str = ""
    hashkey_vault_factory_address: str = ""
    hashkey_usdc_address: str = ""
    hashkey_usdt_address: str = ""
    tx_websocket_channel: str = "aetherpredict:tx_updates"
    vault_websocket_channel: str = "aetherpredict:vault_updates"
    copy_websocket_channel: str = "aetherpredict:copy_updates"
    hashkey_explorer_url: str = "https://explorer.hashkeychain.example"
    websocket_channel: str = "aetherpredict:market_updates"
    walletconnect_project_id: str = ""
    cors_allowed_origins: list[str] = []
    api_docs_enabled: bool | None = None
    auth_rate_limit_per_minute: int = 20
    auth_abuse_threshold: int = 8
    auth_abuse_window_seconds: int = 900
    strategy_engine_rate_limit_per_minute: int = 60
    strategy_engine_build_limit_per_hour: int = 20
    strategy_engine_refresh_seconds: int = 300
    vault_auto_execute_default_slugs: list[str] = []
    vault_auto_execute_allowlist_ids: list[int] = []
    vault_auto_execute_allowlist_manager_roles: list[str] = []

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @field_validator("hashkey_rpc_fallbacks", mode="before")
    @classmethod
    def _split_fallbacks(cls, value):
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value

    @field_validator(
        "cors_allowed_origins",
        "vault_auto_execute_default_slugs",
        "vault_auto_execute_allowlist_manager_roles",
        mode="before",
    )
    @classmethod
    def _split_csv(cls, value):
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value

    @field_validator("vault_auto_execute_allowlist_ids", mode="before")
    @classmethod
    def _split_csv_int(cls, value):
        if isinstance(value, str):
            return [int(item.strip()) for item in value.split(",") if item.strip()]
        return value

    @property
    def is_production(self) -> bool:
        return self.app_env.lower() == "production"

    @property
    def docs_enabled(self) -> bool:
        if self.api_docs_enabled is None:
            return not self.is_production
        return self.api_docs_enabled

    @property
    def cors_origins(self) -> list[str]:
        if self.cors_allowed_origins:
            return self.cors_allowed_origins
        return ["*"] if not self.is_production else []

    @model_validator(mode="after")
    def _validate_production_defaults(self):
        if self.is_production:
            if self.jwt_secret == "change-me" or len(self.jwt_secret) < 32:
                raise ValueError("Production requires a strong JWT_SECRET with at least 32 characters.")
            if not self.cors_allowed_origins:
                raise ValueError("Production requires CORS_ALLOWED_ORIGINS to be explicitly configured.")
            if "*" in self.cors_allowed_origins:
                raise ValueError("Production cannot use wildcard CORS_ALLOWED_ORIGINS.")
            if self.docs_enabled:
                raise ValueError("Production must disable public API docs unless API_DOCS_ENABLED is explicitly false.")
        return self


settings = Settings()
