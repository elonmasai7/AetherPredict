from datetime import datetime

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: int
    level: str
    category: str
    message: str
    read: bool
    created_at: datetime
