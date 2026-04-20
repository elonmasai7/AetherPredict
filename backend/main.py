from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi_jwt_auth import AuthJWT
from pydantic import BaseModel, EmailStr, Field
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import get_current_user, get_db, init_db, settings
from liquidity import liquidity_snapshot
from models import Market, Position, User
from routers import markets, trade
from security import decrypt_json, encrypt_json, hash_api_key, hash_password, verify_password
from websocket import manager, router as websocket_router


app = FastAPI(title=settings.app_name, version="1.0.0")
limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.rate_limit_per_minute}/minute"])
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(markets.router)
app.include_router(trade.router)
app.include_router(websocket_router)


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)


class LoginRequest(RegisterRequest):
    pass


class ProviderCredentialRequest(BaseModel):
    provider: str = Field(pattern="^(kalshi|alpaca)$")
    api_key: str | None = None
    api_secret: str | None = None
    private_key_pem: str | None = None
    oauth_token: str | None = None


@app.on_event("startup")
async def on_startup() -> None:
    init_db()
    asyncio.create_task(market_tick_loop())


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/auth/register")
@limiter.limit("10/minute")
def register(request: Request, payload: RegisterRequest, db: Session = Depends(get_db)) -> dict[str, Any]:
    if db.scalar(select(User).where(User.email == payload.email)):
        raise HTTPException(status_code=409, detail="User already exists")
    user = User(email=payload.email, password_hash=hash_password(payload.password), balance=1000)
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"user_id": user.id, "email": user.email}


@app.post("/auth/login")
@limiter.limit("20/minute")
def login(request: Request, payload: LoginRequest, db: Session = Depends(get_db), authorize: AuthJWT = Depends()) -> dict[str, str]:
    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = authorize.create_access_token(subject=str(user.id))
    return {"access_token": token, "token_type": "bearer"}


@app.post("/auth/provider-credentials")
def store_provider_credentials(
    payload: ProviderCredentialRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict[str, str]:
    provider_payload = payload.model_dump(exclude_none=True)
    user.encrypted_api_credentials = encrypt_json(provider_payload)
    user.api_key_hash = hash_api_key(payload.provider, payload.api_key or "", payload.oauth_token or "")
    user.preferred_provider = payload.provider
    db.commit()
    return {"status": "saved", "provider": payload.provider}


@app.get("/auth/provider-credentials")
def get_provider_credentials(user: User = Depends(get_current_user)) -> dict[str, Any]:
    creds = decrypt_json(user.encrypted_api_credentials)
    redacted = {
        "provider": creds.get("provider"),
        "api_key": f"...{creds.get('api_key', '')[-4:]}" if creds.get("api_key") else None,
        "has_private_key": bool(creds.get("private_key_pem")),
        "has_api_secret": bool(creds.get("api_secret")),
        "has_oauth_token": bool(creds.get("oauth_token")),
    }
    return redacted


@app.get("/portfolio/dashboard")
def dashboard(db: Session = Depends(get_db), user: User = Depends(get_current_user)) -> dict[str, Any]:
    positions = list(db.scalars(select(Position).where(Position.user_id == user.id)))
    payload = []
    total_pnl = 0.0
    for position in positions:
        market = db.get(Market, position.market_id)
        if market is None:
            continue
        mark_price = market.yes_price if position.side == "YES" else market.no_price
        pnl = round((mark_price - position.avg_price) * position.shares * 100, 2)
        total_pnl += pnl
        payload.append(
            {
                "position_id": position.id,
                "market_id": market.id,
                "title": market.title,
                "side": position.side,
                "shares": position.shares,
                "avg_price": position.avg_price,
                "mark_price": mark_price,
                "pnl": pnl,
                "spread_cents": market.spread_cents,
                "volume": market.total_volume,
            }
        )
    return {
        "cash_balance": float(user.balance),
        "total_pnl": round(total_pnl, 2),
        "positions": payload,
    }


@app.get("/portfolio/me")
def me(user: User = Depends(get_current_user)) -> dict[str, Any]:
    return {
        "id": user.id,
        "email": user.email,
        "balance": float(user.balance),
        "preferred_provider": user.preferred_provider,
    }


async def market_tick_loop() -> None:
    from routers.markets import push_market_snapshot, sync_market_quote

    while True:
        db = next(get_db())
        try:
            markets_rows = list(db.scalars(select(Market).where(Market.archived.is_(False))))
            for market in markets_rows:
                snapshot = sync_market_quote(db, market)
                await push_market_snapshot(market.id, snapshot)
                await manager.broadcast(
                    market.id,
                    {
                        **snapshot,
                        "event": market.event,
                        "title": market.title,
                        "ts": datetime.now(timezone.utc).isoformat(),
                    },
                )
        finally:
            db.close()
        await asyncio.sleep(1)


@app.exception_handler(Exception)
async def catch_all(_: Request, exc: Exception):
    return JSONResponse(status_code=500, content={"detail": str(exc)})
