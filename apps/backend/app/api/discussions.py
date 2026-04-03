from fastapi import APIRouter, Query

from app.schemas.discussion import CommentRequest, CommentResponse
from app.services.platform_data import sample_discussions

router = APIRouter(tags=["discussions"])

_comments = sample_discussions()


@router.post("/market/comment", response_model=CommentResponse)
def post_comment(payload: CommentRequest) -> CommentResponse:
    comment = {
        "id": len(_comments) + 1,
        "market_id": payload.market_id,
        "author": payload.author,
        "content": payload.content,
        "evidence_url": payload.evidence_url,
        "parent_id": payload.parent_id,
        "upvotes": 0,
    }
    _comments.append(comment)
    return CommentResponse(**comment)


@router.get("/market/comments", response_model=list[CommentResponse])
def get_comments(market_id: int = Query(...)) -> list[CommentResponse]:
    return [CommentResponse(**item) for item in _comments if item["market_id"] == market_id]
