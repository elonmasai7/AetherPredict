from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: str | None = None


class WalletChallengeRequest(BaseModel):
    wallet_address: str


class WalletLoginRequest(BaseModel):
    wallet_address: str
    signature: str
    nonce: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    wallet_address: str | None = None
    display_name: str | None = None
    role: str
    notification_preferences: dict
    account_preferences: dict
    workspace_preferences: dict
