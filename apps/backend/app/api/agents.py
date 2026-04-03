from fastapi import APIRouter

from app.services.demo_data import demo_agents

router = APIRouter(prefix="/agents", tags=["agents"])


@router.get("")
def list_agents():
    return demo_agents()
