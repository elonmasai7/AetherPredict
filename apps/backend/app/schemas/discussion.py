from pydantic import BaseModel


class CommentRequest(BaseModel):
    market_id: int
    author: str
    content: str
    evidence_url: str | None = None
    parent_id: int | None = None


class CommentResponse(BaseModel):
    id: int
    market_id: int
    author: str
    content: str
    evidence_url: str | None = None
    parent_id: int | None = None
    upvotes: int
