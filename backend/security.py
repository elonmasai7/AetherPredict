from __future__ import annotations

import base64
import hashlib
import json
from typing import Any

from cryptography.fernet import Fernet, InvalidToken
from passlib.context import CryptContext

from database import settings


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _fallback_fernet_key() -> bytes:
    digest = hashlib.sha256(settings.jwt_secret.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(digest)


fernet = Fernet(settings.fernet_key.encode("utf-8") if settings.fernet_key else _fallback_fernet_key())


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return pwd_context.verify(password, password_hash)


def hash_api_key(*parts: str) -> str:
    joined = "|".join(parts)
    return hashlib.sha256(joined.encode("utf-8")).hexdigest()


def encrypt_json(payload: dict[str, Any]) -> str:
    return fernet.encrypt(json.dumps(payload).encode("utf-8")).decode("utf-8")


def decrypt_json(payload: str | None) -> dict[str, Any]:
    if not payload:
        return {}
    try:
        decrypted = fernet.decrypt(payload.encode("utf-8")).decode("utf-8")
        return json.loads(decrypted)
    except (InvalidToken, json.JSONDecodeError):
        return {}
