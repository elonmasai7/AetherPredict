from fastapi import APIRouter

from app.schemas.nba import NbaNewsItemResponse
from app.services.news_service import NewsService

router = APIRouter(prefix="/news", tags=["news"])


@router.get("", response_model=list[NbaNewsItemResponse])
def list_news() -> list[NbaNewsItemResponse]:
    return [NbaNewsItemResponse(**item) for item in NewsService().latest_news()]
