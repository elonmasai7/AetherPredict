from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import DeviceToken, Notification
from app.schemas.common import MessageResponse
from app.schemas.notification import NotificationResponse
from app.services.auth_service import get_current_user, get_optional_user

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/register-device", response_model=MessageResponse)
def register_device(payload: dict, db: Session = Depends(get_db), user=Depends(get_current_user)) -> MessageResponse:
    token = str(payload.get("device_token", "")).strip()
    platform = str(payload.get("platform", "unknown")).strip() or "unknown"
    if not token:
        return MessageResponse(message="Device token missing")
    existing = db.scalar(
        select(DeviceToken).where(DeviceToken.user_id == user.id, DeviceToken.token == token)
    )
    if existing is None:
        db.add(DeviceToken(user_id=user.id, token=token, platform=platform))
        db.commit()
    return MessageResponse(message=f"Device token registered for {platform}")


@router.get("/history", response_model=list[NotificationResponse])
def history(db: Session = Depends(get_db), user=Depends(get_optional_user)) -> list[NotificationResponse]:
    stmt = select(Notification).where(Notification.user_id.is_(None)).order_by(Notification.created_at.desc())
    if user is not None:
        stmt = select(Notification).where((Notification.user_id == user.id) | (Notification.user_id.is_(None))).order_by(Notification.created_at.desc())
    notifications = db.scalars(stmt).all()
    return [NotificationResponse.model_validate(item, from_attributes=True) for item in notifications]


@router.get("", response_model=list[NotificationResponse])
def list_notifications(db: Session = Depends(get_db), user=Depends(get_optional_user)) -> list[NotificationResponse]:
    return history(db=db, user=user)
