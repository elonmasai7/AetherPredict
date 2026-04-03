from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import agents, ai, auth, disputes, markets, notifications, portfolio, ws
from app.core.config import settings

app = FastAPI(title=settings.app_name, version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(markets.router)
app.include_router(portfolio.router)
app.include_router(ai.router)
app.include_router(agents.router)
app.include_router(disputes.router)
app.include_router(notifications.router)
app.include_router(ws.router)


@app.get("/health")
def health():
    return {"status": "ok", "service": "backend"}
