from fastapi import APIRouter, HTTPException

from app.schemas.nba import NbaLiveGameResponse, NbaPlayerResponse, NbaTeamResponse
from app.services.game_service import GameService

router = APIRouter(tags=["nba-data"])


@router.get("/games", response_model=list[NbaLiveGameResponse])
def list_games() -> list[NbaLiveGameResponse]:
    return [NbaLiveGameResponse(**game) for game in GameService().list_games()]


@router.get("/games/{game_id}", response_model=NbaLiveGameResponse)
def get_game(game_id: str) -> NbaLiveGameResponse:
    game = GameService().get_game(game_id)
    if game is None:
        raise HTTPException(status_code=404, detail="Game not found")
    return NbaLiveGameResponse(**game)


@router.get("/teams", response_model=list[NbaTeamResponse])
def list_teams() -> list[NbaTeamResponse]:
    return [NbaTeamResponse(**team) for team in GameService().list_teams()]


@router.get("/players", response_model=list[NbaPlayerResponse])
def list_players() -> list[NbaPlayerResponse]:
    return [NbaPlayerResponse(**player) for player in GameService().list_players()]
