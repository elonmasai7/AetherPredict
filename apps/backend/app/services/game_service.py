from __future__ import annotations

from app.services.nba_data_service import NbaDataService


class GameService:
    def __init__(self) -> None:
        self.data = NbaDataService()

    def list_games(self) -> list[dict]:
        return self.data.live_games()

    def get_game(self, game_id: str) -> dict | None:
        return self.data.game_by_id(game_id)

    def list_teams(self) -> list[dict]:
        return self.data.teams()

    def list_players(self) -> list[dict]:
        return self.data.players()
