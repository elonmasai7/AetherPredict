from pydantic import BaseModel


class NotificationResponse(BaseModel):
    level: str
    message: str
