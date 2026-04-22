from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import AgentStatus
from app.services.agent_engine import AgentEngine
from app.services.market_service import MarketService
from app.services.news_service import NewsService


def bootstrap_nba_platform(db: Session) -> None:
    market_service = MarketService(db)
    market_service.sync_live_markets()
    markets = market_service.enriched_markets()
    news = NewsService().latest_news()
    agents = AgentEngine().build_agents(markets, news)
    existing = {
        row.agent_key: row
        for row in db.scalars(select(AgentStatus)).all()
    }
    changed = False
    for agent in agents:
        row = existing.get(agent["name"])
        if row is None:
            row = AgentStatus(
                agent_key=agent["name"],
                status=agent["status"],
                interventions=agent["active_markets"],
                pnl=agent["roi"],
                summary=agent["summary"],
                active_trades=agent["active_markets"],
            )
            db.add(row)
            changed = True
            continue
        row.status = agent["status"]
        row.interventions = agent["active_markets"]
        row.pnl = agent["roi"]
        row.summary = agent["summary"]
        row.active_trades = agent["active_markets"]
        changed = True
    if changed:
        db.commit()
