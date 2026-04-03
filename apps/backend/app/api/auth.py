from fastapi import APIRouter

from app.schemas.auth import LoginRequest, TokenResponse, WalletLoginRequest
from app.services.security import create_access_token

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest) -> TokenResponse:
    return TokenResponse(access_token=create_access_token(payload.email))


@router.post("/wallet", response_model=TokenResponse)
def wallet_login(payload: WalletLoginRequest) -> TokenResponse:
    return TokenResponse(access_token=create_access_token(payload.wallet_address))
