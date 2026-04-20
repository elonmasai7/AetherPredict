from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
from datetime import UTC, datetime
from math import exp

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import Market, TradeOrder, VaultSubscription


@dataclass
class LiquiditySnapshot:
    summary: dict
    detail: dict


class LiquidityIntelligenceService:
    def __init__(self, db: Session):
        self.db = db

    def build_market_snapshot(self, market: Market) -> LiquiditySnapshot:
        trades = self.db.scalars(
            select(TradeOrder)
            .where(TradeOrder.market_id == market.id)
            .order_by(TradeOrder.created_at.desc())
            .limit(250)
        ).all()
        subscriptions = self.db.scalars(select(VaultSubscription)).all()
        return self._build_snapshot(market, trades, subscriptions)

    def build_dashboard(self) -> dict:
        markets = self.db.scalars(select(Market).order_by(Market.updated_at.desc())).all()
        subscriptions = self.db.scalars(select(VaultSubscription)).all()
        rows: list[dict] = []
        for market in markets:
            trades = self.db.scalars(
                select(TradeOrder)
                .where(TradeOrder.market_id == market.id)
                .order_by(TradeOrder.created_at.desc())
                .limit(250)
            ).all()
            snapshot = self._build_snapshot(market, trades, subscriptions)
            rows.append(
                {
                    "market_id": market.id,
                    "title": market.title,
                    "category": market.category,
                    "spread_cents": snapshot.summary["spread_width_cents"],
                    "liquidity_label": snapshot.summary["liquidity_label"],
                    "liquidity_score": snapshot.detail["liquidity_score"],
                    "risk_label": snapshot.detail["risk"]["label"],
                    "risk_score": snapshot.detail["risk"]["score"],
                    "yes_depth": snapshot.detail["depth"]["yes_depth_total"],
                    "no_depth": snapshot.detail["depth"]["no_depth_total"],
                    "imbalance_ratio": snapshot.detail["depth"]["imbalance_ratio"],
                    "top_lp_share_pct": snapshot.detail["concentration"]["top_providers_share_pct"],
                    "slippage_small_pct": snapshot.detail["retail"]["micro_trade_preview"]["slippage_pct"],
                    "event_profile": snapshot.detail["event_driven"]["profile"],
                    "shock_state": snapshot.detail["information_shock"]["status"],
                }
            )

        most_liquid = sorted(rows, key=lambda row: (-row["liquidity_score"], row["spread_cents"]))[:5]
        least_liquid = sorted(rows, key=lambda row: (row["liquidity_score"], -row["spread_cents"]))[:5]
        spread_leaderboard = sorted(rows, key=lambda row: (row["spread_cents"], -row["yes_depth"]))[:8]
        slippage_heatmap = [
            {
                "market_id": row["market_id"],
                "title": row["title"],
                "small_ticket_slippage_pct": row["slippage_small_pct"],
                "risk_label": row["risk_label"],
            }
            for row in sorted(rows, key=lambda row: row["slippage_small_pct"], reverse=True)[:8]
        ]
        lp_distribution = [
            {
                "market_id": row["market_id"],
                "title": row["title"],
                "top_lp_share_pct": row["top_lp_share_pct"],
                "decentralization_index": round(max(0.0, 100 - row["top_lp_share_pct"] * 0.9), 1),
            }
            for row in sorted(rows, key=lambda row: row["top_lp_share_pct"], reverse=True)[:8]
        ]
        return {
            "generated_at": datetime.now(UTC).isoformat(),
            "market_count": len(rows),
            "market_rankings": sorted(rows, key=lambda row: (-row["liquidity_score"], row["risk_score"])),
            "spread_leaderboard": spread_leaderboard,
            "most_liquid_markets": most_liquid,
            "least_liquid_markets": least_liquid,
            "lp_distribution": lp_distribution,
            "slippage_heatmap": slippage_heatmap,
        }

    def build_slippage_preview(self, market: Market, side: str, collateral_amount: float) -> dict:
        snapshot = self.build_market_snapshot(market)
        detail = snapshot.detail
        side_upper = side.upper()
        yes_depth = detail["depth"]["yes_depth_total"]
        no_depth = detail["depth"]["no_depth_total"]
        pool_depth = yes_depth if side_upper == "YES" else no_depth
        reference_price = detail["spread"]["best_yes_ask"] if side_upper == "YES" else detail["spread"]["implied_no_ask"]
        if side_upper == "NO":
            reference_price = max(0.01, min(0.99, reference_price))
        slippage_pct = self._slippage_pct(collateral_amount, pool_depth, detail["risk"]["score"])
        execution_price = min(0.99, max(0.01, reference_price * (1 + slippage_pct / 100)))
        return {
            "side": side_upper,
            "collateral_amount": round(collateral_amount, 2),
            "expected_execution_price": round(execution_price, 4),
            "slippage_pct": round(slippage_pct, 2),
            "price_impact_pct": round(slippage_pct * 0.82, 2),
            "warning": "Elevated price impact. Consider reducing size."
            if slippage_pct >= 2.5
            else None,
        }

    def _build_snapshot(
        self,
        market: Market,
        trades: list[TradeOrder],
        subscriptions: list[VaultSubscription],
    ) -> LiquiditySnapshot:
        now = datetime.now(UTC)
        expiry = market.expiry_at.replace(tzinfo=UTC) if market.expiry_at.tzinfo is None else market.expiry_at.astimezone(UTC)
        hours_to_expiry = max((expiry - now).total_seconds() / 3600, 0)
        event_profile = self._event_profile(market)
        volatility = self._volatility_score(market, trades)
        spread_width_cents = self._spread_width_cents(market, hours_to_expiry, volatility, event_profile["support_score"])
        half_spread = spread_width_cents / 200
        best_yes_bid = round(max(0.01, market.yes_probability - half_spread), 4)
        best_yes_ask = round(min(0.99, market.yes_probability + half_spread), 4)
        implied_no_bid = round(max(0.01, 1 - best_yes_ask), 4)
        implied_no_ask = round(min(0.99, 1 - best_yes_bid), 4)
        depth = self._depth_profile(market, spread_width_cents, event_profile["support_score"], volatility)
        concentration = self._concentration_profile(market, trades, subscriptions)
        shock = self._information_shock(market, volatility, trades)
        expiry_profile = self._expiry_profile(hours_to_expiry, spread_width_cents)
        risk = self._risk_profile(
            spread_width_cents=spread_width_cents,
            depth_score=depth["depth_score"],
            concentration_score=concentration["concentration_score"],
            volatility=volatility,
            hours_to_expiry=hours_to_expiry,
            shock_active=shock["status"] != "Stable",
        )
        market_maker = self._market_maker_profile(
            market=market,
            spread_width_cents=spread_width_cents,
            volatility=volatility,
            event_profile=event_profile,
            hours_to_expiry=hours_to_expiry,
            shock=shock,
            imbalance_ratio=depth["imbalance_ratio"],
        )
        retail = self._retail_profile(
            market=market,
            risk_score=risk["score"],
            yes_depth=depth["yes_depth_total"],
            no_depth=depth["no_depth_total"],
            best_yes_ask=best_yes_ask,
            implied_no_ask=implied_no_ask,
        )
        summary = {
            "best_yes_bid": best_yes_bid,
            "best_yes_ask": best_yes_ask,
            "implied_no_spread": {
                "bid": implied_no_bid,
                "ask": implied_no_ask,
            },
            "spread_width_cents": spread_width_cents,
            "liquidity_label": self._spread_label(spread_width_cents),
            "risk_label": risk["label"],
        }
        detail = {
            "spread": summary,
            "depth": depth,
            "concentration": concentration,
            "event_driven": event_profile,
            "expiry_decay": expiry_profile,
            "retail": retail,
            "information_shock": shock,
            "risk": risk,
            "liquidity_score": round(
                max(
                    1.0,
                    min(
                        100.0,
                        100
                        - risk["score"] * 0.55
                        + depth["depth_score"] * 0.45
                        + event_profile["support_score"] * 0.1,
                    ),
                ),
                1,
            ),
            "market_maker": market_maker,
        }
        return LiquiditySnapshot(summary=summary, detail=detail)

    def _spread_width_cents(
        self,
        market: Market,
        hours_to_expiry: float,
        volatility: float,
        support_score: float,
    ) -> int:
        balance_penalty = abs(market.yes_probability - 0.5) * 10
        expiry_penalty = 6.5 * exp(-hours_to_expiry / 72) if hours_to_expiry > 0 else 8.0
        support_discount = support_score / 18
        raw = 2.2 + volatility * 0.14 + balance_penalty + expiry_penalty - support_discount
        return max(1, int(round(raw)))

    def _spread_label(self, spread_width_cents: int) -> str:
        if spread_width_cents <= 2:
            return "High Liquidity"
        if spread_width_cents <= 5:
            return "Moderate Liquidity"
        if spread_width_cents <= 10:
            return "Low Liquidity"
        return "Illiquid"

    def _volatility_score(self, market: Market, trades: list[TradeOrder]) -> float:
        point_series = market.metadata_json.get("probability_points") or []
        last_points = [self._probability(point) for point in point_series[-6:]]
        series_vol = 0.0
        if len(last_points) >= 2:
            moves = [abs(last_points[idx] - last_points[idx - 1]) for idx in range(1, len(last_points))]
            series_vol = (sum(moves) / len(moves)) * 100
        trade_vol = 0.0
        if trades:
            recent_prices = [self._probability(trade.price) for trade in trades[:10]]
            center = sum(recent_prices) / len(recent_prices)
            trade_vol = sum(abs(price - center) for price in recent_prices) / len(recent_prices) * 100
        confidence_penalty = (1 - min(max(market.ai_confidence, 0), 1)) * 12
        return round(series_vol + trade_vol + confidence_penalty, 2)

    def _depth_profile(
        self,
        market: Market,
        spread_width_cents: int,
        support_score: float,
        volatility: float,
    ) -> dict:
        total_liquidity = max(market.liquidity, 1000.0)
        centrality = 1 - min(abs(market.yes_probability - 0.5) * 1.45, 0.45)
        liquidity_multiplier = max(0.55, min(1.5, support_score / 60 + 0.7))
        volatility_drag = max(0.55, 1 - volatility / 140)
        available_depth = total_liquidity * centrality * liquidity_multiplier * volatility_drag
        yes_bias = min(max(0.5 + (market.yes_probability - 0.5) * 0.7, 0.22), 0.78)
        yes_depth_total = round(available_depth * yes_bias, 2)
        no_depth_total = round(available_depth * (1 - yes_bias), 2)
        imbalance_ratio = round(yes_depth_total / max(no_depth_total, 1), 2)
        ladder = []
        cumulative_yes = 0.0
        cumulative_no = 0.0
        for step in range(0, 11):
            probability = round(step / 10, 2)
            distance = abs(probability - market.yes_probability)
            weight = max(0.12, 1 - distance * 2.15)
            rung_yes = round(yes_depth_total * weight / 4.9, 2)
            rung_no = round(no_depth_total * max(0.12, 1 - abs((1 - probability) - market.no_probability) * 2.15) / 4.9, 2)
            cumulative_yes += rung_yes
            cumulative_no += rung_no
            ladder.append(
                {
                    "probability": probability,
                    "yes_depth": rung_yes,
                    "no_depth": rung_no,
                    "cumulative_yes": round(cumulative_yes, 2),
                    "cumulative_no": round(cumulative_no, 2),
                }
            )
        depth_score = round(min(100.0, available_depth / max(spread_width_cents * 2200, 1) * 100), 1)
        return {
            "yes_depth_total": yes_depth_total,
            "no_depth_total": no_depth_total,
            "imbalance_ratio": imbalance_ratio,
            "order_distribution": ladder,
            "probability_ladder": [item["probability"] for item in ladder],
            "depth_score": depth_score,
        }

    def _concentration_profile(
        self,
        market: Market,
        trades: list[TradeOrder],
        subscriptions: list[VaultSubscription],
    ) -> dict:
        providers: defaultdict[int, float] = defaultdict(float)
        for trade in trades:
            providers[trade.user_id] += max(trade.collateral_amount, 0)
        for subscription in subscriptions:
            providers[subscription.user_id] += max(subscription.deposited_amount * 0.04, 0)
        if not providers:
            providers[0] = max(market.liquidity, 1)
        amounts = sorted(providers.values(), reverse=True)
        total = max(sum(amounts), 1)
        top_share = sum(amounts[:3]) / total * 100
        hhi = sum((amount / total) ** 2 for amount in amounts)
        decentralization_index = round(max(0.0, min(100.0, (1 - hhi) * 100)), 1)
        concentration_score = round(min(100.0, top_share * 0.9 + hhi * 100 * 0.4), 1)
        return {
            "top_providers_share_pct": round(top_share, 1),
            "top_provider_count": min(3, len(amounts)),
            "lp_concentration_score": concentration_score,
            "decentralization_index": decentralization_index,
            "risk_flag": top_share >= 60,
            "summary": f"Top 3 LPs provide {round(top_share):.0f}% of liquidity",
            "providers": [
                {
                    "rank": idx + 1,
                    "share_pct": round(amount / total * 100, 1),
                }
                for idx, amount in enumerate(amounts[:5])
            ],
            "concentration_score": concentration_score,
        }

    def _event_profile(self, market: Market) -> dict:
        title = f"{market.title} {market.category}".lower()
        score = 35.0
        if any(token in title for token in ("btc", "bitcoin", "fed", "sec", "regulation", "cpi", "macro", "etf")):
            score += 28
        if market.volume >= 1_000_000:
            score += 18
        elif market.volume >= 250_000:
            score += 8
        if market.liquidity >= 1_500_000:
            score += 12
        profile = "High Profile" if score >= 70 else "Standard" if score >= 48 else "Low Profile"
        return {
            "profile": profile,
            "support_score": round(min(score, 100), 1),
            "spread_bias": "Tighter spreads and deeper AI support" if profile == "High Profile" else "Baseline support" if profile == "Standard" else "Wider spreads with lighter support",
            "liquidity_policy": "Boosted" if profile == "High Profile" else "Balanced" if profile == "Standard" else "Conservative",
        }

    def _expiry_profile(self, hours_to_expiry: float, spread_width_cents: int) -> dict:
        decay = round(min(100.0, max(0.0, 100 - min(hours_to_expiry, 720) / 7.2)), 1)
        warning = "Liquidity decreasing as resolution nears" if hours_to_expiry <= 72 else None
        return {
            "hours_to_expiry": round(hours_to_expiry, 1),
            "decay_score": decay,
            "spread_adjustment_cents": max(1, round(spread_width_cents * 0.3)) if hours_to_expiry <= 72 else 0,
            "warning": warning,
            "exposure_guidance": "Reduce leverage and tighten sizing" if hours_to_expiry <= 72 else "Normal position sizing",
        }

    def _retail_profile(
        self,
        market: Market,
        risk_score: float,
        yes_depth: float,
        no_depth: float,
        best_yes_ask: float,
        implied_no_ask: float,
    ) -> dict:
        micro_size = 50.0 if risk_score < 55 else 25.0
        side = "YES" if market.yes_probability >= 0.5 else "NO"
        pool_depth = yes_depth if side == "YES" else no_depth
        price = best_yes_ask if side == "YES" else implied_no_ask
        slippage = self._slippage_pct(micro_size, pool_depth, risk_score)
        return {
            "micro_position_optimized": True,
            "recommended_ticket_size_usd": micro_size,
            "primary_side": side,
            "routing_mode": "Minimal slippage routing",
            "simplified_ui_hint": "Most forecast participants here can size under $100 with capped price impact.",
            "micro_trade_preview": {
                "ticket_size_usd": micro_size,
                "slippage_pct": round(slippage, 2),
                "execution_price": round(min(0.99, price * (1 + slippage / 100)), 4),
            },
        }

    def _information_shock(self, market: Market, volatility: float, trades: list[TradeOrder]) -> dict:
        point_series = market.metadata_json.get("probability_points") or []
        shock_move = 0.0
        if len(point_series) >= 2:
            shock_move = abs(self._probability(point_series[-1]) - self._probability(point_series[-2])) * 100
        recent_trade_burst = min(len(trades), 20) / 2
        shock_score = round(shock_move * 2.4 + volatility * 0.65 + recent_trade_burst, 1)
        if shock_score >= 25:
            status = "Shock Active"
            action = "Spreads widened and AI market maker intervention triggered"
        elif shock_score >= 15:
            status = "Elevated"
            action = "Volatility flags raised and liquidity monitored closely"
        else:
            status = "Stable"
            action = "Normal information flow"
        return {
            "status": status,
            "shock_score": shock_score,
            "action": action,
            "user_alert": "Incoming information shock detected. Execution guardrails tightened." if status != "Stable" else None,
        }

    def _risk_profile(
        self,
        *,
        spread_width_cents: int,
        depth_score: float,
        concentration_score: float,
        volatility: float,
        hours_to_expiry: float,
        shock_active: bool,
    ) -> dict:
        expiry_risk = 100 - min(hours_to_expiry, 480) / 4.8
        score = (
            spread_width_cents * 4.1
            + (100 - depth_score) * 0.28
            + concentration_score * 0.18
            + volatility * 1.2
            + expiry_risk * 0.14
            + (8 if shock_active else 0)
        )
        bounded = round(max(0.0, min(100.0, score)), 1)
        label = "Low Risk" if bounded < 38 else "Medium Risk" if bounded < 68 else "High Risk"
        return {
            "score": bounded,
            "label": label,
            "drivers": [
                f"Spread {spread_width_cents}c",
                f"Depth {depth_score:.0f}",
                f"Concentration {concentration_score:.0f}",
                f"Volatility {volatility:.1f}",
                f"Expiry {hours_to_expiry:.0f}h",
            ],
        }

    def _market_maker_profile(
        self,
        *,
        market: Market,
        spread_width_cents: int,
        volatility: float,
        event_profile: dict,
        hours_to_expiry: float,
        shock: dict,
        imbalance_ratio: float,
    ) -> dict:
        stable = volatility < 8 and shock["status"] == "Stable" and hours_to_expiry > 96
        target_spread = max(1, spread_width_cents - 1) if stable else spread_width_cents + (2 if shock["status"] == "Shock Active" else 0)
        return {
            "agent_name": "Aether MM-01",
            "mode": "Tighten spreads" if stable else "Defensive rebalance",
            "target_spread_cents": target_spread,
            "inventory_bias": "YES" if imbalance_ratio < 0.92 else "NO" if imbalance_ratio > 1.08 else "Balanced",
            "actions": [
                "Provide continuous YES/NO liquidity",
                "Rebalance outcome pools around probability shifts",
                "Widen spreads during uncertainty spikes" if not stable else "Tighten spreads in stable conditions",
                "Reduce inventory risk into expiry",
            ],
            "inputs": {
                "time_to_expiry_hours": round(hours_to_expiry, 1),
                "volatility_score": volatility,
                "event_profile": event_profile["profile"],
                "liquidity_gap_state": "Gap detected" if spread_width_cents >= 8 else "Contained",
                "information_state": shock["status"],
            },
        }

    def _slippage_pct(self, collateral_amount: float, pool_depth: float, risk_score: float) -> float:
        if pool_depth <= 0:
            return 9.0
        size_ratio = collateral_amount / max(pool_depth, 1)
        raw = size_ratio * 22 + risk_score / 110
        return max(0.2, min(12.0, raw))

    def _probability(self, value: float | int | str | None) -> float:
        if value is None:
            return 0.5
        raw = float(value)
        if raw > 1:
            raw /= 100
        return max(0.0, min(1.0, raw))
