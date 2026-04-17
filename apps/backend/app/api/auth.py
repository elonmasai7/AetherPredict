from fastapi import APIRouter, Depends, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import User
from app.schemas.auth import (
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
    WalletChallengeRequest,
    WalletLoginRequest,
)
from app.services.auth_service import (
    authenticate_user,
    create_user,
    ensure_wallet_nonce,
    get_current_user,
    issue_tokens,
    rotate_refresh_token,
    verify_wallet_signature,
)
from app.services.rate_limit import (
    clear_auth_failures,
    enforce_auth_abuse_guard,
    enforce_rate_limit,
    record_auth_failure,
    request_client_ip,
)
from app.core.config import settings

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register", response_model=TokenResponse)
async def register(payload: RegisterRequest, request: Request, db: Session = Depends(get_db)) -> TokenResponse:
    await enforce_rate_limit(
        "auth-register",
        f"{request_client_ip(request)}:{payload.email.lower()}",
        settings.auth_rate_limit_per_minute,
        60,
    )
    user = create_user(db, payload.email, payload.password, payload.display_name)
    access, refresh = issue_tokens(db, user)
    return TokenResponse(access_token=access, refresh_token=refresh)


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)) -> TokenResponse:
    await enforce_rate_limit(
        "auth-login",
        f"{request_client_ip(request)}:{payload.email.lower()}",
        settings.auth_rate_limit_per_minute,
        60,
    )
    await enforce_auth_abuse_guard(payload.email, request)
    user = authenticate_user(db, payload.email, payload.password)
    if user is None:
        from fastapi import HTTPException

        await record_auth_failure(payload.email, request)
        raise HTTPException(status_code=401, detail="Invalid credentials")
    await clear_auth_failures(payload.email, request)
    access, refresh = issue_tokens(db, user)
    return TokenResponse(access_token=access, refresh_token=refresh)


@router.post("/wallet/challenge")
async def wallet_challenge(payload: WalletChallengeRequest, request: Request, db: Session = Depends(get_db)) -> dict:
    await enforce_rate_limit(
        "auth-wallet-challenge",
        f"{request_client_ip(request)}:{payload.wallet_address.lower()}",
        settings.auth_rate_limit_per_minute,
        60,
    )
    nonce = ensure_wallet_nonce(db, payload.wallet_address)
    return {"wallet_address": payload.wallet_address, "nonce": nonce}


@router.post("/wallet", response_model=TokenResponse)
async def wallet_login(payload: WalletLoginRequest, request: Request, db: Session = Depends(get_db)) -> TokenResponse:
    await enforce_rate_limit(
        "auth-wallet-login",
        f"{request_client_ip(request)}:{payload.wallet_address.lower()}",
        settings.auth_rate_limit_per_minute,
        60,
    )
    nonce = ensure_wallet_nonce(db, payload.wallet_address)
    if payload.nonce != nonce or not payload.signature:
        from fastapi import HTTPException

        raise HTTPException(status_code=401, detail="Invalid wallet challenge response")
    if not verify_wallet_signature(payload.wallet_address, nonce, payload.signature):
        from fastapi import HTTPException

        raise HTTPException(status_code=401, detail="Invalid wallet signature")
    user = db.scalar(select(User).where(User.wallet_address == payload.wallet_address))
    if user is None:
        from fastapi import HTTPException

        raise HTTPException(status_code=404, detail="Wallet user not found")
    access, refresh = issue_tokens(db, user)
    return TokenResponse(access_token=access, refresh_token=refresh)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(payload: RefreshRequest, request: Request, db: Session = Depends(get_db)) -> TokenResponse:
    await enforce_rate_limit(
        "auth-refresh",
        request_client_ip(request),
        settings.auth_rate_limit_per_minute,
        60,
    )
    access, refresh_token = rotate_refresh_token(db, payload.refresh_token)
    return TokenResponse(access_token=access, refresh_token=refresh_token)


@router.get("/me", response_model=UserResponse)
def me(user=Depends(get_current_user)) -> UserResponse:
    return UserResponse(
        id=user.id,
        email=user.email,
        wallet_address=user.wallet_address,
        display_name=user.display_name,
        role=user.role,
        notification_preferences=user.notification_preferences,
        account_preferences=user.account_preferences,
        workspace_preferences=user.workspace_preferences,
    )
