from fastapi import APIRouter
from pydantic import BaseModel

from app.services.resolution_engine import (
    anomaly_detection,
    copilot_recommendation,
    market_sentiment_feed,
    probability_update,
    resolve_market,
    score_sentiment,
)

router = APIRouter()


class ResolveRequest(BaseModel):
    market_id: str
    title: str
    oracle_source: str
    data_sources: list[str]


class SentimentRequest(BaseModel):
    topic: str


class ProbabilityRequest(BaseModel):
    market_id: str


class CopilotRequest(BaseModel):
    market_id: str
    wallet_address: str
    portfolio_data: dict


class VaultStrategyRequest(BaseModel):
    vault_id: str
    market_data: dict
    portfolio_state: dict


@router.post("/resolve")
def resolve(payload: ResolveRequest):
    return resolve_market(payload.title, payload.oracle_source, payload.data_sources)


@router.post("/sentiment")
def sentiment(payload: SentimentRequest):
    return score_sentiment(payload.topic)


@router.post("/probability-update")
def probability(payload: ProbabilityRequest):
    return probability_update(payload.market_id)


@router.post("/anomaly-detection")
def anomaly(payload: ProbabilityRequest):
    return anomaly_detection(payload.market_id)


@router.post("/copilot/recommendation")
def copilot(payload: CopilotRequest):
    return copilot_recommendation(payload.model_dump())


@router.post("/market/sentiment-feed")
def sentiment_feed(payload: ProbabilityRequest):
    return market_sentiment_feed(payload.model_dump())


@router.post("/vaults/execute-strategy")
def execute_vault_strategy(payload: VaultStrategyRequest):
    market_data = payload.market_data or {}
    portfolio_state = payload.portfolio_state or {}

    momentum = float(market_data.get("momentum", 0.0))
    sentiment = float(market_data.get("sentiment", 0.0))
    volatility = float(market_data.get("volatility", 0.0))
    drawdown = float(portfolio_state.get("drawdown", 0.0))

    confidence = max(0.05, min(0.99, 0.62 + momentum * 0.2 + sentiment * 0.15 - volatility * 0.2 - drawdown * 0.1))
    market = str(market_data.get("market", "btc_120k"))

    if volatility > 0.7 or drawdown > 0.15:
        action = "BUY_NO"
        reasoning = "Risk-off hedge triggered by elevated volatility/drawdown"
        allocation = 0.08
    elif momentum >= 0.1:
        action = "BUY_YES"
        reasoning = "Momentum breakout signal"
        allocation = 0.15
    elif sentiment <= -0.2:
        action = "BUY_NO"
        reasoning = "Negative sentiment regime with downside skew"
        allocation = 0.12
    else:
        action = "HOLD"
        reasoning = "No dominant edge after confidence normalization"
        allocation = 0.0

    return {
        "action": action,
        "market": market,
        "allocation": allocation,
        "confidence": round(confidence, 4),
        "reasoning": reasoning,
    }
