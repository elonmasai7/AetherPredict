import asyncio
from datetime import datetime
from random import uniform

from fastapi import APIRouter, WebSocket

router = APIRouter()


@router.websocket("/ws/markets")
async def market_stream(websocket: WebSocket):
    await websocket.accept()
    while True:
        await websocket.send_json(
            {
                "market": "btc-120k-2026",
                "yes_probability": round(uniform(0.69, 0.76), 4),
                "confidence": round(uniform(0.87, 0.93), 4),
                "timestamp": datetime.utcnow().isoformat(),
            }
        )
        await asyncio.sleep(2)
