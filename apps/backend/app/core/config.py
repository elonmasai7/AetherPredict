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
    ai_service_url: str = "http://localhost:8010"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
