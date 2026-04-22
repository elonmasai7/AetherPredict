from __future__ import annotations

from datetime import UTC, datetime

from app.services.live_data_service import LiveDataService
from app.services.reference_data import seeded_players, seeded_teams


class NbaDataService:
    def __init__(self) -> None:
        self.provider = LiveDataService()

    def teams(self) -> list[dict]:
        standings_result = self.provider.fetch_standings()
        standings = standings_result.data if isinstance(standings_result.data, dict) else {}
        seeded_by_code = {team["id"]: team for team in seeded_teams()}
        teams: list[dict] = []
        entries = standings.get("children") or standings.get("standings") or []

        for group in entries:
            conference = group.get("name") or "Unknown"
            for standing in group.get("standings", {}).get("entries", []):
                team = standing.get("team") or {}
                stats = standing.get("stats") or []
                stats_map = {item.get("name"): item.get("value") for item in stats if item.get("name")}
                abbreviation = team.get("abbreviation") or ""
                seeded = seeded_by_code.get(abbreviation, {})
                teams.append(
                    {
                        "id": abbreviation or str(team.get("id") or ""),
                        "name": team.get("displayName") or team.get("name") or seeded.get("name") or "",
                        "short_name": team.get("shortDisplayName") or abbreviation or seeded.get("short_name") or "",
                        "conference": seeded.get("conference") or conference,
                        "color": f"#{team.get('color')}" if team.get("color") else seeded.get("color", "#111827"),
                        "accent": f"#{team.get('alternateColor')}" if team.get("alternateColor") else seeded.get("accent", "#374151"),
                        "logo_text": abbreviation or seeded.get("logo_text", ""),
                        "win_pct": float(stats_map.get("winPercent") or 0.0),
                        "last_five": self._last_ten(stats_map),
                    }
                )
        teams = [team for team in teams if team["id"] and team["name"]]
        return teams or seeded_teams()

    def players(self) -> list[dict]:
        players: list[dict] = []
        seen_ids: set[str] = set()
        for game in self.live_games():
            summary = self.provider.fetch_summary(game["game_id"])
            payload = summary.data if isinstance(summary.data, dict) else {}
            boxscore = payload.get("boxscore") or {}
            for team_group in boxscore.get("players", []):
                team = team_group.get("team") or {}
                team_id = str(team.get("id") or "")
                team_name = team.get("displayName") or team.get("name") or ""
                for athlete_group in team_group.get("statistics", []):
                    for athlete in athlete_group.get("athletes", []):
                        athlete_info = athlete.get("athlete") or {}
                        player_id = str(athlete_info.get("id") or "")
                        if not player_id or player_id in seen_ids:
                            continue
                        seen_ids.add(player_id)
                        players.append(
                            {
                                "id": player_id,
                                "name": athlete_info.get("displayName") or athlete_info.get("fullName") or "",
                                "team_id": team_id,
                                "team_name": team_name,
                                "position": (athlete_info.get("position") or {}).get("abbreviation") or "",
                                "stats_json": self._stat_map(
                                    athlete_group.get("labels") or [],
                                    athlete.get("stats") or [],
                                ),
                            }
                        )
        return players or seeded_players()

    def live_games(self) -> list[dict]:
        result = self.provider.fetch_scoreboard()
        scoreboard = result.data if isinstance(result.data, dict) else {}
        events = scoreboard.get("events") or []
        games = [self._map_event(event) for event in events]
        return [game for game in games if game is not None]

    def game_by_id(self, game_id: str) -> dict | None:
        summary = self.provider.fetch_summary(game_id)
        if isinstance(summary.data, dict) and summary.data.get("header"):
            event = {
                "id": game_id,
                "name": summary.data.get("header", {}).get("competitions", [{}])[0].get("name"),
                "date": summary.data.get("header", {}).get("competitions", [{}])[0].get("date"),
                "status": summary.data.get("header", {}).get("competitions", [{}])[0].get("status"),
                "competitions": summary.data.get("header", {}).get("competitions") or [],
            }
            mapped = self._map_event(event, summary.data)
            if mapped is not None:
                return mapped
        return next((game for game in self.live_games() if game["game_id"] == game_id), None)

    def _map_event(self, event: dict, summary: dict | None = None) -> dict | None:
        competition = (event.get("competitions") or [{}])[0]
        competitors = competition.get("competitors") or []
        home = next((row for row in competitors if row.get("homeAway") == "home"), None)
        away = next((row for row in competitors if row.get("homeAway") == "away"), None)
        if home is None or away is None:
            return None
        status = (competition.get("status") or event.get("status") or {}).get("type") or {}
        situation = competition.get("situation") or {}
        home_team = home.get("team") or {}
        away_team = away.get("team") or {}
        tipoff = self._parse_datetime(competition.get("date") or event.get("date"))
        headline = (
            (situation.get("lastPlay") or {}).get("text")
            or (summary or {}).get("headline")
            or status.get("detail")
            or "No live data available"
        )
        return {
            "game_id": str(event.get("id") or ""),
            "id": str(event.get("id") or ""),
            "matchup": event.get("name") or f"{away_team.get('shortDisplayName', 'Away')} vs {home_team.get('shortDisplayName', 'Home')}",
            "status": status.get("shortDetail") or status.get("detail") or "No live data available",
            "tipoff_time": tipoff,
            "start_time": tipoff,
            "team_a": home_team.get("displayName") or home_team.get("name") or "",
            "team_b": away_team.get("displayName") or away_team.get("name") or "",
            "team_a_id": str(home_team.get("id") or ""),
            "team_b_id": str(away_team.get("id") or ""),
            "home_team": home_team.get("displayName") or home_team.get("name") or "",
            "away_team": away_team.get("displayName") or away_team.get("name") or "",
            "home_score": int(float(home.get("score") or 0)),
            "away_score": int(float(away.get("score") or 0)),
            "win_probability_home": self._home_win_probability(competition, home, away, status),
            "pace": self._pace_estimate(competition, home, away),
            "headline": headline,
        }

    def _home_win_probability(self, competition: dict, home: dict, away: dict, status: dict) -> float:
        probabilities = competition.get("probabilities") or []
        if probabilities:
            source = probabilities[0]
            for key in ("homeWinPercentage", "homeWinPct", "homeTeamPercentage"):
                value = source.get(key)
                if value is not None:
                    return self._normalize_probability(value)

        home_score = int(float(home.get("score") or 0))
        away_score = int(float(away.get("score") or 0))
        if status.get("completed"):
            return 1.0 if home_score > away_score else 0.0

        differential = home_score - away_score
        clock_text = status.get("shortDetail") or ""
        progress_bonus = 0.0
        if "Q4" in clock_text or "OT" in clock_text:
            progress_bonus = 0.12
        elif "Q3" in clock_text:
            progress_bonus = 0.08
        elif "Q2" in clock_text:
            progress_bonus = 0.04
        return max(0.01, min(0.99, 0.5 + (differential * 0.018) + progress_bonus))

    def _pace_estimate(self, competition: dict, home: dict, away: dict) -> float:
        total_score = int(float(home.get("score") or 0)) + int(float(away.get("score") or 0))
        detail = ((competition.get("status") or {}).get("type") or {}).get("shortDetail") or ""
        if "Q4" in detail or "OT" in detail:
            divisor = 1.0
        elif "Q3" in detail:
            divisor = 0.75
        elif "Q2" in detail:
            divisor = 0.5
        elif "Q1" in detail:
            divisor = 0.25
        else:
            return 0.0
        return round(total_score / max(divisor, 0.25), 1)

    def _stat_map(self, labels: list[str], values: list[str]) -> dict:
        stats: dict[str, str] = {}
        for index, label in enumerate(labels):
            if index >= len(values):
                break
            stats[label] = values[index]
        return stats

    def _parse_datetime(self, value: str | None) -> datetime:
        if not value:
            return datetime.now(UTC)
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return datetime.now(UTC)
        return parsed.astimezone(UTC) if parsed.tzinfo else parsed.replace(tzinfo=UTC)

    def _normalize_probability(self, value) -> float:
        numeric = float(value)
        return round(numeric / 100 if numeric > 1 else numeric, 4)

    def _last_ten(self, stats_map: dict) -> str:
        value = stats_map.get("lastTenGames")
        if isinstance(value, str) and "-" in value:
            return value
        return ""
