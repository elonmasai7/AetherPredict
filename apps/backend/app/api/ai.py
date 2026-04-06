import httpx
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.schemas.ai import AIResolutionRequest, AIResolutionResponse, AISignalRequest, RiskAnalysisRequest
from app.schemas.copilot import CopilotRecommendationRequest, CopilotRecommendationResponse
from app.services.ai_engine import build_risk_analysis, build_signal
from app.services.auth_service import get_current_user, get_optional_user

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

    evidence = data.get("evidence") or data.get("supporting_evidence", [])
    return AIResolutionResponse(
        outcome=data.get("outcome", "NO"),
        confidence=float(data.get("confidence", 0)),
        evidence=evidence,
        anomaly_alerts=data.get("anomaly_alerts", []),
    )


@router.post("/signal")
def signal(payload: AISignalRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> dict:
    wallet_address = payload.wallet_address or (user.wallet_address if user else None)
    signal_row = build_signal(db, payload.market_id, wallet_address)
    return {
        "id": signal_row.id,
        "action": signal_row.action,
        "confidence": signal_row.confidence,
        "risk": signal_row.risk,
        "reasoning": signal_row.reasoning,
        "payload": signal_row.payload_json,
    }


@router.post("/copilot", response_model=CopilotRecommendationResponse)
def copilot(payload: CopilotRecommendationRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> CopilotRecommendationResponse:
    wallet_address = payload.wallet_address or (user.wallet_address if user else None)
    signal_row = build_signal(db, int(payload.market_id), wallet_address)
    return CopilotRecommendationResponse(
        action=signal_row.action,
        confidence=round(signal_row.confidence * 100),
        risk=signal_row.risk,
        reasoning=signal_row.reasoning,
        position_size=f"{max(2, min(25, round(signal_row.confidence * 20)))}%",
        sentiment_trend="BULLISH" if signal_row.action == "BUY_YES" else "BEARISH",
    )


@router.post("/risk-analysis")
def risk_analysis(payload: RiskAnalysisRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> dict:
    wallet_address = payload.wallet_address or (user.wallet_address if user else "")
    return build_risk_analysis(db, wallet_address)


@router.post("/copilot/recommendation", response_model=CopilotRecommendationResponse)
def legacy_copilot(payload: CopilotRecommendationRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> CopilotRecommendationResponse:
    return copilot(payload, db, user)


@router.post("/market/sentiment-feed")
async def sentiment_feed(payload: dict) -> dict:
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(f"{settings.ai_service_url}/market/sentiment-feed", json=payload)
            response.raise_for_status()
            return response.json()
    except Exception as error:
        _handle_upstream_error(error, "/market/sentiment-feed")
