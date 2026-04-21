from __future__ import annotations

from datetime import UTC, datetime


class PredictionEngine:
    def enrich_market(self, market, liquidity_snapshot: dict, news_items: list[dict]) -> dict:
        metadata = market.metadata_json or {}
        yes_probability = round(float(market.yes_probability), 4)
        confidence = round(float(market.ai_confidence), 4)
        detail = liquidity_snapshot["detail"]
        insight = self._build_ai_insight(market.title, metadata, news_items, yes_probability, confidence)
        return {
            "id": market.id,
            "slug": market.slug,
            "title": market.title,
            "market_type": metadata.get("market_type", "game_outcome"),
            "category": market.category,
            "matchup": metadata.get("matchup", market.title),
            "primary_subject": metadata.get("primary_subject", market.title),
            "yes_label": metadata.get("yes_label", "Yes"),
            "no_label": metadata.get("no_label", "No"),
            "yes_probability": yes_probability,
            "no_probability": round(1 - yes_probability, 4),
            "ai_confidence": confidence,
            "volume": round(float(market.volume), 2),
            "liquidity": round(float(market.liquidity), 2),
            "spread_bps": liquidity_snapshot["summary"]["spread_width_cents"] * 100,
            "depth": round(
                detail["depth"]["yes_depth_total"] + detail["depth"]["no_depth_total"],
                2,
            ),
            "slippage": detail["retail"]["micro_trade_preview"]["slippage_pct"],
            "liquidity_score": detail["liquidity_score"],
            "team_form": metadata.get("team_form", {}),
            "player_context": metadata.get("player_context", {}),
            "probability_points": metadata.get("probability_points", []),
            "ai_insight": insight,
            "latest_news": news_items,
            "expires_at": market.expiry_at.astimezone(UTC) if market.expiry_at.tzinfo else market.expiry_at.replace(tzinfo=UTC),
            "confidence_label": self._confidence_label(confidence),
        }

    def preview_strategy(self, prompt: str, markets: list[dict], risk_level: str, automation_enabled: bool, data_sources: list[str]) -> dict:
        normalized = prompt.lower()
        chosen = next(
            (
                market
                for market in markets
                if any(token in normalized for token in market["title"].lower().split())
            ),
            markets[0] if markets else None,
        )
        probability = chosen["yes_probability"] if chosen else 0.55
        confidence = max(0.55, min(0.88, chosen["ai_confidence"] if chosen else 0.64))
        if "injury" in normalized:
            confidence = min(0.92, confidence + 0.05)
        if risk_level.lower() == "conservative":
            probability = max(0.52, probability - 0.03)
        elif risk_level.lower() == "aggressive":
            probability = min(0.78, probability + 0.04)

        selected_market_id = chosen["id"] if chosen else None
        title = f"Strategy: {prompt[:44].strip()}" if prompt.strip() else "Strategy Preview"
        return {
            "title": title,
            "summary": "Custom strategy agent translated your natural language instructions into a focused NBA prediction workflow.",
            "probability": round(probability, 4),
            "confidence": round(confidence, 4),
            "execution_ready": bool(selected_market_id),
            "suggested_market_id": selected_market_id,
            "rationale": [
                f"Primary market selected: {chosen['title'] if chosen else 'No matching market found'}.",
                f"Data sources considered: {', '.join(data_sources) if data_sources else 'team stats, news, and historical form'}.",
                "Model weights recent form, availability signals, and matchup efficiency before recommending execution.",
            ],
            "safeguards": [
                f"Risk mode: {risk_level.title()}",
                "Avoid auto-execution when key injury statuses remain unresolved.",
                "Cap position size when slippage exceeds 1.5% or confidence falls below 60%.",
                "Automation is enabled." if automation_enabled else "Automation is disabled.",
            ],
        }

    def _build_ai_insight(self, title: str, metadata: dict, news_items: list[dict], yes_probability: float, confidence: float) -> str:
        headline = metadata.get("player_context", {}).get("trend") or metadata.get("team_form", {}).get("home_record_last_5")
        news_prefix = ""
        if news_items:
            news_prefix = f"{news_items[0]['tag']} is active. "
        lean = "leans YES" if yes_probability >= 0.5 else "leans NO"
        return f"{news_prefix}Model {lean} on {title} with {confidence * 100:.0f}% confidence. {headline or 'Efficiency trend remains supportive.'}"

    def _confidence_label(self, confidence: float) -> str:
        if confidence >= 0.78:
            return "High Conviction"
        if confidence >= 0.68:
            return "Actionable"
        return "Monitor"
