from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from database import SessionLocal, init_db, settings
from models import Market, User
from security import hash_password


def seed() -> None:
    init_db()
    db = SessionLocal()
    try:
        if db.scalar(select(User).where(User.email == "demo@predictodds.pro")) is None:
            db.add(User(email="demo@predictodds.pro", password_hash=hash_password("DemoPass123!"), balance=750))

        if not db.scalars(select(Market)).first():
            now = datetime.now(timezone.utc)
            markets = [
                Market(
                    title="Will Nairobi hit 29C before Friday close?",
                    event="Nairobi weather",
                    provider="mock",
                    end_ts=now + timedelta(days=3),
                    min_liquidity=2500,
                    liquidity_usd=6000,
                    b_param=settings.default_b_param,
                    yes_shares=960,
                    no_shares=840,
                    metadata_json={"theme": "weather", "city": "Nairobi"},
                ),
                Market(
                    title="Will the Nairobi county turnout exceed 58% in the next election?",
                    event="Nairobi election",
                    provider="mock",
                    end_ts=now + timedelta(days=10),
                    min_liquidity=4000,
                    liquidity_usd=9000,
                    b_param=settings.default_b_param,
                    yes_shares=930,
                    no_shares=870,
                    metadata_json={"theme": "election", "region": "Nairobi"},
                ),
                Market(
                    title="Will the Fed cut rates by 25bps at the next meeting?",
                    event="Fed rates",
                    provider="mock",
                    end_ts=now + timedelta(days=18),
                    min_liquidity=5000,
                    liquidity_usd=15000,
                    b_param=settings.default_b_param,
                    yes_shares=880,
                    no_shares=920,
                    metadata_json={"theme": "macro"},
                ),
                Market(
                    title="Will a Trump tariff headline move odds by more than 8 cents this week?",
                    event="Trump policies",
                    provider="mock",
                    end_ts=now + timedelta(days=5),
                    min_liquidity=3500,
                    liquidity_usd=12000,
                    b_param=settings.default_b_param,
                    yes_shares=910,
                    no_shares=890,
                    metadata_json={"theme": "politics"},
                ),
            ]
            db.add_all(markets)
        db.commit()
        print("Seed complete.")
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ensure-db", action="store_true")
    parser.parse_args()
    seed()
