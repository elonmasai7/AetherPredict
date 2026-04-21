from __future__ import annotations


class AgentEngine:
    def build_agents(self, markets: list[dict], news: list[dict]) -> list[dict]:
        active_markets = len(markets)
        high_impact_news = sum(1 for item in news if item.get("urgency") == "high")
        return [
            {
                "key": "game-analyst",
                "name": "Game Analyst Agent",
                "specialty": "Outcome probability modeling",
                "status": "online",
                "confidence": 0.76,
                "historical_accuracy": 0.684,
                "roi": 18.4,
                "active_markets": active_markets,
                "summary": "Ranks game outcome markets by efficiency gap, rest advantage, and late-game shot quality.",
                "recommendation": "Lakers and Celtics game lines still show the clearest pre-game edge.",
            },
            {
                "key": "player-performance",
                "name": "Player Performance Agent",
                "specialty": "Prop prediction and usage tracking",
                "status": "online",
                "confidence": 0.71,
                "historical_accuracy": 0.661,
                "roi": 14.1,
                "active_markets": max(3, active_markets // 2),
                "summary": "Tracks usage, expected minutes, touch profile, and opponent scheme to rate player props.",
                "recommendation": "Jokic rebounds profiles strongest; Curry assists need injury clarity.",
            },
            {
                "key": "news-impact",
                "name": "News Impact Agent",
                "specialty": "Headline-to-probability adjustments",
                "status": "watching",
                "confidence": 0.74,
                "historical_accuracy": 0.652,
                "roi": 11.8,
                "active_markets": high_impact_news + 2,
                "summary": "Scores injury alerts, travel spots, and lineup notes for immediate market repricing.",
                "recommendation": "Monitor Warriors news feed before locking aggressive pre-game exposure.",
            },
            {
                "key": "custom-strategy",
                "name": "Custom Strategy Agent",
                "specialty": "Prompt-driven strategy generation",
                "status": "ready",
                "confidence": 0.79,
                "historical_accuracy": 0.69,
                "roi": 20.6,
                "active_markets": active_markets,
                "summary": "Transforms natural language prompts into NBA-specific decision rules, confidence scoring, and optional execution.",
                "recommendation": "Use prompts combining last 5 games, injury data, and matchup history for the strongest previews.",
            },
        ]
