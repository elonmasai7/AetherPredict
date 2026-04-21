from __future__ import annotations

from datetime import UTC, datetime, timedelta


class NewsService:
    def __init__(self) -> None:
        self.now = datetime.now(UTC)

    def latest_news(self) -> list[dict]:
        now = self.now
        return [
            {
                "id": "news-curry-status",
                "title": "Stephen Curry questionable with ankle soreness ahead of Lakers matchup",
                "summary": "Availability risk lowers Golden State's half-court creation outlook and trims assist upside for surrounding lineups.",
                "source": "ESPN Feed",
                "published_at": now - timedelta(minutes=42),
                "urgency": "high",
                "team": "Golden State Warriors",
                "player": "Stephen Curry",
                "tag": "Injury Alert",
            },
            {
                "id": "news-jokic-boards",
                "title": "Denver leaning bigger in recent rotations, boosting Jokic rebound projection",
                "summary": "Lineup data suggests more defensive rebound opportunities are flowing to Jokic in closing groups.",
                "source": "NBA Official Feed",
                "published_at": now - timedelta(hours=2, minutes=15),
                "urgency": "medium",
                "team": "Denver Nuggets",
                "player": "Nikola Jokic",
                "tag": "Rotation",
            },
            {
                "id": "news-boston-rest",
                "title": "Celtics enter Bucks game on full rest while Milwaukee finishes a travel back-to-back",
                "summary": "Schedule context reinforces Boston's late-game probability edge and defensive consistency projection.",
                "source": "Associated Sports RSS",
                "published_at": now - timedelta(hours=3, minutes=4),
                "urgency": "medium",
                "team": "Boston Celtics",
                "player": None,
                "tag": "Schedule Edge",
            },
            {
                "id": "news-mvp-race",
                "title": "MVP race tightens as voters focus on efficiency and team record balance",
                "summary": "Award markets remain fluid with SGA, Jokic, and Tatum separated by narrow narrative and performance bands.",
                "source": "Sports RSS",
                "published_at": now - timedelta(hours=6),
                "urgency": "low",
                "team": None,
                "player": "Shai Gilgeous-Alexander",
                "tag": "Awards",
            },
        ]

    def news_for_market(self, market: dict) -> list[dict]:
        title = market.get("title", "").lower()
        relevant = []
        for item in self.latest_news():
            team = (item.get("team") or "").lower()
            player = (item.get("player") or "").lower()
            if team and any(token in title for token in team.split()):
                relevant.append(item)
                continue
            if player and any(token in title for token in player.split()):
                relevant.append(item)
        return relevant[:2]
