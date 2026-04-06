from fastapi import APIRouter, WebSocket

from app.core.config import settings
from app.services.redis_bus import subscribe

router = APIRouter()


@router.websocket("/ws/markets")
async def market_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.websocket_channel):
        await websocket.send_json(payload)


@router.websocket("/ws/tx")
async def tx_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.tx_websocket_channel):
        await websocket.send_json(payload)
