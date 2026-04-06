from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from web3 import Web3
from web3.exceptions import TransactionNotFound

from app.core.config import settings


ABI_DIR = Path(__file__).resolve().parents[2] / "blockchain" / "abi"
ERC20_ABI = ABI_DIR / "erc20.json"


@dataclass
class BuiltTransaction:
    to: str
    data: str
    value: int
    gas: int | None
    gas_price: int | None
    nonce: int | None
    chain_id: int


class BlockchainService:
    def __init__(self) -> None:
        self.web3 = self._build_web3()
        self.chain_id = settings.hashkey_chain_id

    def _build_web3(self) -> Web3:
        endpoints = [settings.hashkey_rpc_url] + settings.hashkey_rpc_fallbacks
        endpoints = [endpoint for endpoint in endpoints if endpoint]
        if not endpoints:
            raise RuntimeError("HASHKEY_RPC_URL must be configured.")
        for endpoint in endpoints:
            provider = Web3(Web3.HTTPProvider(endpoint))
            try:
                if provider.is_connected():
                    return provider
            except Exception:
                continue
        return Web3(Web3.HTTPProvider(endpoints[0]))

    def _load_abi(self, name: str) -> list[dict[str, Any]]:
        path = ABI_DIR / f"{name}.json"
        payload = json.loads(path.read_text())
        return payload["abi"] if isinstance(payload, dict) and "abi" in payload else payload

    def _load_erc20_abi(self) -> list[dict[str, Any]]:
        payload = json.loads(ERC20_ABI.read_text())
        return payload["abi"] if isinstance(payload, dict) and "abi" in payload else payload

    def get_erc20_balance(self, token_address: str, wallet_address: str) -> tuple[float, int]:
        abi = self._load_erc20_abi()
        contract = self.web3.eth.contract(address=Web3.to_checksum_address(token_address), abi=abi)
        balance = contract.functions.balanceOf(Web3.to_checksum_address(wallet_address)).call()
        decimals = contract.functions.decimals().call()
        normalized = balance / (10 ** decimals)
        return float(normalized), int(decimals)

    def _contract(self, address: str, abi_name: str):
        abi = self._load_abi(abi_name)
        return self.web3.eth.contract(address=Web3.to_checksum_address(address), abi=abi)

    def _build_tx(self, from_address: str, to: str, data: str, value: int = 0) -> BuiltTransaction:
        chain_id = self.chain_id
        try:
            nonce = self.web3.eth.get_transaction_count(Web3.to_checksum_address(from_address))
        except Exception:
            nonce = None
        gas = None
        gas_price = None
        try:
            gas = self.web3.eth.estimate_gas(
                {"from": from_address, "to": to, "data": data, "value": value}
            )
        except Exception:
            gas = None
        try:
            gas_price = self.web3.eth.gas_price
        except Exception:
            gas_price = None
        return BuiltTransaction(
            to=to,
            data=data,
            value=value,
            gas=gas,
            gas_price=gas_price,
            nonce=nonce,
            chain_id=chain_id,
        )

    def build_buy_yes(self, market_address: str, wallet_address: str, collateral_wei: int) -> BuiltTransaction:
        contract = self._contract(market_address, "prediction_market")
        data = contract.encodeABI(fn_name="buy_yes", args=[])
        return self._build_tx(wallet_address, market_address, data, collateral_wei)

    def build_buy_no(self, market_address: str, wallet_address: str, collateral_wei: int) -> BuiltTransaction:
        contract = self._contract(market_address, "prediction_market")
        data = contract.encodeABI(fn_name="buy_no", args=[])
        return self._build_tx(wallet_address, market_address, data, collateral_wei)

    def build_sell(self, market_address: str, wallet_address: str, yes_side: bool, token_amount_wei: int) -> BuiltTransaction:
        contract = self._contract(market_address, "prediction_market")
        data = contract.encodeABI(fn_name="sell_position", args=[yes_side, token_amount_wei])
        return self._build_tx(wallet_address, market_address, data, 0)

    def build_claim(self, market_address: str, wallet_address: str) -> BuiltTransaction:
        contract = self._contract(market_address, "prediction_market")
        data = contract.encodeABI(fn_name="claim_rewards", args=[])
        return self._build_tx(wallet_address, market_address, data, 0)

    def build_dispute(self, market_address: str, wallet_address: str, evidence_uri: str, stake_wei: int) -> BuiltTransaction:
        contract = self._contract(market_address, "prediction_market")
        data = contract.encodeABI(fn_name="dispute_outcome", args=[evidence_uri])
        return self._build_tx(wallet_address, market_address, data, stake_wei)

    def build_create_market(
        self,
        wallet_address: str,
        title: str,
        description: str,
        oracle_source: str,
        expiry: int,
        creation_fee_wei: int,
    ) -> BuiltTransaction:
        if not settings.hashkey_factory_address:
            raise RuntimeError("HASHKEY_FACTORY_ADDRESS must be configured.")
        factory = self._contract(settings.hashkey_factory_address, "market_factory")
        data = factory.encodeABI(
            fn_name="create_market",
            args=[title, description, oracle_source, expiry],
        )
        return self._build_tx(wallet_address, settings.hashkey_factory_address, data, creation_fee_wei)

    def buy_yes_position(self, market_address: str, wallet_address: str, collateral_wei: int) -> BuiltTransaction:
        return self.build_buy_yes(market_address, wallet_address, collateral_wei)

    def buy_no_position(self, market_address: str, wallet_address: str, collateral_wei: int) -> BuiltTransaction:
        return self.build_buy_no(market_address, wallet_address, collateral_wei)

    def sell_position(self, market_address: str, wallet_address: str, yes_side: bool, token_amount_wei: int) -> BuiltTransaction:
        return self.build_sell(market_address, wallet_address, yes_side, token_amount_wei)

    def create_market(
        self,
        wallet_address: str,
        title: str,
        description: str,
        oracle_source: str,
        expiry: int,
        creation_fee_wei: int,
    ) -> BuiltTransaction:
        return self.build_create_market(wallet_address, title, description, oracle_source, expiry, creation_fee_wei)

    def claim_rewards(self, market_address: str, wallet_address: str) -> BuiltTransaction:
        return self.build_claim(market_address, wallet_address)

    def dispute_market(self, market_address: str, wallet_address: str, evidence_uri: str, stake_wei: int) -> BuiltTransaction:
        return self.build_dispute(market_address, wallet_address, evidence_uri, stake_wei)

    def broadcast_raw_tx(self, signed_tx: bytes) -> str:
        return self.web3.eth.send_raw_transaction(signed_tx).hex()

    def wait_for_receipt(self, tx_hash: str, timeout: int = 120) -> dict:
        return dict(self.web3.eth.wait_for_transaction_receipt(tx_hash, timeout=timeout))

    def get_receipt(self, tx_hash: str) -> dict | None:
        try:
            receipt = self.web3.eth.get_transaction_receipt(tx_hash)
        except TransactionNotFound:
            return None
        return dict(receipt)

    def get_native_balance(self, wallet_address: str) -> float:
        balance_wei = self.web3.eth.get_balance(Web3.to_checksum_address(wallet_address))
        return float(self.web3.from_wei(balance_wei, "ether"))

    def parse_market_events(self, market_address: str, receipt: dict) -> list[dict]:
        contract = self._contract(market_address, "prediction_market")
        events = []
        for event in (
            contract.events.PositionBought,
            contract.events.PositionSold,
            contract.events.MarketResolved,
            contract.events.OutcomeDisputed,
            contract.events.RewardsClaimed,
        ):
            for log in event().process_receipt(receipt):
                events.append(
                    {
                        "event": log["event"],
                        "args": dict(log["args"]),
                    }
                )
        return events

    def parse_factory_events(self, receipt: dict) -> list[dict]:
        factory = self._contract(settings.hashkey_factory_address, "market_factory")
        events = []
        for log in factory.events.MarketCreated().process_receipt(receipt):
            events.append(
                {
                    "event": log["event"],
                    "args": dict(log["args"]),
                }
            )
        return events
