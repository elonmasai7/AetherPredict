from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, UploadFile

from app.db.session import get_db
from app.models.entities import ChainTransaction, Dispute
from app.schemas.dispute import DisputeHistoryResponse, DisputeResponse
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/disputes", tags=["disputes"])


@router.get("", response_model=list[DisputeResponse])
def list_disputes(db: Session = Depends(get_db)) -> list[DisputeResponse]:
    disputes = db.scalars(select(Dispute).order_by(Dispute.id.desc())).all()
    return [DisputeResponse.model_validate(dispute, from_attributes=True) for dispute in disputes]


@router.get("/history", response_model=list[DisputeHistoryResponse])
def dispute_history(db: Session = Depends(get_db)) -> list[DisputeHistoryResponse]:
    disputes = db.scalars(select(Dispute).order_by(Dispute.id.desc())).all()
    txs = {
        tx.market_id: tx
        for tx in db.scalars(select(ChainTransaction).where(ChainTransaction.tx_type == "DISPUTE")).all()
    }
    history: list[DisputeHistoryResponse] = []
    for dispute in disputes:
        tx = txs.get(dispute.market_id)
        history.append(
            DisputeHistoryResponse(
                id=dispute.id,
                market_id=dispute.market_id,
                status=dispute.status,
                evidence_url=dispute.evidence_url,
                created_at=dispute.created_at,
                tx_hash=tx.tx_hash if tx else None,
                chain_status=tx.status if tx else None,
            )
        )
    return history


@router.post("")
async def submit_dispute(market_id: int, evidence: UploadFile, db: Session = Depends(get_db), user=Depends(get_current_user)):
    dispute = Dispute(
        market_id=market_id,
        user_id=user.id,
        evidence_url=f"uploads/{evidence.filename}",
        ai_summary="Evidence received and queued for analyst review.",
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
