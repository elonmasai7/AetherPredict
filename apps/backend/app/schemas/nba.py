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
    id: str | None = None
    matchup: str
    status: str
    tipoff_time: datetime
    start_time: datetime | None = None
    team_a: str | None = None
    team_b: str | None = None
    team_a_id: str | None = None
    team_b_id: str | None = None
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
    url: str
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


class NbaTeamResponse(BaseModel):
    id: str
    name: str
    short_name: str
    conference: str
    color: str
    accent: str
    logo_text: str
    win_pct: float
    last_five: str


class NbaPlayerResponse(BaseModel):
    id: str
    name: str
    team_id: str
    team_name: str
    position: str
    stats_json: dict


class MarketCreateRequest(BaseModel):
    title: str
    description: str
    category: str
    oracle_source: str
    expiry_at: datetime
    yes_label: str = "Yes"
    no_label: str = "No"
    liquidity_amount: float = 0
    wallet_address: str | None = None


class PredictRequest(BaseModel):
    market_id: int
    user_id: int | None = None
    choice: str
    amount: float
    confidence: float = 0.7
    wallet_address: str | None = None


class ClosePredictionRequest(BaseModel):
    prediction_id: int
    wallet_address: str | None = None


class PredictionResponse(BaseModel):
    id: int
    user_id: int
    market_id: int
    choice: str
    amount: float
    entry_price: float
    status: str
    tx_status: str


class AnalyzeGameRequest(BaseModel):
    game_id: str | None = None
    market_id: int | None = None


class GeneratePredictionRequest(BaseModel):
    market_id: int
    amount: float = 100


class CustomAgentRequest(BaseModel):
    prompt: str
    risk_level: str = "balanced"
    data_sources: list[str] = []
    automation_enabled: bool = False


class AiPredictionResponse(BaseModel):
    market_id: int | None = None
    probability: float
    confidence: float
    predicted_side: str
    reasoning: list[str]
    suggested_amount: float
    impact_level: str | None = None


class LiquidityResponse(BaseModel):
    market_id: int
    liquidity: float
    spread: float
    depth: float
    slippage: float
    liquidity_score: float
    bids: list[dict]
    asks: list[dict]


class AddLiquidityRequest(BaseModel):
    market_id: int
    amount: float
    wallet_address: str | None = None


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
