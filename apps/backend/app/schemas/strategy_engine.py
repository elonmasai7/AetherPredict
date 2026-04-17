from datetime import datetime

from pydantic import BaseModel, Field


class StrategyTemplateResponse(BaseModel):
    key: str
    name: str
    description: str
    use_case: str
    interfaces: list[str]
    ingestion_sources: list[str]
    confidence_method: str
    execution_hook: str


class CanonCommandResponse(BaseModel):
    command: str
    summary: str
    details: list[str]


class StrategyPipelineStepResponse(BaseModel):
    name: str
    status: str
    detail: str


class StrategyAgentRoleResponse(BaseModel):
    name: str
    job: str
    outputs: list[str]


class StrategyRecordResponse(BaseModel):
    id: str
    name: str
    prompt: str
    template_key: str
    template_name: str
    stage: str
    market: str
    confidence: float
    owner: str
    status: str
    created_at: datetime
    updated_at: datetime
    pipeline: list[StrategyPipelineStepResponse]
    project_path: str
    project_name: str


class StrategyEngineMetricsResponse(BaseModel):
    active_strategies: int
    live_deployments: int
    forecast_accuracy: float
    calibration_score: float


class StrategyEngineStateResponse(BaseModel):
    metrics: StrategyEngineMetricsResponse
    canon_commands: list[CanonCommandResponse]
    strategies: list[StrategyRecordResponse]


class StrategyBuildRequest(BaseModel):
    prompt: str = Field(min_length=8)


class StrategyBuildResponse(BaseModel):
    strategy: StrategyRecordResponse
    agents: list[StrategyAgentRoleResponse]
    project_files: list["CanonProjectFileResponse"]


class CanonActionResponse(BaseModel):
    strategy: StrategyRecordResponse
    message: str


class MonitorLogResponse(BaseModel):
    strategy_id: str
    strategy_name: str
    timestamp: datetime
    stage: str
    message: str
    status: str
    confidence: float


class StrategyMonitorResponse(BaseModel):
    logs: list[MonitorLogResponse]


class StrategyRankingEntryResponse(BaseModel):
    rank: int
    strategy: str
    accuracy: float
    pnl: float
    consistency: float
    calibration: float
    risk_adjusted_performance: float
    status: str


class StrategyRankingResponse(BaseModel):
    entries: list[StrategyRankingEntryResponse]


class CanonProjectFileResponse(BaseModel):
    path: str
    content: str


class CanonProjectExportResponse(BaseModel):
    project_name: str
    export_label: str
    files: list[CanonProjectFileResponse]


StrategyBuildResponse.model_rebuild()
