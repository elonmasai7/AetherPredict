from pydantic import BaseModel


class LeaderboardEntry(BaseModel):
    rank: int
    name: str
    score: float
    roi: float
    win_rate: float
    period: str
