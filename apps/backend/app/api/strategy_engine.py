from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.strategy_engine import (
    CanonActionResponse,
    CanonProjectExportResponse,
    StrategyBuildRequest,
    StrategyBuildResponse,
    StrategyEngineStateResponse,
    StrategyMonitorResponse,
    StrategyRankingResponse,
    StrategyTemplateResponse,
)
from app.services.auth_service import get_current_user
from app.services.strategy_engine_service import StrategyEngineService

router = APIRouter(prefix="/strategy-engine", tags=["strategy-engine"])


@router.get(
    "/state",
    response_model=StrategyEngineStateResponse,
    summary="Get Strategy Engine state",
    description="Return live Strategy Engine metrics, Canon commands, and persisted strategy workflow records for the authenticated user.",
)
def state(db: Session = Depends(get_db), user=Depends(get_current_user)) -> StrategyEngineStateResponse:
    return StrategyEngineService(db).get_state(user)


@router.get(
    "/templates",
    response_model=list[StrategyTemplateResponse],
    summary="List Strategy Engine templates",
    description="Return forecasting templates available to Canon project generation and the AI Builder.",
)
def templates(db: Session = Depends(get_db), user=Depends(get_current_user)) -> list[StrategyTemplateResponse]:
    return StrategyEngineService(db).templates()


@router.post(
    "/build",
    response_model=StrategyBuildResponse,
    summary="Build a strategy from a prompt",
    description="Generate a persisted Strategy Engine workflow, AI agent plan, and Canon project scaffold from a natural-language forecasting prompt.",
)
def build(payload: StrategyBuildRequest, db: Session = Depends(get_db), user=Depends(get_current_user)) -> StrategyBuildResponse:
    return StrategyEngineService(db).build_from_prompt(user, payload.prompt)


@router.post(
    "/strategies/{strategy_id}/canon/{command}",
    response_model=CanonActionResponse,
    summary="Run a Canon workflow command",
    description="Advance a persisted strategy through Canon workflow stages such as init, start, or deploy.",
)
def canon_action(
    strategy_id: str,
    command: str,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> CanonActionResponse:
    return StrategyEngineService(db).run_canon_action(user, strategy_id, command)


@router.get(
    "/monitor",
    response_model=StrategyMonitorResponse,
    summary="Get Strategy Engine monitor logs",
    description="Return aggregated monitor logs for Canon workflow activity, strategy stages, and deployment updates.",
)
def monitor(db: Session = Depends(get_db), user=Depends(get_current_user)) -> StrategyMonitorResponse:
    return StrategyEngineService(db).monitor(user)


@router.get(
    "/ranking",
    response_model=StrategyRankingResponse,
    summary="Get Strategy Engine ranking",
    description="Return forecast-quality leaderboard data for registered prediction strategies.",
)
def ranking(db: Session = Depends(get_db), user=Depends(get_current_user)) -> StrategyRankingResponse:
    return StrategyEngineService(db).ranking(user)


@router.get(
    "/strategies/{strategy_id}/export/manifest",
    response_model=CanonProjectExportResponse,
    summary="Get Canon export manifest",
    description="Return the logical file manifest for a Canon project export so UI clients can inspect generated files.",
)
def export_project_manifest(strategy_id: str, db: Session = Depends(get_db), user=Depends(get_current_user)) -> CanonProjectExportResponse:
    return StrategyEngineService(db).export_project(user, strategy_id)


@router.get(
    "/strategies/{strategy_id}/export",
    summary="Download Canon project archive",
    description="Download a generated Canon project as a zip or tar archive for the authenticated user.",
)
def export_project_archive(
    strategy_id: str,
    format: str = Query(default="zip", pattern="^(zip|tar)$"),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> Response:
    filename, media_type, payload = StrategyEngineService(db).export_project_archive(
        user,
        strategy_id,
        format,
    )
    headers = {"Content-Disposition": f'attachment; filename="{filename}"'}
    return Response(content=payload, media_type=media_type, headers=headers)
