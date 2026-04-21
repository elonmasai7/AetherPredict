from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.schemas.strategy_engine import (
    StrategyBuildRequest,
    StrategyBuildResponse,
    StrategyRecordResponse,
)
from app.services.auth_service import get_current_user
from app.services.rate_limit import enforce_rate_limit, request_client_ip
from app.services.strategy_engine_service import StrategyEngineService

router = APIRouter(prefix="/strategy", tags=["strategy"])


@router.post("/create", response_model=StrategyBuildResponse)
async def create_strategy(
    payload: StrategyBuildRequest,
    request: Request,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> StrategyBuildResponse:
    await enforce_rate_limit(
        "strategy-create",
        f"{user.id}:{request_client_ip(request)}",
        settings.strategy_engine_build_limit_per_hour,
        3600,
    )
    return StrategyEngineService(db).build_from_prompt(user, payload.prompt)


@router.get("/list", response_model=list[StrategyRecordResponse])
def list_strategies(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
    limit: int = Query(default=50, ge=1, le=200),
) -> list[StrategyRecordResponse]:
    state = StrategyEngineService(db).get_state(user)
    return state.strategies[:limit]
