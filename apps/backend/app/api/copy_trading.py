import asyncio

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.copy_trading import (
    CopyPerformanceSnapshotResponse,
    CopyPortfolioSummary,
    CopyRelationshipResponse,
    CopiedTradeResponse,
    FollowTraderRequest,
    UpdateCopySettingsRequest,
)
from app.services.auth_service import get_current_user
from app.services.copy_trading_service import CopyTradingService

router = APIRouter(prefix="/copy-trading", tags=["copy-trading"])


@router.post("/follow", response_model=CopyRelationshipResponse, status_code=201)
def follow_trader(payload: FollowTraderRequest, db: Session = Depends(get_db), user=Depends(get_current_user)) -> CopyRelationshipResponse:
    service = CopyTradingService(db)
    try:
        relation = service.follow_trader(user.id, payload)
        asyncio.create_task(
            service.publish_copy_event(
                "copy_follow",
                {
                    "relationship_id": relation.id,
                    "follower_user_id": relation.follower_user_id,
                    "source_user_id": relation.source_user_id,
                },
            )
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    return _to_response(relation)


@router.post("/unfollow/{source_user_id}", response_model=CopyRelationshipResponse)
def unfollow_trader(source_user_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)) -> CopyRelationshipResponse:
    service = CopyTradingService(db)
    try:
        relation = service.unfollow_trader(user.id, source_user_id)
        asyncio.create_task(service.publish_copy_event("copy_unfollow", {"relationship_id": relation.id}))
    except ValueError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    return _to_response(relation)


@router.post("/relationships/{relationship_id}/stop", response_model=CopyRelationshipResponse)
def stop_copying(relationship_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)) -> CopyRelationshipResponse:
    service = CopyTradingService(db)
    try:
        relation = service.stop_copying(relationship_id, user.id)
        asyncio.create_task(service.publish_copy_event("copy_stop", {"relationship_id": relation.id}))
    except ValueError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    return _to_response(relation)


@router.patch("/relationships/{relationship_id}", response_model=CopyRelationshipResponse)
def update_settings(
    relationship_id: int,
    payload: UpdateCopySettingsRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> CopyRelationshipResponse:
    service = CopyTradingService(db)
    try:
        relation = service.update_settings(relationship_id, user.id, payload)
        asyncio.create_task(service.publish_copy_event("copy_settings", {"relationship_id": relation.id}))
    except ValueError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    return _to_response(relation)


@router.get("/relationships", response_model=list[CopyRelationshipResponse])
def relationships(db: Session = Depends(get_db), user=Depends(get_current_user)) -> list[CopyRelationshipResponse]:
    service = CopyTradingService(db)
    relations = service.list_relationships(user.id)
    return [_to_response(item) for item in relations]


@router.get("/trades", response_model=list[CopiedTradeResponse])
def copied_trades(db: Session = Depends(get_db), user=Depends(get_current_user)) -> list[CopiedTradeResponse]:
    service = CopyTradingService(db)
    rows = service.list_copied_trades(user.id)
    return [CopiedTradeResponse.model_validate(item, from_attributes=True) for item in rows]


@router.get("/relationships/{relationship_id}/performance", response_model=list[CopyPerformanceSnapshotResponse])
def copy_performance(relationship_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)) -> list[CopyPerformanceSnapshotResponse]:
    service = CopyTradingService(db)
    rows = service.list_snapshots(relationship_id, user.id)
    return [CopyPerformanceSnapshotResponse.model_validate(item, from_attributes=True) for item in rows]


@router.get("/portfolio", response_model=CopyPortfolioSummary)
def portfolio_summary(db: Session = Depends(get_db), user=Depends(get_current_user)) -> CopyPortfolioSummary:
    service = CopyTradingService(db)
    summary = service.portfolio_summary(user.id)
    return CopyPortfolioSummary.model_validate(summary)


def _to_response(relation) -> CopyRelationshipResponse:
    return CopyRelationshipResponse(
        id=relation.id,
        follower_user_id=relation.follower_user_id,
        source_user_id=relation.source_user_id,
        source_type=relation.source_type,
        status=relation.status,
        allocation_pct=relation.allocation_pct,
        max_loss_pct=relation.max_loss_pct,
        risk_level=relation.risk_level,
        auto_stop_threshold=relation.auto_stop_threshold,
        max_follower_exposure=relation.max_follower_exposure,
        trader_commission_bps=relation.trader_commission_bps,
        platform_fee_bps=relation.platform_fee_bps,
        allowed_market_ids=list(relation.allowed_markets_json or []),
    )
