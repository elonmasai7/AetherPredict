from fastapi import APIRouter

from app.core.config import settings
from app.schemas.common import MessageResponse
from app.schemas.notification import NotificationResponse
from app.services.platform_data import sample_notifications

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/register-device", response_model=MessageResponse)
def register_device(payload: dict) -> MessageResponse:
    token = payload.get("device_token", "unknown")
    return MessageResponse(message=f"Device token registered: {token}")


@router.get("/history", response_model=list[NotificationResponse])
def history() -> list[NotificationResponse]:
    return [
        NotificationResponse(level=item["level"], message=f"{item['message']} [{item['category']}]")
        for item in sample_notifications()
    ]


@router.get("", response_model=list[NotificationResponse])
def list_notifications() -> list[NotificationResponse]:
    items = sample_notifications()
    items.append({"level": "info", "category": "chain", "message": f"Connected to HashKey chain id {settings.hashkey_chain_id}"})
    return [NotificationResponse(level=item["level"], message=f"{item['message']}") for item in items]
