from pydantic import BaseModel


class CopilotRecommendationRequest(BaseModel):
    market_id: str
    wallet_address: str
    portfolio_data: dict


class CopilotRecommendationResponse(BaseModel):
    action: str
    confidence: int
    risk: str
    reasoning: str
    position_size: str
    sentiment_trend: str
