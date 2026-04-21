from datetime import datetime

from pydantic import BaseModel


class NbaOverviewResponse(BaseModel):
    active_markets: int
    live_games: int
    model_accuracy: float
    total_liquidity: float
    open_predictions: int
    prediction_roi: float


class NbaLiveGameResponse(BaseModel):
    game_id: str
    matchup: str
    status: str
    tipoff_time: datetime
    home_team: str
    away_team: str
    home_score: int
    away_score: int
    win_probability_home: float
    pace: float
    headline: str


class NbaNewsItemResponse(BaseModel):
    id: str
    title: str
    summary: str
    source: str
    published_at: datetime
    urgency: str
    team: str | None = None
    player: str | None = None
    tag: str


class NbaAgentResponse(BaseModel):
    key: str
    name: str
    specialty: str
    status: str
    confidence: float
    historical_accuracy: float
    roi: float
    active_markets: int
    summary: str
    recommendation: str


class NbaLeaderboardEntryResponse(BaseModel):
    rank: int
    name: str
    accuracy: float
    roi: float
    consistency: float
    predictions: int
    streak: int


class NbaMarketResponse(BaseModel):
    id: int
    slug: str
    title: str
    market_type: str
    category: str
    matchup: str
    primary_subject: str
    yes_label: str
    no_label: str
    yes_probability: float
    no_probability: float
    ai_confidence: float
    volume: float
    liquidity: float
    spread_bps: float
    depth: float
    slippage: float
    liquidity_score: float
    team_form: dict
    player_context: dict
    probability_points: list[float]
    ai_insight: str
    latest_news: list[NbaNewsItemResponse]
    expires_at: datetime
    confidence_label: str


class PredictionActivityResponse(BaseModel):
    id: str
    user: str
    market: str
    pick: str
    confidence: str
    amount: float
    created_at: datetime


class StrategyPreviewRequest(BaseModel):
    prompt: str
    data_sources: list[str] = []
    risk_level: str = "balanced"
    automation_enabled: bool = False


class StrategyPreviewResponse(BaseModel):
    title: str
    summary: str
    probability: float
    confidence: float
    execution_ready: bool
    suggested_market_id: int | None = None
    rationale: list[str]
    safeguards: list[str]


class PlatformHomeResponse(BaseModel):
    generated_at: datetime
    overview: NbaOverviewResponse
    featured_market_id: int | None = None
    live_games: list[NbaLiveGameResponse]
    markets: list[NbaMarketResponse]
    news: list[NbaNewsItemResponse]
    agents: list[NbaAgentResponse]
    leaderboard: list[NbaLeaderboardEntryResponse]
    activity_feed: list[PredictionActivityResponse]
    recent_predictions: list[PredictionActivityResponse]
