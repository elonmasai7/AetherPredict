from fastapi import APIRouter, WebSocket
from starlette.websockets import WebSocketDisconnect

from app.core.config import settings
from app.services.redis_bus import subscribe

router = APIRouter()


@router.websocket("/ws/markets")
async def market_stream(websocket: WebSocket):
    await websocket.accept()
    try:
        async for payload in subscribe(settings.websocket_channel):
            await websocket.send_json(payload)
    except WebSocketDisconnect:
        return


@router.websocket("/ws/games")
async def games_stream(websocket: WebSocket):
    await websocket.accept()
    try:
        async for payload in subscribe(settings.games_websocket_channel):
            await websocket.send_json(payload)
    except WebSocketDisconnect:
        return


@router.websocket("/ws/activity")
async def activity_stream(websocket: WebSocket):
    await websocket.accept()
    try:
        async for payload in subscribe(settings.activity_websocket_channel):
            await websocket.send_json(payload)
    except WebSocketDisconnect:
        return


@router.websocket("/ws/tx")
async def tx_stream(websocket: WebSocket):
    await websocket.accept()
    try:
        async for payload in subscribe(settings.tx_websocket_channel):
            await websocket.send_json(payload)
    except WebSocketDisconnect:
        return


@router.websocket("/ws/vaults")
async def vault_stream(websocket: WebSocket):
    await websocket.accept()
    try:
        async for payload in subscribe(settings.vault_websocket_channel):
            await websocket.send_json(payload)
    except WebSocketDisconnect:
        return


@router.websocket("/ws/copy")
async def copy_stream(websocket: WebSocket):
    await websocket.accept()
    try:
        async for payload in subscribe(settings.copy_websocket_channel):
            await websocket.send_json(payload)
    except WebSocketDisconnect:
        return
