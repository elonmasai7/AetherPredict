from datetime import datetime

from pydantic import BaseModel


class DisputeResponse(BaseModel):
    id: int
    market_id: int
    status: str
    evidence_url: str
    ai_summary: str
    juror_votes_yes: int
    juror_votes_no: int


class DisputeHistoryResponse(BaseModel):
    id: int
    market_id: int
    status: str
    evidence_url: str
    created_at: datetime
    tx_hash: str | None = None
    chain_status: str | None = None
