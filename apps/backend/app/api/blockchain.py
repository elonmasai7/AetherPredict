from fastapi import APIRouter, Depends

from app.schemas.blockchain import BlockchainCreateMarketRequest, BlockchainTxRequest, BlockchainTxResponse
from app.services.blockchain_service import BlockchainService
from app.services.auth_service import get_optional_user

router = APIRouter(prefix="/blockchain", tags=["blockchain"])


def _tx_payload(built):
    return {
        "to": built.to,
        "data": built.data,
        "value": hex(built.value),
        "gas": hex(built.gas) if built.gas else None,
        "gasPrice": hex(built.gas_price) if built.gas_price else None,
        "nonce": hex(built.nonce) if built.nonce is not None else None,
        "chainId": built.chain_id,
    }


@router.post("/buy-yes", response_model=BlockchainTxResponse)
def buy_yes(payload: BlockchainTxRequest, user=Depends(get_optional_user)) -> BlockchainTxResponse:
    chain = BlockchainService()
    built = chain.buy_yes_position(payload.market_address, payload.wallet_address, payload.amount_wei)
    return BlockchainTxResponse(tx=_tx_payload(built))


@router.post("/buy-no", response_model=BlockchainTxResponse)
def buy_no(payload: BlockchainTxRequest, user=Depends(get_optional_user)) -> BlockchainTxResponse:
    chain = BlockchainService()
    built = chain.buy_no_position(payload.market_address, payload.wallet_address, payload.amount_wei)
    return BlockchainTxResponse(tx=_tx_payload(built))


@router.post("/sell", response_model=BlockchainTxResponse)
def sell(payload: BlockchainTxRequest, user=Depends(get_optional_user)) -> BlockchainTxResponse:
    chain = BlockchainService()
    built = chain.sell_position(payload.market_address, payload.wallet_address, payload.yes_side, payload.amount_wei)
    return BlockchainTxResponse(tx=_tx_payload(built))


@router.post("/claim", response_model=BlockchainTxResponse)
def claim(payload: BlockchainTxRequest, user=Depends(get_optional_user)) -> BlockchainTxResponse:
    chain = BlockchainService()
    built = chain.claim_rewards(payload.market_address, payload.wallet_address)
    return BlockchainTxResponse(tx=_tx_payload(built))


@router.post("/dispute", response_model=BlockchainTxResponse)
def dispute(payload: BlockchainTxRequest, user=Depends(get_optional_user)) -> BlockchainTxResponse:
    chain = BlockchainService()
    built = chain.dispute_market(payload.market_address, payload.wallet_address, payload.evidence_uri or "", payload.amount_wei)
    return BlockchainTxResponse(tx=_tx_payload(built))


@router.post("/create-market", response_model=BlockchainTxResponse)
def create_market(payload: BlockchainCreateMarketRequest, user=Depends(get_optional_user)) -> BlockchainTxResponse:
    chain = BlockchainService()
    built = chain.create_market(
        payload.wallet_address,
        payload.title,
        payload.description,
        payload.oracle_source,
        payload.expiry,
        payload.creation_fee_wei,
    )
    return BlockchainTxResponse(tx=_tx_payload(built))
