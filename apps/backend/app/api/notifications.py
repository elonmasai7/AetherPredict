from fastapi import APIRouter

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("")
def list_notifications():
    return [
        {"level": "info", "message": "BTC > $120k probability moved from 68% to 74%"},
        {"level": "warning", "message": "Sentinel agent detected whale activity"},
    ]
