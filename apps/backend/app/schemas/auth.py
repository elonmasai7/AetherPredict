from pydantic import BaseModel


class LoginRequest(BaseModel):
    email: str
    password: str


class WalletLoginRequest(BaseModel):
    wallet_address: str
    signature: str
    nonce: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
