from __future__ import annotations


class AgentEngine:
    def build_agents(self, markets: list[dict], news: list[dict]) -> list[dict]:
        if not markets and not news:
            return []

        avg_confidence = sum(market.get("ai_confidence", 0) for market in markets) / max(len(markets), 1)
        high_impact_news = [item for item in news if item.get("urgency") == "high"]
        live_markets = [market for market in markets if any(token in market.get("matchup", "") for token in (" at ", " vs "))]

        return [
            {
                "key": "game-analyst",
                "name": "Game Analyst Agent",
                "specialty": "Outcome probability modeling",
                "status": "online" if live_markets else "idle",
                "confidence": round(avg_confidence, 4),
                "historical_accuracy": round(avg_confidence, 4),
                "roi": 0.0,
                "active_markets": len(live_markets),
                "summary": f"Tracking {len(live_markets)} live outcome markets from the current NBA feed.",
                "recommendation": f"{len(high_impact_news)} high-impact headline(s) are affecting live probabilities.",
            },
            {
                "key": "news-impact",
                "name": "News Impact Agent",
                "specialty": "Headline-to-probability adjustments",
                "status": "watching" if news else "idle",
                "confidence": round(min(0.95, avg_confidence + 0.03), 4),
                "historical_accuracy": round(avg_confidence, 4),
                "roi": 0.0,
                "active_markets": len(high_impact_news),
                "summary": f"Watching {len(news)} live headline(s) across ESPN and configured RSS feeds.",
                "recommendation": high_impact_news[0]["title"] if high_impact_news else "No high-impact alert is active.",
            },
            {
                "key": "custom-strategy",
                "name": "Custom Strategy Agent",
                "specialty": "Prompt-driven strategy generation",
                "status": "ready" if markets else "idle",
                "confidence": round(avg_confidence, 4),
                "historical_accuracy": round(avg_confidence, 4),
                "roi": 0.0,
                "active_markets": len(markets),
                "summary": "Builds user-defined strategies against the currently available live market set.",
                "recommendation": f"{len(markets)} live market(s) are available for prompt-driven analysis.",
            },
        ]
