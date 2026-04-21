from fastapi import APIRouter, WebSocket

from app.core.config import settings
from app.services.redis_bus import subscribe

router = APIRouter()


@router.websocket("/ws/markets")
async def market_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.websocket_channel):
        await websocket.send_json(payload)


@router.websocket("/ws/games")
async def games_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.websocket_channel):
        await websocket.send_json({
            "type": "game",
            "game": payload.get("market"),
            "headline": payload.get("headline"),
            "timestamp": payload.get("timestamp"),
            "confidence": payload.get("confidence"),
        })


@router.websocket("/ws/tx")
async def tx_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.tx_websocket_channel):
        await websocket.send_json(payload)


@router.websocket("/ws/vaults")
async def vault_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.vault_websocket_channel):
        await websocket.send_json(payload)


@router.websocket("/ws/copy")
async def copy_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.copy_websocket_channel):
        await websocket.send_json(payload)


@router.websocket("/ws/vaults")
async def vault_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.vault_websocket_channel):
        await websocket.send_json(payload)


@router.websocket("/ws/copy")
async def copy_stream(websocket: WebSocket):
    await websocket.accept()
    async for payload in subscribe(settings.copy_websocket_channel):
        await websocket.send_json(payload)
