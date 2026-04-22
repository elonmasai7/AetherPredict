from datetime import UTC, datetime

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.api.leaderboard import default_leaderboard
from app.schemas.nba import PlatformHomeResponse, StrategyPreviewRequest, StrategyPreviewResponse
from app.services.agent_engine import AgentEngine
from app.services.market_service import MarketService
from app.services.news_service import NewsService
from app.services.prediction_engine import PredictionEngine
from app.services.redis_bus import get_cached_json, set_cached_json
from app.core.config import settings

router = APIRouter(prefix="/platform", tags=["platform"])


@router.get("/home", response_model=PlatformHomeResponse)
def platform_home(db: Session = Depends(get_db)) -> PlatformHomeResponse:
    cache_key = "platform:home:v2"
    cached = get_cached_json(cache_key)
    if cached is not None:
        return PlatformHomeResponse.model_validate(cached)

    market_service = MarketService(db)
    markets = market_service.enriched_markets()
    news = NewsService().latest_news()
    agents = AgentEngine().build_agents(markets, news)
    leaderboard_rows = default_leaderboard(db)
    games = market_service.live_games()
    response = PlatformHomeResponse(
        generated_at=datetime.now(UTC),
        overview=market_service.overview(markets=markets, games=games),
        featured_market_id=markets[0]["id"] if markets else None,
        live_games=games,
        markets=markets,
        news=news,
        agents=agents,
        leaderboard=[
            {
                "rank": row.rank,
                "name": row.name,
                "accuracy": row.lifetime_accuracy or row.win_rate,
                "roi": row.roi,
                "consistency": row.win_rate,
                "predictions": max(int(row.score), 0),
                "streak": 0,
            }
            for row in leaderboard_rows[:10]
        ],
        activity_feed=market_service.activity_feed(),
        recent_predictions=market_service.recent_predictions(),
    )
    set_cached_json(
        cache_key,
        response.model_dump(mode="json"),
        ttl_seconds=max(3, min(settings.live_cache_ttl_seconds, 10)),
    )
    return response


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
