from __future__ import annotations

import asyncio
import json
from collections import defaultdict

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from database import SessionLocal
from models import Market
from routers.markets import liquidity_snapshot


router = APIRouter()


class OddsConnectionManager:
    def __init__(self) -> None:
        self.connections: dict[int, set[WebSocket]] = defaultdict(set)

    async def connect(self, market_id: int, websocket: WebSocket) -> None:
        await websocket.accept()
        self.connections[market_id].add(websocket)

    def disconnect(self, market_id: int, websocket: WebSocket) -> None:
        self.connections[market_id].discard(websocket)
        if not self.connections[market_id]:
            self.connections.pop(market_id, None)

    async def broadcast(self, market_id: int, payload: dict) -> None:
        dead: list[WebSocket] = []
        for connection in self.connections.get(market_id, set()):
            try:
                await connection.send_text(json.dumps(payload))
            except Exception:
                dead.append(connection)
        for connection in dead:
            self.disconnect(market_id, connection)


manager = OddsConnectionManager()


@router.websocket("/ws/odds/{market_id}")
async def odds_stream(websocket: WebSocket, market_id: int) -> None:
    await manager.connect(market_id, websocket)
    db = SessionLocal()
    try:
        market = db.get(Market, market_id)
        if market is not None:
            await websocket.send_text(json.dumps(liquidity_snapshot(market)))
        while True:
            try:
                await asyncio.wait_for(websocket.receive_text(), timeout=1.0)
            except TimeoutError:
                market = db.get(Market, market_id)
                if market is not None:
                    await websocket.send_text(json.dumps(liquidity_snapshot(market)))
            except WebSocketDisconnect:
                break
    finally:
        db.close()
        manager.disconnect(market_id, websocket)
