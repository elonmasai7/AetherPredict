from pydantic import BaseModel


class InsuranceQuoteResponse(BaseModel):
    position_id: str
    premium_bps: int
    coverage_amount: float
    eligible_risks: list[str]


class InsuranceClaimResponse(BaseModel):
    claim_id: str
    status: str
    payout_estimate: float
