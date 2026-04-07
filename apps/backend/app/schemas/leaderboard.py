from pydantic import BaseModel


class LeaderboardEntry(BaseModel):
    rank: int
    user_id: int | None = None
    name: str
    score: float
    roi: float
    roi_7d: float = 0
    roi_30d: float = 0
    win_rate: float
    lifetime_accuracy: float = 0
    copied_followers: int = 0
    assets_copied: float = 0
    period: str
