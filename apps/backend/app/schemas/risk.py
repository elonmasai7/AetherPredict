from pydantic import BaseModel


class PortfolioRiskResponse(BaseModel):
    total_exposure: float
    risk_score: str
    max_loss: float
    var_95: float
    volatility_score: float
    confidence_weighted_risk: float


class ExposureSlice(BaseModel):
    category: str
    allocation: float


class PerformancePoint(BaseModel):
    label: str
    pnl: float
