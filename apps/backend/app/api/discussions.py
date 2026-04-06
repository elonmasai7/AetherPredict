from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import DiscussionComment
from app.schemas.discussion import CommentRequest, CommentResponse
from app.services.auth_service import get_current_user

router = APIRouter(tags=["discussions"])


@router.post("/market/comment", response_model=CommentResponse)
def post_comment(
    payload: CommentRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> CommentResponse:
    comment = DiscussionComment(
        user_id=user.id,
        market_id=payload.market_id,
        author=payload.author or user.display_name or user.email,
        content=payload.content,
        evidence_url=payload.evidence_url,
        parent_id=payload.parent_id,
        upvotes=0,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return CommentResponse.model_validate(comment, from_attributes=True)


@router.get("/market/comments", response_model=list[CommentResponse])
def get_comments(market_id: int = Query(...), db: Session = Depends(get_db)) -> list[CommentResponse]:
    comments = db.scalars(
        select(DiscussionComment).where(DiscussionComment.market_id == market_id).order_by(DiscussionComment.created_at.desc())
    ).all()
    return [CommentResponse.model_validate(item, from_attributes=True) for item in comments]
