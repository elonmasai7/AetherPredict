from datetime import datetime

from pydantic import BaseModel


class WorkspaceRequest(BaseModel):
    name: str
    layout_json: dict = {}
    notes_json: dict = {}
    chart_preferences: dict = {}


class WorkspaceResponse(BaseModel):
    id: int
    name: str
    layout_json: dict
    notes_json: dict
    chart_preferences: dict
    created_at: datetime
    updated_at: datetime
