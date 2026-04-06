from collections import defaultdict
import httpx

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import Market, PortfolioPosition, TradeOrder, WalletBalance
from app.schemas.hedge import AutoHedgeRequest, AutoHedgeResponse
from app.schemas.portfolio import PositionResponse
from app.schemas.risk import ExposureSlice, PerformancePoint, PortfolioRiskResponse
from app.services.auth_service import get_current_user, get_optional_user
from app.services.blockchain_service import BlockchainService
from app.core.config import settings

router = APIRouter(prefix="/portfolio", tags=["portfolio"])


@router.get("/positions", response_model=list[PositionResponse])
def positions(db: Session = Depends(get_db), user=Depends(get_optional_user)) -> list[PositionResponse]:
    if user is None:
        return []
    rows = db.scalars(
        select(PortfolioPosition)
        .where(PortfolioPosition.user_id == user.id)
        .order_by(PortfolioPosition.opened_at.desc())
    ).all()
    markets = {market.id: market.title for market in db.scalars(select(Market)).all()}
    return [
        PositionResponse(
            market_id=row.market_id,
            market_title=markets.get(row.market_id, "Unknown market"),
            side=row.side,
            size=row.size,
            avg_price=row.avg_price,
            mark_price=row.mark_price,
            pnl=row.pnl,
            realized_pnl=row.realized_pnl,
            unrealized_pnl=row.unrealized_pnl,
            status=row.status,
            opened_at=row.opened_at,
        )
        for row in rows
    ]


@router.get("/risk", response_model=PortfolioRiskResponse)
def risk(db: Session = Depends(get_db), user=Depends(get_optional_user)) -> PortfolioRiskResponse:
    if user is None:
        return PortfolioRiskResponse(
            total_exposure=0,
            risk_score="LOW",
            max_loss=0,
            var_95=0,
            volatility_score=0,
            confidence_weighted_risk=0,
        )
    positions_list = db.scalars(select(PortfolioPosition).where(PortfolioPosition.user_id == user.id)).all()
    balances = db.scalars(select(WalletBalance).where(WalletBalance.user_id == user.id)).all()
    total_exposure = sum(position.size * position.mark_price for position in positions_list)
    wallet_value = sum(balance.value_usd for balance in balances)
    gross = total_exposure + wallet_value
    max_loss = round(total_exposure * 0.31, 2)
    var_95 = round(total_exposure * 0.24, 2)
    volatility_score = round(sum(abs(position.mark_price - position.avg_price) for position in positions_list) * 100, 2)
    confidence_weighted = round(total_exposure * 0.68, 2)
    risk_score = "HIGH" if gross > 10000 else "MEDIUM" if gross > 1000 else "LOW"
    return PortfolioRiskResponse(
        total_exposure=round(gross, 2),
        risk_score=risk_score,
        max_loss=max_loss,
        var_95=var_95,
        volatility_score=volatility_score,
        confidence_weighted_risk=confidence_weighted,
    )


@router.get("/exposure", response_model=list[ExposureSlice])
def exposure(db: Session = Depends(get_db), user=Depends(get_optional_user)) -> list[ExposureSlice]:
    if user is None:
        return []
    markets = {market.id: market for market in db.scalars(select(Market)).all()}
    positions_list = db.scalars(select(PortfolioPosition).where(PortfolioPosition.user_id == user.id)).all()
    totals = defaultdict(float)
    total_value = 0.0
    for position in positions_list:
        market = markets.get(position.market_id)
        category = market.category if market else "Other"
        value = position.size * position.mark_price
        totals[category] += value
        total_value += value
    if total_value <= 0:
        return []
    return [ExposureSlice(category=category, allocation=round((value / total_value) * 100, 2)) for category, value in totals.items()]


@router.get("/performance", response_model=list[PerformancePoint])
def performance(db: Session = Depends(get_db), user=Depends(get_optional_user)) -> list[PerformancePoint]:
    if user is None:
        return []
    trades = db.scalars(select(TradeOrder).where(TradeOrder.user_id == user.id).order_by(TradeOrder.created_at.asc())).all()
    if not trades:
        return []
    cumulative = 0.0
    points: list[PerformancePoint] = []
    for trade in trades[-10:]:
        cumulative += trade.collateral_amount * (trade.price if trade.side == "YES" else (1 - trade.price))
        points.append(PerformancePoint(label=trade.created_at.strftime("%m-%d"), pnl=round(cumulative, 2)))
    return points


@router.post("/auto-hedge", response_model=AutoHedgeResponse)
def auto_hedge(payload: AutoHedgeRequest, db: Session = Depends(get_db), user=Depends(get_current_user)) -> AutoHedgeResponse:
    hedge_ratio = 0.2 if payload.enable else 0.0
    volatility = 0.0
    market = db.scalar(select(Market).where(Market.id == int(payload.market_id))) if str(payload.market_id).isdigit() else None
    if market is not None:
        volatility = abs(market.yes_probability - market.no_probability)
    protection_score = round((hedge_ratio * 50) + (volatility * 50))
    estimated_loss_reduction = round(payload.position_size * hedge_ratio * 0.35, 2)
    return AutoHedgeResponse(
        enabled=payload.enable,
        hedge_ratio=hedge_ratio,
        protection_score=protection_score,
        estimated_loss_reduction=estimated_loss_reduction,
    )


@router.get("/balances")
def wallet_balances(db: Session = Depends(get_db), user=Depends(get_optional_user)) -> list[dict]:
    if user is None or not user.wallet_address:
        return []
    chain = BlockchainService()
    native_balance = chain.get_native_balance(user.wallet_address)
    balance_row = db.scalar(
        select(WalletBalance).where(
            WalletBalance.user_id == user.id,
            WalletBalance.wallet_address == user.wallet_address,
            WalletBalance.symbol == "HSK",
        )
    )
    if balance_row is None:
        balance_row = WalletBalance(
            user_id=user.id,
            wallet_address=user.wallet_address,
            network="hashkey",
            symbol="HSK",
            balance=native_balance,
            price_usd=0,
            value_usd=0,
        )
        db.add(balance_row)
    else:
        balance_row.balance = native_balance

    token_rows = []
    prices = {}
    try:
        response = httpx.get(
            f"{settings.coingecko_api_url}/simple/price",
            params={"ids": "usd-coin,tether", "vs_currencies": "usd"},
            timeout=10,
        )
        if response.status_code == 200:
            prices = response.json()
    except Exception:
        prices = {}

    for symbol, address in (("USDC", settings.hashkey_usdc_address), ("USDT", settings.hashkey_usdt_address)):
        if not address:
            continue
        token_balance, _ = chain.get_erc20_balance(address, user.wallet_address)
        price_id = "usd-coin" if symbol == "USDC" else "tether"
        price = float(prices.get(price_id, {}).get("usd", 1.0)) if prices else 1.0
        row = db.scalar(
            select(WalletBalance).where(
                WalletBalance.user_id == user.id,
                WalletBalance.wallet_address == user.wallet_address,
                WalletBalance.symbol == symbol,
            )
        )
        if row is None:
            row = WalletBalance(
                user_id=user.id,
                wallet_address=user.wallet_address,
                network="hashkey",
                symbol=symbol,
                balance=token_balance,
                price_usd=price,
                value_usd=token_balance * price,
            )
            db.add(row)
        else:
            row.balance = token_balance
            row.price_usd = price
            row.value_usd = token_balance * price
        token_rows.append(row)
    db.commit()
    rows = db.scalars(select(WalletBalance).where(WalletBalance.user_id == user.id)).all()
    return [
        {
            "symbol": row.symbol,
            "balance": row.balance,
            "network": row.network,
            "price_usd": row.price_usd,
            "value_usd": row.value_usd,
        }
        for row in rows
    ]
