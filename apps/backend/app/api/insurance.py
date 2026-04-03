from fastapi import APIRouter, Query

from app.schemas.insurance import InsuranceClaimResponse, InsuranceQuoteResponse

router = APIRouter(prefix="/insurance", tags=["insurance"])


@router.get("/quote", response_model=InsuranceQuoteResponse)
def quote(position_id: str = Query(...)) -> InsuranceQuoteResponse:
    return InsuranceQuoteResponse(
        position_id=position_id,
        premium_bps=180,
        coverage_amount=1250,
        eligible_risks=["SMART_CONTRACT_FAILURE", "ORACLE_DISPUTE", "INVALID_RESOLUTION"],
    )


@router.post("/claim", response_model=InsuranceClaimResponse)
def claim(position_id: str = Query(...)) -> InsuranceClaimResponse:
    return InsuranceClaimResponse(
        claim_id=f"claim-{position_id}",
        status="UNDER_REVIEW",
        payout_estimate=820,
    )
