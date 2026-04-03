from fastapi import APIRouter

from app.schemas.portfolio import PositionResponse
from app.services.demo_data import demo_positions

router = APIRouter(prefix="/portfolio", tags=["portfolio"])


@router.get("/positions", response_model=list[PositionResponse])
def positions() -> list[PositionResponse]:
    return [PositionResponse(**item) for item in demo_positions()]
