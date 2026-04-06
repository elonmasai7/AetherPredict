from datetime import datetime

from pydantic import BaseModel


class WatchlistItemRequest(BaseModel):
    market_id: int


class WatchlistResponse(BaseModel):
    id: int
    name: str
    market_ids: list[int]
    created_at: datetime
    updated_at: datetime
