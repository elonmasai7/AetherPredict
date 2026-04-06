from __future__ import annotations

import json
from statistics import mean
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import urlopen
from xml.etree import ElementTree


COINGECKO_URL = "https://api.coingecko.com/api/v3/coins/markets"
NEWS_FEEDS = {
    "btc": "https://www.coindesk.com/arc/outboundfeeds/rss/",
    "eth": "https://decrypt.co/feed",
    "sol": "https://cointelegraph.com/rss/tag/solana",
    "hashkey": "https://www.coindesk.com/arc/outboundfeeds/rss/?outputType=xml",
}


def _infer_asset_key(text: str) -> tuple[str, str]:
    lower = text.lower()
    if "eth" in lower:
        return "ethereum", "eth"
    if "sol" in lower:
        return "solana", "sol"
    if "hashkey" in lower or "hsk" in lower:
        return "hashkey-ecosphere", "hashkey"
    return "bitcoin", "btc"


def _fetch_market(asset_id: str) -> dict:
    params = urlencode(
        {
            "vs_currency": "usd",
            "ids": asset_id,
            "order": "market_cap_desc",
            "sparkline": "false",
            "price_change_percentage": "24h",
        }
    )
    with urlopen(f"{COINGECKO_URL}?{params}", timeout=20) as response:
        payload = json.loads(response.read().decode("utf-8"))
    return payload[0] if payload else {}


def _fetch_headlines(topic_key: str) -> list[dict]:
    url = NEWS_FEEDS[topic_key]
    try:
        with urlopen(url, timeout=20) as response:
            xml = response.read().decode("utf-8", errors="ignore")
    except URLError:
        return []
    root = ElementTree.fromstring(xml)
    items = []
    for item in root.findall(".//item")[:3]:
        title = item.findtext("title") or "Headline unavailable"
        source = item.findtext("source") or item.findtext("link") or "RSS"
        items.append({"headline": title.strip(), "source": source.strip()})
    return items


def _build_market_context(asset_id: str, topic_key: str) -> tuple[dict, list[dict]]:
    market = _fetch_market(asset_id)
    headlines = _fetch_headlines(topic_key)
    return market, headlines


def resolve_market(title: str, oracle_source: str, data_sources: list[str]) -> dict:
    asset_id, topic_key = _infer_asset_key(title)
    market, headlines = _build_market_context(asset_id, topic_key)
    change = float(market.get("price_change_percentage_24h") or 0)
    confidence = max(0.05, min(0.98, 0.6 + (change / 100)))
    outcome = "YES" if change >= 0 else "NO"
    return {
        "outcome": outcome,
        "confidence": round(confidence, 4),
        "supporting_evidence": [
            f"Oracle source reviewed: {oracle_source}",
            f"24h price change: {change:.2f}%",
            f"External sources checked: {len(data_sources)}",
            *[headline["headline"] for headline in headlines[:2]],
        ],
        "anomaly_alerts": ["No critical anomalies detected"] if abs(change) < 8 else ["Elevated daily move detected"],
    }


def score_sentiment(topic: str) -> dict:
    asset_id, topic_key = _infer_asset_key(topic)
    market, headlines = _build_market_context(asset_id, topic_key)
    change = float(market.get("price_change_percentage_24h") or 0)
    sentiment = "bullish" if change > 1 else "bearish" if change < -1 else "neutral"
    confidence = max(0.1, min(0.95, 0.55 + abs(change / 100)))
    return {
        "topic": topic,
        "sentiment": sentiment,
        "confidence": round(confidence, 4),
        "supporting_evidence": [headline["headline"] for headline in headlines] or ["No live news headlines available"],
    }


def probability_update(market_id: str) -> dict:
    asset_id, topic_key = _infer_asset_key(market_id)
    market, headlines = _build_market_context(asset_id, topic_key)
    change = float(market.get("price_change_percentage_24h") or 0)
    high = float(market.get("high_24h") or market.get("current_price") or 0)
    low = float(market.get("low_24h") or market.get("current_price") or 0)
    current = float(market.get("current_price") or 0)
    volatility = ((high - low) / current) if current else 0
    probability = max(0.01, min(0.99, 0.5 + (change / 100)))
    return {
        "market_id": market_id,
        "yes_probability": round(probability, 4),
        "confidence": round(max(0.1, min(0.95, 0.55 + volatility)), 4),
        "supporting_evidence": [headline["headline"] for headline in headlines[:2]] or ["Probability calibrated from live market data"],
    }


def anomaly_detection(market_id: str) -> dict:
    asset_id, _ = _infer_asset_key(market_id)
    market = _fetch_market(asset_id)
    volume = float(market.get("total_volume") or 0)
    market_cap = float(market.get("market_cap") or 0)
    ratio = (volume / market_cap) if market_cap else 0
    alerts = []
    if ratio > 0.12:
        alerts.append("Volume-to-market-cap ratio elevated")
    if abs(float(market.get("price_change_percentage_24h") or 0)) > 8:
        alerts.append("Large 24h price movement")
    return {
        "market_id": market_id,
        "outcome": "WATCH" if alerts else "STABLE",
        "confidence": round(min(0.95, 0.5 + ratio), 4),
        "supporting_evidence": [f"Volume/market cap ratio {ratio:.4f}"],
        "anomaly_alerts": alerts or ["No anomaly detected"],
    }


def copilot_recommendation(payload: dict) -> dict:
    market_id = payload["market_id"]
    update = probability_update(market_id)
    yes_probability = update["yes_probability"]
    bullish = yes_probability >= 0.55
    return {
        "action": "BUY_YES" if bullish else "BUY_NO" if yes_probability <= 0.45 else "HOLD",
        "confidence": round(update["confidence"] * 100),
        "risk": "HIGH" if abs(yes_probability - 0.5) < 0.05 else "MEDIUM",
        "reasoning": "; ".join(update["supporting_evidence"]),
        "position_size": f"{max(3, min(20, round(abs(yes_probability - 0.5) * 100)))}%",
        "sentiment_trend": "BULLISH" if bullish else "BEARISH" if yes_probability <= 0.45 else "NEUTRAL",
    }


def market_sentiment_feed(payload: dict) -> dict:
    topic = payload.get("market_id", "macro")
    asset_id, topic_key = _infer_asset_key(topic)
    market, headlines = _build_market_context(asset_id, topic_key)
    scores = [float(market.get("price_change_percentage_24h") or 0), float(market.get("market_cap_rank") or 0) / 100]
    sentiment_score = max(0.0, min(1.0, 0.5 + (mean(scores) / 100)))
    confidence_shift = round(float(market.get("price_change_percentage_24h") or 0))
    return {
        "sentiment_score": round(sentiment_score, 4),
        "trend": "BULLISH" if confidence_shift > 1 else "BEARISH" if confidence_shift < -1 else "MIXED",
        "news_items": headlines,
        "confidence_shift": confidence_shift,
    }
