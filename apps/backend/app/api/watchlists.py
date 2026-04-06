from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import Watchlist, WatchlistItem
from app.schemas.watchlist import WatchlistItemRequest, WatchlistResponse
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/watchlists", tags=["watchlists"])


@router.get("", response_model=list[WatchlistResponse])
def list_watchlists(db: Session = Depends(get_db), user=Depends(get_current_user)) -> list[WatchlistResponse]:
    rows = db.scalars(select(Watchlist).where(Watchlist.user_id == user.id).order_by(Watchlist.updated_at.desc())).all()
    return [
        WatchlistResponse(
            id=row.id,
            name=row.name,
            market_ids=[item.market_id for item in row.items],
            created_at=row.created_at,
            updated_at=row.updated_at,
        )
        for row in rows
    ]


@router.post("", response_model=WatchlistResponse, status_code=201)
def create_default_watchlist(db: Session = Depends(get_db), user=Depends(get_current_user)) -> WatchlistResponse:
    watchlist = Watchlist(user_id=user.id, name="Default Watchlist")
    db.add(watchlist)
    db.commit()
    db.refresh(watchlist)
    return WatchlistResponse(id=watchlist.id, name=watchlist.name, market_ids=[], created_at=watchlist.created_at, updated_at=watchlist.updated_at)


@router.post("/{watchlist_id}/items", response_model=WatchlistResponse)
def add_watchlist_item(
    watchlist_id: int,
    payload: WatchlistItemRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> WatchlistResponse:
    watchlist = db.scalar(select(Watchlist).where(Watchlist.id == watchlist_id, Watchlist.user_id == user.id))
    if watchlist is None:
        raise HTTPException(status_code=404, detail="Watchlist not found")
    exists = db.scalar(
        select(WatchlistItem).where(WatchlistItem.watchlist_id == watchlist.id, WatchlistItem.market_id == payload.market_id)
    )
    if exists is None:
        db.add(WatchlistItem(watchlist_id=watchlist.id, market_id=payload.market_id))
        db.commit()
        db.refresh(watchlist)
    return WatchlistResponse(
        id=watchlist.id,
        name=watchlist.name,
        market_ids=[item.market_id for item in watchlist.items],
        created_at=watchlist.created_at,
        updated_at=watchlist.updated_at,
    )
