from __future__ import annotations

import secrets
from typing import Annotated

from fastapi import Depends, Header, HTTPException
from passlib.exc import UnknownHashError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import RefreshToken, User
from app.services.security import (
    create_access_token,
    create_refresh_token,
    get_subject_from_token,
    hash_password,
    hash_token,
    is_legacy_bcrypt_hash,
    verify_password,
)
from web3 import Web3
from eth_account.messages import encode_defunct


def parse_bearer_token(authorization: str | None) -> str:
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing authorization header")
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    return token


def get_current_user(
    db: Session = Depends(get_db),
    authorization: Annotated[str | None, Header(alias="Authorization")] = None,
) -> User:
    token = parse_bearer_token(authorization)
    try:
        subject = get_subject_from_token(token, expected_type="access")
    except ValueError as error:
        raise HTTPException(status_code=401, detail=str(error)) from error

    user = db.scalar(select(User).where(User.email == subject))
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user


def get_optional_user(
    db: Session = Depends(get_db),
    authorization: Annotated[str | None, Header(alias="Authorization")] = None,
) -> User | None:
    if not authorization:
        return None
    try:
        token = parse_bearer_token(authorization)
        subject = get_subject_from_token(token, expected_type="access")
    except Exception:
        return None
    return db.scalar(select(User).where(User.email == subject))


def authenticate_user(db: Session, email: str, password: str) -> User | None:
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        return None

    try:
        password_valid = verify_password(password, user.password_hash)
    except (UnknownHashError, ValueError, TypeError):
        return None

    if not password_valid:
        return None

    if is_legacy_bcrypt_hash(user.password_hash):
        # Upgrade legacy bcrypt hashes to pbkdf2 on successful login.
        user.password_hash = hash_password(password)
        db.commit()

    return user


def create_user(db: Session, email: str, password: str, display_name: str | None = None) -> User:
    existing = db.scalar(select(User).where(User.email == email))
    if existing is not None:
        raise HTTPException(status_code=409, detail="Email already registered")
    user = User(
        email=email,
        password_hash=hash_password(password),
        display_name=display_name,
        notification_preferences={"email": True, "push": True, "in_app": True},
        account_preferences={"theme": "system", "locale": "en-US"},
        workspace_preferences={},
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def issue_tokens(db: Session, user: User) -> tuple[str, str]:
    access = create_access_token(user.email)
    refresh, expires_at = create_refresh_token(user.email)
    db.add(RefreshToken(user_id=user.id, token_hash=hash_token(refresh), expires_at=expires_at))
    db.commit()
    return access, refresh


def rotate_refresh_token(db: Session, refresh_token: str) -> tuple[str, str]:
    try:
        subject = get_subject_from_token(refresh_token, expected_type="refresh")
    except ValueError as error:
        raise HTTPException(status_code=401, detail=str(error)) from error

    token_row = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == hash_token(refresh_token)))
    if token_row is None or token_row.revoked_at is not None:
        raise HTTPException(status_code=401, detail="Refresh token revoked")

    user = db.scalar(select(User).where(User.email == subject))
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")

    token_row.revoked_at = token_row.expires_at
    access, refresh = issue_tokens(db, user)
    db.commit()
    return access, refresh


def ensure_wallet_nonce(db: Session, wallet_address: str) -> str:
    user = db.scalar(select(User).where(User.wallet_address == wallet_address))
    if user is None:
        user = User(
            email=f"{wallet_address.lower()}@wallet.local",
            password_hash=hash_password(secrets.token_urlsafe(24)),
            wallet_address=wallet_address,
            wallet_nonce=secrets.token_hex(16),
            display_name=wallet_address[:10],
            notification_preferences={"email": False, "push": True, "in_app": True},
            account_preferences={"login": "wallet"},
            workspace_preferences={},
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    elif not user.wallet_nonce:
        user.wallet_nonce = secrets.token_hex(16)
        db.commit()
    return user.wallet_nonce or ""


def get_or_create_wallet_user(db: Session, wallet_address: str) -> User:
    user = db.scalar(select(User).where(User.wallet_address == wallet_address))
    if user is None:
        user = User(
            email=f"{wallet_address.lower()}@wallet.local",
            password_hash=hash_password(secrets.token_urlsafe(24)),
            wallet_address=wallet_address,
            wallet_nonce=secrets.token_hex(16),
            display_name=wallet_address[:10],
            notification_preferences={"email": False, "push": True, "in_app": True},
            account_preferences={"login": "wallet"},
            workspace_preferences={},
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


def verify_wallet_signature(wallet_address: str, nonce: str, signature: str) -> bool:
    message = encode_defunct(text=f"AetherPredict login nonce: {nonce}")
    try:
        recovered = Web3().eth.account.recover_message(message, signature=signature)
    except Exception:
        return False
    return recovered.lower() == wallet_address.lower()
