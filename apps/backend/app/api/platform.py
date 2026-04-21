from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.nba import PlatformHomeResponse, StrategyPreviewRequest, StrategyPreviewResponse
from app.services.agent_engine import AgentEngine
from app.services.market_service import MarketService
from app.services.news_service import NewsService
from app.services.prediction_engine import PredictionEngine

router = APIRouter(prefix="/platform", tags=["platform"])


@router.get("/home", response_model=PlatformHomeResponse)
def platform_home(db: Session = Depends(get_db)) -> PlatformHomeResponse:
    market_service = MarketService(db)
    markets = market_service.enriched_markets()
    news = NewsService().latest_news()
    agents = AgentEngine().build_agents(markets, news)
    leaderboard = [
        {"rank": 1, "name": "Baseline Alpha", "accuracy": 71.4, "roi": 24.8, "consistency": 92.0, "predictions": 138, "streak": 9},
        {"rank": 2, "name": "Paint Pressure", "accuracy": 69.8, "roi": 18.6, "consistency": 88.3, "predictions": 121, "streak": 6},
        {"rank": 3, "name": "Clutch Model", "accuracy": 68.9, "roi": 16.1, "consistency": 85.1, "predictions": 109, "streak": 4},
        {"rank": 4, "name": "Transition Edge", "accuracy": 67.2, "roi": 14.9, "consistency": 83.4, "predictions": 98, "streak": 3},
    ]
    return PlatformHomeResponse(
        generated_at=NewsService().now,
        overview=market_service.overview(),
        featured_market_id=markets[0]["id"] if markets else None,
        live_games=market_service.live_games(),
        markets=markets,
        news=news,
        agents=agents,
        leaderboard=leaderboard,
        activity_feed=market_service.activity_feed(),
        recent_predictions=market_service.recent_predictions(),
    )


@router.post("/strategy/preview", response_model=StrategyPreviewResponse)
def preview_strategy(payload: StrategyPreviewRequest, db: Session = Depends(get_db)) -> StrategyPreviewResponse:
    market_service = MarketService(db)
    markets = market_service.enriched_markets()
    return StrategyPreviewResponse(
        **PredictionEngine().preview_strategy(
            payload.prompt,
            markets,
            payload.risk_level,
            payload.automation_enabled,
            payload.data_sources,
        )
    )
