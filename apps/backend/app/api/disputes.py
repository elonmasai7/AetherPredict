from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, UploadFile

from app.db.session import get_db
from app.models.entities import Dispute
from app.schemas.dispute import DisputeResponse

router = APIRouter(prefix="/disputes", tags=["disputes"])


@router.get("", response_model=list[DisputeResponse])
def list_disputes(db: Session = Depends(get_db)) -> list[DisputeResponse]:
    disputes = db.scalars(select(Dispute).order_by(Dispute.id.desc())).all()
    return [DisputeResponse.model_validate(dispute, from_attributes=True) for dispute in disputes]


@router.post("")
async def submit_dispute(market_id: int, evidence: UploadFile, db: Session = Depends(get_db)):
    dispute = Dispute(
        market_id=market_id,
        evidence_url=f"uploads/{evidence.filename}",
        ai_summary="Pending AI summarization",
        status="OPEN",
        juror_votes_yes=0,
        juror_votes_no=0,
    )
    db.add(dispute)
    db.commit()
    return {
        "message": "Dispute submitted",
        "market_id": market_id,
        "filename": evidence.filename,
        "status": "OPEN",
    }
