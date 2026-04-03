import httpx
from fastapi import APIRouter

from app.core.config import settings
from app.schemas.ai import AIResolutionRequest, AIResolutionResponse
from app.schemas.copilot import CopilotRecommendationRequest, CopilotRecommendationResponse

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/resolve", response_model=AIResolutionResponse)
async def resolve(payload: AIResolutionRequest) -> AIResolutionResponse:
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(f"{settings.ai_service_url}/resolve", json=payload.model_dump())
        data = response.json()
    return AIResolutionResponse(**data)


@router.post("/copilot/recommendation", response_model=CopilotRecommendationResponse)
async def copilot_recommendation(payload: CopilotRecommendationRequest) -> CopilotRecommendationResponse:
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(f"{settings.ai_service_url}/copilot/recommendation", json=payload.model_dump())
        data = response.json()
    return CopilotRecommendationResponse(**data)


@router.post("/market/sentiment-feed")
async def sentiment_feed(payload: dict):
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(f"{settings.ai_service_url}/market/sentiment-feed", json=payload)
        return response.json()
