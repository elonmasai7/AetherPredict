import httpx
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.schemas.ai import AIResolutionRequest, AIResolutionResponse, AISignalRequest, RiskAnalysisRequest
from app.schemas.copilot import CopilotRecommendationRequest, CopilotRecommendationResponse
from app.schemas.nba import AiPredictionResponse, AnalyzeGameRequest, CustomAgentRequest, GeneratePredictionRequest
from app.services.ai_engine import build_risk_analysis, build_signal
from app.services.auth_service import get_current_user, get_optional_user
from app.services.market_service import MarketService
from app.services.prediction_engine import PredictionEngine

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


@router.post("/analyze-game", response_model=AiPredictionResponse)
def analyze_game(payload: AnalyzeGameRequest, db: Session = Depends(get_db)) -> AiPredictionResponse:
    markets = MarketService(db).enriched_markets()
    market = None
    if payload.market_id is not None:
        market = next((row for row in markets if row["id"] == payload.market_id), None)
    elif payload.game_id is not None:
        market = next((row for row in markets if payload.game_id.replace("-", " ")[:3].lower() in row["title"].lower()), None)
    if market is None and markets:
        market = markets[0]
    if market is None:
        raise HTTPException(status_code=404, detail="No market available")
    return AiPredictionResponse(
        market_id=market["id"],
        probability=market["yes_probability"],
        confidence=market["ai_confidence"],
        predicted_side="YES" if market["yes_probability"] >= 0.5 else "NO",
        reasoning=[
            market["ai_insight"],
            f"Liquidity score {market['liquidity_score']:.1f} with spread {market['spread_bps']:.0f} bps.",
            "Latest news and recent form were incorporated into the recommendation.",
        ],
        suggested_amount=125.0,
    )


@router.post("/generate-prediction", response_model=AiPredictionResponse)
def generate_prediction(payload: GeneratePredictionRequest, db: Session = Depends(get_db)) -> AiPredictionResponse:
    markets = MarketService(db).enriched_markets()
    market = next((row for row in markets if row["id"] == payload.market_id), None)
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    side = "YES" if market["yes_probability"] >= 0.5 else "NO"
    return AiPredictionResponse(
        market_id=market["id"],
        probability=market["yes_probability"] if side == "YES" else market["no_probability"],
        confidence=market["ai_confidence"],
        predicted_side=side,
        reasoning=[
            market["ai_insight"],
            f"Suggested size adapts to requested amount ${payload.amount:.0f}.",
        ],
        suggested_amount=round(payload.amount * max(0.5, market["ai_confidence"]), 2),
    )


@router.post("/custom-agent", response_model=AiPredictionResponse)
def custom_agent(payload: CustomAgentRequest, db: Session = Depends(get_db)) -> AiPredictionResponse:
    preview = PredictionEngine().preview_strategy(
        payload.prompt,
        MarketService(db).enriched_markets(),
        payload.risk_level,
        payload.automation_enabled,
        payload.data_sources,
    )
    side = "YES" if preview["probability"] >= 0.5 else "NO"
    return AiPredictionResponse(
        market_id=preview["suggested_market_id"],
        probability=preview["probability"],
        confidence=preview["confidence"],
        predicted_side=side,
        reasoning=preview["rationale"],
        suggested_amount=150.0 if payload.risk_level == "aggressive" else 90.0,
        impact_level="high" if preview["confidence"] >= 0.75 else "medium",
    )
