import httpx
from fastapi import APIRouter

from app.core.config import settings
from app.schemas.ai import AIResolutionRequest, AIResolutionResponse

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/resolve", response_model=AIResolutionResponse)
async def resolve(payload: AIResolutionRequest) -> AIResolutionResponse:
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(f"{settings.ai_service_url}/resolve", json=payload.model_dump())
        data = response.json()
    return AIResolutionResponse(**data)
