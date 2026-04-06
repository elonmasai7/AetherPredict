from pydantic import BaseModel


class BlockchainTxRequest(BaseModel):
    market_address: str
    wallet_address: str
    amount_wei: int = 0
    yes_side: bool = True
    evidence_uri: str | None = None


class BlockchainCreateMarketRequest(BaseModel):
    wallet_address: str
    title: str
    description: str
    oracle_source: str
    expiry: int
    creation_fee_wei: int


class BlockchainTxResponse(BaseModel):
    tx: dict
