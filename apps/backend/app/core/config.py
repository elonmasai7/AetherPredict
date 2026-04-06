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
    hashkey_chain_id: int = 133
    hashkey_private_key: str = ""
    treasury_address: str = ""
    hashkey_explorer_url: str = "https://explorer.hashkeychain.example"
    websocket_channel: str = "aetherpredict:market_updates"
    walletconnect_project_id: str = ""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
