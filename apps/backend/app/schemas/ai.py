from pydantic import BaseModel


class AIResolutionRequest(BaseModel):
    market_id: str
    title: str
    oracle_source: str
    data_sources: list[str]


class AIResolutionResponse(BaseModel):
    outcome: str
    confidence: float
    evidence: list[str]
    anomaly_alerts: list[str]
