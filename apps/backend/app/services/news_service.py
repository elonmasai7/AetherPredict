from __future__ import annotations

from app.services.live_data_service import LiveDataService
from app.services.reference_data import seeded_players, seeded_teams


class NewsService:
    def __init__(self) -> None:
        self.provider = LiveDataService()

    def latest_news(self) -> list[dict]:
        items, warning = self.provider.fetch_news_items()
        # Use seeded reference data to enrich team/player fields without
        # incurring expensive live player/boxscore fetches inside news flows.
        teams = seeded_teams()
        players = seeded_players()
        enriched: list[dict] = []
        for item in items:
            title = item["title"]
            summary = item["summary"]
            urgency = self._urgency(title, summary)
            team = self._match_team(title, summary, teams)
            player = self._match_player(title, summary, players)
            enriched.append(
                {
                    **item,
                    "urgency": urgency,
                    "team": team,
                    "player": player,
                    "tag": self._tag(title, summary, urgency),
                }
            )

        if enriched:
            return enriched
        if warning:
            return []
        return []

    def news_for_market(self, market: dict, *, news_items: list[dict] | None = None) -> list[dict]:
        items = news_items if news_items is not None else self.latest_news()
        text = " ".join(
            filter(
                None,
                [
                    market.get("title"),
                    market.get("matchup"),
                    market.get("primary_subject"),
                    market.get("yes_label"),
                    market.get("no_label"),
                ],
            )
        ).lower()
        return [
            item
            for item in items
            if any(token and token in text for token in self._news_tokens(item))
        ][:5]

    def news_for_team(self, team: str, *, news_items: list[dict] | None = None) -> list[dict]:
        items = news_items if news_items is not None else self.latest_news()
        query = team.lower()
        return [
            item
            for item in items
            if query in (item.get("team") or "").lower()
        ]

    def _match_team(self, title: str, summary: str, teams: list[dict]) -> str | None:
        haystack = f"{title} {summary}".lower()
        for team in teams:
            if team["name"].lower() in haystack or team["short_name"].lower() in haystack:
                return team["name"]
        return None

    def _match_player(self, title: str, summary: str, players: list[dict]) -> str | None:
        haystack = f"{title} {summary}".lower()
        for player in players:
            if player["name"].lower() in haystack:
                return player["name"]
        return None

    def _urgency(self, title: str, summary: str) -> str:
        haystack = f"{title} {summary}".lower()
        if any(token in haystack for token in ("questionable", "out ", "injury", "doubtful", "breaking")):
            return "high"
        if any(token in haystack for token in ("probable", "update", "report", "returns", "active")):
            return "medium"
        return "low"

    def _tag(self, title: str, summary: str, urgency: str) -> str:
        haystack = f"{title} {summary}".lower()
        if any(token in haystack for token in ("questionable", "out ", "injury", "doubtful")):
            return "Injury Alert"
        if "trade" in haystack:
            return "Roster Move"
        if urgency == "high":
            return "Breaking"
        return "News"

    def _news_tokens(self, item: dict) -> list[str]:
        values = [item.get("team") or "", item.get("player") or "", item.get("title") or ""]
        tokens: list[str] = []
        for value in values:
            tokens.extend(token.lower() for token in value.split() if len(token) > 2)
        return tokens
