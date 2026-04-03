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
