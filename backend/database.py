from __future__ import annotations

from collections.abc import Generator
from datetime import timedelta

import redis.asyncio as redis
from fastapi import Depends, HTTPException, status
from fastapi_jwt_auth import AuthJWT
from pydantic import BaseModel
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Settings(BaseSettings):
    app_name: str = "PredictOdds Pro API"
    app_env: str = "development"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/predictodds"
    redis_url: str = "redis://localhost:6379/0"
    jwt_secret: str = "replace-me-please-change-this-before-production"
    fernet_key: str = ""
    access_token_minutes: int = 720
    kalshi_base_url: str = "https://api.elections.kalshi.com/trade-api/v2"
    kalshi_demo_base_url: str = "https://demo-api.kalshi.co/trade-api/v2"
    alpaca_trading_url: str = "https://paper-api.alpaca.markets"
    alpaca_market_data_url: str = "https://data.alpaca.markets"
    alpaca_auth_url: str = "https://authx.alpaca.markets/v1/oauth2/token"
    primary_provider: str = "kalshi"
    use_external_markets: bool = True
    default_b_param: float = 1800.0
    default_maker_rebate_bps: int = 10
    mock_mode: bool = True
    rate_limit_per_minute: int = 90

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()


class JwtConfig(BaseModel):
    authjwt_secret_key: str = settings.jwt_secret
    authjwt_access_token_expires: timedelta = timedelta(minutes=settings.access_token_minutes)
    authjwt_token_location: set[str] = {"headers"}


@AuthJWT.load_config
def _jwt_config() -> JwtConfig:
    return JwtConfig()


class Base(DeclarativeBase):
    pass


engine = create_engine(settings.database_url, future=True, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
redis_client = redis.from_url(settings.redis_url, decode_responses=True)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    with engine.begin() as conn:
        for statement in (
            "CREATE EXTENSION IF NOT EXISTS timescaledb",
            "CREATE EXTENSION IF NOT EXISTS pgcrypto",
        ):
            try:
                conn.execute(text(statement))
            except Exception:
                pass
    Base.metadata.create_all(bind=engine)


def get_current_user(
    db: Session = Depends(get_db),
    authorize: AuthJWT = Depends(),
):
    from models import User

    try:
        authorize.jwt_required()
        subject = authorize.get_jwt_subject()
    except Exception as exc:  # pragma: no cover - library exception shape varies
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc

    user = db.get(User, int(subject))
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user
