from datetime import datetime

from pydantic import BaseModel


class CreateTradeRequest(BaseModel):
    market_id: int
    side: str
    collateral_amount: float
    price: float
    order_type: str = "MARKET"
    wallet_address: str
    signed_payload: str | None = None


class PrepareTradeRequest(BaseModel):
    market_id: int
    side: str
    collateral_amount: float
    wallet_address: str


class PrepareTradeResponse(BaseModel):
    trade_id: int
    tx: dict
    liquidity_preview: dict | None = None


class TradeResponse(BaseModel):
    id: int
    market_id: int
    side: str
    collateral_amount: float
    price: float
    shares: float
    status: str
    tx_hash: str | None = None
    explorer_url: str | None = None
    gas_estimate: float | None = None
    gas_fee_native: float | None = None
    failure_reason: str | None = None
    liquidity_preview: dict | None = None
    created_at: datetime
