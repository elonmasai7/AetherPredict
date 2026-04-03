from fastapi import APIRouter

from app.schemas.leaderboard import LeaderboardEntry
from app.services.platform_data import sample_leaderboard

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])


@router.get("/traders", response_model=list[LeaderboardEntry])
def traders() -> list[LeaderboardEntry]:
    return [LeaderboardEntry(**item) for item in sample_leaderboard("traders")]


@router.get("/agents", response_model=list[LeaderboardEntry])
def agents() -> list[LeaderboardEntry]:
    return [LeaderboardEntry(**item) for item in sample_leaderboard("agents")]


@router.get("/jurors", response_model=list[LeaderboardEntry])
def jurors() -> list[LeaderboardEntry]:
    return [LeaderboardEntry(**item) for item in sample_leaderboard("jurors")]
