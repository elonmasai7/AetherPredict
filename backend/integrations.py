from __future__ import annotations

import base64
from datetime import datetime, timezone
from typing import Any
from urllib.parse import urljoin

import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from requests_oauthlib import OAuth2Session

from database import settings


class ProviderProxy:
    timeout = 8

    def fetch_market_data(self, market) -> dict[str, Any]:
        if market.provider == "kalshi" and market.provider_market_id:
            return self._fetch_kalshi_market(market.provider_market_id)
        if market.provider == "alpaca":
            return self._fetch_alpaca_reference(market)
        return {}

    def _fetch_kalshi_market(self, ticker: str) -> dict[str, Any]:
        try:
            market_response = requests.get(
                f"{settings.kalshi_base_url}/markets/{ticker}",
                timeout=self.timeout,
            )
            orderbook_response = requests.get(
                f"{settings.kalshi_base_url}/markets/{ticker}/orderbook",
                timeout=self.timeout,
            )
            market_payload = market_response.json().get("market", {}) if market_response.ok else {}
            orderbook_payload = orderbook_response.json().get("orderbook_fp", {}) if orderbook_response.ok else {}
            yes_bid = float(orderbook_payload.get("yes_dollars", [["0.49", "25"]])[0][0])
            no_bid = float(orderbook_payload.get("no_dollars", [["0.49", "25"]])[0][0])
            yes_ask = 1 - no_bid
            return {
                "reference_yes_price": float(market_payload.get("yes_price_dollars", yes_ask)),
                "reference_no_price": float(market_payload.get("no_price_dollars", 1 - yes_ask)),
                "reference_volume": float(market_payload.get("volume", 0) or 0),
                "reference_orderbook": {
                    "yes_dollars": orderbook_payload.get("yes_dollars", []),
                    "no_dollars": orderbook_payload.get("no_dollars", []),
                },
                "source": "kalshi",
            }
        except Exception:
            return {}

    def _fetch_alpaca_reference(self, market) -> dict[str, Any]:
        symbol = (market.metadata_json or {}).get("alpaca_symbol", "SPY")
        endpoint = f"{settings.alpaca_market_data_url}/v2/stocks/{symbol}/quotes/latest"
        headers: dict[str, str] = {}
        if credentials := (market.metadata_json or {}).get("alpaca_market_headers"):
            headers.update(credentials)
        try:
            response = requests.get(endpoint, headers=headers, timeout=self.timeout)
            if not response.ok:
                return {}
            quote = response.json().get("quote", {})
            bid = float(quote.get("bp", 100))
            ask = float(quote.get("ap", bid + 0.1))
            price = (bid + ask) / 2
            normalized = max(0.05, min(0.95, ((price % 100) / 100)))
            return {
                "reference_yes_price": normalized,
                "reference_no_price": 1 - normalized,
                "reference_volume": float(quote.get("as", 0) or 0),
                "source": "alpaca",
            }
        except Exception:
            return {}


class KalshiAuthClient:
    def __init__(self, api_key_id: str, private_key_pem: str, base_url: str | None = None):
        self.api_key_id = api_key_id
        self.private_key = serialization.load_pem_private_key(private_key_pem.encode("utf-8"), password=None)
        self.base_url = base_url or settings.kalshi_demo_base_url

    def _headers(self, method: str, path: str) -> dict[str, str]:
        timestamp = str(int(datetime.now(timezone.utc).timestamp() * 1000))
        signature_payload = f"{timestamp}{method.upper()}{path}".encode("utf-8")
        signature = self.private_key.sign(
            signature_payload,
            padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.DIGEST_LENGTH),
            hashes.SHA256(),
        )
        return {
            "KALSHI-ACCESS-KEY": self.api_key_id,
            "KALSHI-ACCESS-TIMESTAMP": timestamp,
            "KALSHI-ACCESS-SIGNATURE": base64.b64encode(signature).decode("utf-8"),
        }

    def get_balance(self) -> dict[str, Any]:
        path = "/portfolio/balance"
        response = requests.get(urljoin(self.base_url + "/", path.lstrip("/")), headers=self._headers("GET", "/trade-api/v2" + path), timeout=8)
        return response.json() if response.ok else {"error": response.text}


class AlpacaAuthClient:
    def __init__(
        self,
        api_key_id: str | None = None,
        api_secret: str | None = None,
        oauth_token: str | None = None,
        trading_url: str | None = None,
    ):
        self.api_key_id = api_key_id
        self.api_secret = api_secret
        self.oauth_token = oauth_token
        self.trading_url = trading_url or settings.alpaca_trading_url

    def account(self) -> dict[str, Any]:
        if self.oauth_token:
            session = OAuth2Session(token={"access_token": self.oauth_token, "token_type": "Bearer"})
            response = session.get(f"{self.trading_url}/v2/account", timeout=8)
        else:
            headers = {
                "APCA-API-KEY-ID": self.api_key_id or "",
                "APCA-API-SECRET-KEY": self.api_secret or "",
            }
            response = requests.get(f"{self.trading_url}/v2/account", headers=headers, timeout=8)
        return response.json() if response.ok else {"error": response.text}
