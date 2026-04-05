import httpx
from fastapi import APIRouter, HTTPException

from app.core.config import settings
from app.schemas.ai import AIResolutionRequest, AIResolutionResponse
from app.schemas.copilot import CopilotRecommendationRequest, CopilotRecommendationResponse

router = APIRouter(prefix="/ai", tags=["ai"])


def _handle_upstream_error(error: Exception, endpoint: str) -> None:
    if isinstance(error, httpx.HTTPStatusError):
        status = error.response.status_code
        detail = error.response.text[:240] if error.response.text else "empty response"
        raise HTTPException(status_code=502, detail=f"AI upstream {endpoint} failed ({status}): {detail}") from error
    if isinstance(error, httpx.RequestError):
        raise HTTPException(status_code=502, detail=f"AI upstream {endpoint} unavailable: {error}") from error
    raise HTTPException(status_code=500, detail=f"Unexpected AI gateway error ({endpoint})") from error


@router.post("/resolve", response_model=AIResolutionResponse)
async def resolve(payload: AIResolutionRequest) -> AIResolutionResponse:
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(f"{settings.ai_service_url}/resolve", json=payload.model_dump())
            response.raise_for_status()
            data = response.json()
    except Exception as error:
        _handle_upstream_error(error, "/resolve")

    evidence = data.get("evidence")
    if evidence is None:
        evidence = data.get("supporting_evidence", [])
    return AIResolutionResponse(
        outcome=data.get("outcome", "NO"),
        confidence=float(data.get("confidence", 0)),
        evidence=evidence,
        anomaly_alerts=data.get("anomaly_alerts", []),
    )


@router.post("/copilot/recommendation", response_model=CopilotRecommendationResponse)
async def copilot_recommendation(payload: CopilotRecommendationRequest) -> CopilotRecommendationResponse:
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(f"{settings.ai_service_url}/copilot/recommendation", json=payload.model_dump())
            response.raise_for_status()
            data = response.json()
    except Exception as error:
        _handle_upstream_error(error, "/copilot/recommendation")
    return CopilotRecommendationResponse(**data)


@router.post("/market/sentiment-feed")
async def sentiment_feed(payload: dict):
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(f"{settings.ai_service_url}/market/sentiment-feed", json=payload)
            response.raise_for_status()
            return response.json()
    except Exception as error:
        _handle_upstream_error(error, "/market/sentiment-feed")
