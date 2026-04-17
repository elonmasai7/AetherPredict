from __future__ import annotations

import hashlib

from fastapi import HTTPException, Request

from app.core.config import settings
from app.services.redis_bus import redis_client


def _digest(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()[:24]


def request_client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


async def enforce_rate_limit(namespace: str, identifier: str, limit: int, window_seconds: int) -> None:
    key = f"ratelimit:{namespace}:{_digest(identifier)}"
    current = await redis_client.incr(key)
    if current == 1:
        await redis_client.expire(key, window_seconds)
    if current > limit:
        raise HTTPException(status_code=429, detail="Rate limit exceeded")


async def record_auth_failure(email: str, request: Request) -> int:
    identifier = f"{email.lower()}:{request_client_ip(request)}"
    key = f"auth-abuse:{_digest(identifier)}"
    current = await redis_client.incr(key)
    if current == 1:
        await redis_client.expire(key, settings.auth_abuse_window_seconds)
    return int(current)


async def clear_auth_failures(email: str, request: Request) -> None:
    identifier = f"{email.lower()}:{request_client_ip(request)}"
    key = f"auth-abuse:{_digest(identifier)}"
    await redis_client.delete(key)


async def enforce_auth_abuse_guard(email: str, request: Request) -> None:
    identifier = f"{email.lower()}:{request_client_ip(request)}"
    key = f"auth-abuse:{_digest(identifier)}"
    failures = await redis_client.get(key)
    if failures is not None and int(failures) >= settings.auth_abuse_threshold:
        raise HTTPException(status_code=429, detail="Too many failed authentication attempts")
