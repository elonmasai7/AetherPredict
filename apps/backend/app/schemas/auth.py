from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class WalletLoginRequest(BaseModel):
    wallet_address: str
    signature: str
    nonce: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
