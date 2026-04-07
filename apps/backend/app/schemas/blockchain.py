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


class BlockchainCreateVaultRequest(BaseModel):
    wallet_address: str
    manager_address: str
    collateral_token: str
    title: str
    strategy_description: str
    risk_profile: str
    manager_type: str
    management_fee_bps: int
    performance_fee_bps: int
    share_name: str
    share_symbol: str


class VaultTxRequest(BaseModel):
    vault_address: str
    wallet_address: str
    amount_wei: int = 0
    share_amount_wei: int = 0
    market_address: str | None = None
    action: str | None = None


class Erc20ApproveRequest(BaseModel):
    token_address: str
    wallet_address: str
    spender: str
    amount_wei: int


class BlockchainTxResponse(BaseModel):
    tx: dict
