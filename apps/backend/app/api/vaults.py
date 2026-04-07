import asyncio

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import ChainTransaction, Market, VaultTrade
from app.schemas.vault import (
    ExecuteVaultStrategyRequest,
    ExecuteVaultStrategyResponse,
    VaultAutoExecuteUpdateRequest,
    VaultCreateRequest,
    VaultPerformancePoint,
    VaultResponse,
    VaultSubscriptionRequest,
    VaultTradeResponse,
)
from app.services.auth_service import get_current_user, get_optional_user, get_or_create_wallet_user
from app.services.strategy_vault_service import StrategyVaultService

router = APIRouter(prefix="/vaults", tags=["vaults"])


@router.get("", response_model=list[VaultResponse])
def list_vaults(category: str | None = None, db: Session = Depends(get_db)) -> list[VaultResponse]:
    service = StrategyVaultService(db)
    vaults = service.list_vaults(category=category)
    return [_to_response(db, vault) for vault in vaults]


@router.post("", response_model=VaultResponse, status_code=201)
def create_vault(payload: VaultCreateRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> VaultResponse:
    service = StrategyVaultService(db)
    try:
        vault = service.create_vault(user.id if user else None, payload)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    return _to_response(db, vault)


@router.get("/{vault_id}", response_model=VaultResponse)
def get_vault(vault_id: int, db: Session = Depends(get_db)) -> VaultResponse:
    service = StrategyVaultService(db)
    vault = service.get_vault(vault_id)
    if vault is None:
        raise HTTPException(status_code=404, detail="Vault not found")
    return _to_response(db, vault)


@router.post("/{vault_id}/pause", response_model=VaultResponse)
def pause_vault(vault_id: int, payload: dict, db: Session = Depends(get_db), _=Depends(get_current_user)) -> VaultResponse:
    service = StrategyVaultService(db)
    paused = bool(payload.get("paused", True))
    try:
        vault = service.pause_vault(vault_id, paused=paused)
        asyncio.create_task(service.publish_vault_event("vault_paused", {"vault_id": vault.id, "paused": paused}))
    except ValueError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    return _to_response(db, vault)


@router.post("/{vault_id}/archive", response_model=VaultResponse)
def archive_vault(vault_id: int, db: Session = Depends(get_db), _=Depends(get_current_user)) -> VaultResponse:
    service = StrategyVaultService(db)
    try:
        vault = service.archive_vault(vault_id)
        asyncio.create_task(service.publish_vault_event("vault_archived", {"vault_id": vault.id}))
    except ValueError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    return _to_response(db, vault)


@router.post("/{vault_id}/auto-execute", response_model=VaultResponse)
def update_auto_execute(
    vault_id: int,
    payload: VaultAutoExecuteUpdateRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> VaultResponse:
    service = StrategyVaultService(db)
    vault = service.get_vault(vault_id)
    if vault is None:
        raise HTTPException(status_code=404, detail="Vault not found")
    if not user or user.role not in {"admin", "manager"}:
        raise HTTPException(status_code=403, detail="Not authorized to update auto execute")
    vault.auto_execute_enabled = payload.auto_execute_enabled
    db.commit()
    asyncio.create_task(
        service.publish_vault_event(
            "vault_auto_execute_updated",
            {"vault_id": vault.id, "auto_execute_enabled": vault.auto_execute_enabled},
        )
    )
    return _to_response(db, vault)


@router.post("/deposit", response_model=dict, status_code=201)
def deposit(payload: VaultSubscriptionRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> dict:
    if user is None:
        user = get_or_create_wallet_user(db, payload.wallet_address)
    service = StrategyVaultService(db)
    try:
        subscription = service.deposit(payload.vault_id, user.id, payload.wallet_address, payload.amount)
        asyncio.create_task(
            service.publish_vault_event(
                "vault_deposit",
                {
                    "vault_id": payload.vault_id,
                    "user_id": user.id,
                    "amount": payload.amount,
                    "share_balance": subscription.share_balance,
                },
            )
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    response = {
        "vault_id": payload.vault_id,
        "user_id": user.id,
        "deposited_amount": subscription.deposited_amount,
        "share_balance": subscription.share_balance,
        "status": subscription.status,
    }
    vault = service.get_vault(payload.vault_id)
    if vault and vault.on_chain_address:
        tx = ChainTransaction(
            user_id=user.id,
            market_id=None,
            tx_type="VAULT_DEPOSIT",
            status="AWAITING_WALLET_SIGNATURE",
            metadata_json={
                "vault_id": vault.id,
                "vault_address": vault.on_chain_address,
                "amount": payload.amount,
                "wallet_address": payload.wallet_address,
            },
        )
        db.add(tx)
        db.commit()
        response["chain_tx_id"] = tx.id
    return response


@router.post("/withdraw", response_model=dict)
def withdraw(payload: VaultSubscriptionRequest, db: Session = Depends(get_db), user=Depends(get_optional_user)) -> dict:
    if user is None:
        user = get_or_create_wallet_user(db, payload.wallet_address)
    service = StrategyVaultService(db)
    try:
        subscription = service.withdraw(payload.vault_id, user.id, payload.amount)
        asyncio.create_task(
            service.publish_vault_event(
                "vault_withdraw",
                {
                    "vault_id": payload.vault_id,
                    "user_id": user.id,
                    "amount": payload.amount,
                    "share_balance": subscription.share_balance,
                },
            )
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    response = {
        "vault_id": payload.vault_id,
        "user_id": user.id,
        "deposited_amount": subscription.deposited_amount,
        "share_balance": subscription.share_balance,
        "status": subscription.status,
    }
    vault = service.get_vault(payload.vault_id)
    if vault and vault.on_chain_address:
        tx = ChainTransaction(
            user_id=user.id,
            market_id=None,
            tx_type="VAULT_WITHDRAW",
            status="AWAITING_WALLET_SIGNATURE",
            metadata_json={
                "vault_id": vault.id,
                "vault_address": vault.on_chain_address,
                "amount": payload.amount,
                "wallet_address": payload.wallet_address,
            },
        )
        db.add(tx)
        db.commit()
        response["chain_tx_id"] = tx.id
    return response


@router.post("/{vault_id}/execute-trade", response_model=VaultTradeResponse, status_code=201)
def execute_trade(
    vault_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> VaultTradeResponse:
    service = StrategyVaultService(db)
    try:
        trade = service.execute_trade(
            vault_id=vault_id,
            market_id=int(payload["market_id"]),
            side=str(payload["side"]),
            allocation=float(payload.get("allocation", 0)),
            confidence=float(payload.get("confidence", 0)),
            reasoning=str(payload.get("reasoning", "Manual vault execution")),
            tx_hash=payload.get("tx_hash"),
        )
        asyncio.create_task(
            service.publish_vault_event(
                "vault_trade",
                {
                    "vault_id": vault_id,
                    "trade_id": trade.id,
                    "market_id": trade.market_id,
                    "side": trade.side,
                    "allocation": trade.allocation,
                    "amount": trade.amount,
                },
            )
        )
    except (ValueError, KeyError) as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    chain_tx_id: int | None = None
    vault = service.get_vault(vault_id)
    market = db.scalar(select(Market).where(Market.id == trade.market_id))
    if (
        vault
        and vault.on_chain_address
        and market
        and market.on_chain_address
        and user.wallet_address
    ):
        amount_wei = service._amount_to_wei(trade.amount, vault.collateral_token_decimals)
        tx = ChainTransaction(
            user_id=user.id,
            market_id=market.id,
            tx_type="VAULT_EXECUTE",
            status="AWAITING_WALLET_SIGNATURE",
            metadata_json={
                "vault_id": vault.id,
                "vault_address": vault.on_chain_address,
                "market_id": market.id,
                "market_address": market.on_chain_address,
                "action": trade.side,
                "amount_wei": amount_wei,
                "wallet_address": user.wallet_address,
            },
        )
        db.add(tx)
        db.commit()
        chain_tx_id = tx.id
        asyncio.create_task(
            service.publish_vault_event(
                "vault_execute_chain_tx",
                {"vault_id": vault.id, "trade_id": trade.id, "chain_tx_id": chain_tx_id},
            )
        )

    response = VaultTradeResponse.model_validate(trade, from_attributes=True)
    response.chain_tx_id = chain_tx_id
    return response


@router.post("/{vault_id}/rebalance", response_model=VaultResponse)
def rebalance(vault_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)) -> VaultResponse:
    service = StrategyVaultService(db)
    try:
        vault = service.rebalance(vault_id)
        asyncio.create_task(service.publish_vault_event("vault_rebalance", {"vault_id": vault_id}))
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    if vault.on_chain_address and user.wallet_address:
        tx = ChainTransaction(
            user_id=user.id,
            market_id=None,
            tx_type="VAULT_REBALANCE",
            status="AWAITING_WALLET_SIGNATURE",
            metadata_json={
                "vault_id": vault.id,
                "vault_address": vault.on_chain_address,
                "wallet_address": user.wallet_address,
            },
        )
        db.add(tx)
        db.commit()
        asyncio.create_task(
            service.publish_vault_event(
                "vault_rebalance_chain_tx",
                {"vault_id": vault.id, "chain_tx_id": tx.id},
            )
        )
    return _to_response(db, vault)


@router.post("/{vault_id}/distribute-returns")
def distribute_returns(
    vault_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
) -> dict:
    service = StrategyVaultService(db)
    try:
        gross_return = float(payload.get("gross_return", 0))
        result = service.distribute_returns(vault_id, gross_return)
        asyncio.create_task(service.publish_vault_event("vault_returns", {"vault_id": vault_id, **result}))
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    vault = service.get_vault(vault_id)
    if vault and vault.on_chain_address and user.wallet_address:
        tx = ChainTransaction(
            user_id=user.id,
            market_id=None,
            tx_type="VAULT_DISTRIBUTE",
            status="AWAITING_WALLET_SIGNATURE",
            metadata_json={
                "vault_id": vault.id,
                "vault_address": vault.on_chain_address,
                "gross_return_wei": service._amount_to_wei(gross_return, vault.collateral_token_decimals),
                "wallet_address": user.wallet_address,
            },
        )
        db.add(tx)
        db.commit()
        result["chain_tx_id"] = tx.id
        asyncio.create_task(
            service.publish_vault_event(
                "vault_distribute_chain_tx",
                {"vault_id": vault.id, "chain_tx_id": tx.id},
            )
        )
    return result


@router.get("/{vault_id}/trades", response_model=list[VaultTradeResponse])
def vault_trades(vault_id: int, db: Session = Depends(get_db)) -> list[VaultTradeResponse]:
    rows = db.scalars(select(VaultTrade).where(VaultTrade.vault_id == vault_id).order_by(VaultTrade.created_at.desc()).limit(200)).all()
    return [VaultTradeResponse.model_validate(item, from_attributes=True) for item in rows]


@router.get("/{vault_id}/performance", response_model=list[VaultPerformancePoint])
def vault_performance(vault_id: int, db: Session = Depends(get_db)) -> list[VaultPerformancePoint]:
    service = StrategyVaultService(db)
    rows = service.get_performance(vault_id)
    return [VaultPerformancePoint.model_validate(item, from_attributes=True) for item in rows]


@router.post("/execute-strategy", response_model=ExecuteVaultStrategyResponse)
def execute_vault_strategy(payload: ExecuteVaultStrategyRequest, db: Session = Depends(get_db)) -> ExecuteVaultStrategyResponse:
    service = StrategyVaultService(db)
    try:
        auto_execute = payload.portfolio_state.get("auto_execute")
        if auto_execute:
            vault_id = int(payload.vault_id)
            if not service.is_auto_execute_allowed(vault_id):
                raise HTTPException(status_code=403, detail="Vault not allowlisted for auto execution")
        return service.execute_strategy(payload)
    except ValueError as error:
        raise HTTPException(status_code=403, detail=str(error)) from error


def _to_response(db: Session, vault) -> VaultResponse:
    market_ids = [item.market_id for item in vault.markets]
    markets = db.scalars(select(Market).where(Market.id.in_(market_ids))).all() if market_ids else []
    return VaultResponse(
        id=vault.id,
        title=vault.title,
        slug=vault.slug,
        strategy_description=vault.strategy_description,
        risk_profile=vault.risk_profile,
        collateral_token_decimals=vault.collateral_token_decimals,
        auto_execute_enabled=vault.auto_execute_enabled,
        target_markets=[item.slug for item in markets] if markets else list(vault.target_markets_json),
        performance_history=list(vault.performance_history_json),
        current_allocation=dict(vault.current_allocation_json),
        ai_confidence_score=vault.ai_confidence_score,
        manager_type=vault.manager_type,
        roi_7d=vault.roi_7d,
        roi_30d=vault.roi_30d,
        win_rate=vault.win_rate,
        volatility=vault.volatility,
        active_subscribers=vault.active_subscribers,
        total_aum=vault.total_aum,
        status=vault.status,
    )
