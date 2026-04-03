from fastapi import APIRouter, UploadFile

router = APIRouter(prefix="/disputes", tags=["disputes"])


@router.post("")
async def submit_dispute(market_id: int, evidence: UploadFile):
    return {
        "message": "Dispute submitted",
        "market_id": market_id,
        "filename": evidence.filename,
        "status": "OPEN",
    }
