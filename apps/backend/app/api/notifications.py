from fastapi import APIRouter

from app.core.config import settings
from app.schemas.notification import NotificationResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=list[NotificationResponse])
def list_notifications() -> list[NotificationResponse]:
    return [
        NotificationResponse(level="info", message="BTC > $120k probability moved from 68% to 74%"),
        NotificationResponse(level="warning", message="Sentinel agent detected whale activity"),
        NotificationResponse(level="info", message=f"Connected to HashKey chain id {settings.hashkey_chain_id}"),
    ]
