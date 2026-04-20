# PredictOdds Pro

PredictOdds Pro is a production-style MVP for real-time binary prediction markets built with:

- Flutter 3.24 / Dart 3.5 frontend in `frontend/`
- FastAPI 0.115+ / SQLAlchemy 2 / PostgreSQL 16+Timescale / Redis 7 backend in `backend/`
- Kalshi-first prediction market data integration with Alpaca credential support for secure account connectivity patterns

The app is tuned for retail-sized trading under `$100`, live bid/ask spreads, order book depth, and simulated liquidity that behaves like an event-driven prediction venue instead of a generic broker UI.

## PredictFlow Dart companion

The old `predictflow/` Node/TypeScript project has been removed and replaced with a pure Dart package in `predictflow/`.

Run it separately if you want the companion local engine online:

```bash
cd predictflow
dart pub get
dart run bin/server.dart
```

Default local endpoint:

```text
http://localhost:8081
```

## Official API references used

- Kalshi market data and auth docs: https://docs.kalshi.com/getting_started/quick_start_market_data and https://docs.kalshi.com/getting_started/quick_start_authenticated_requests
- Alpaca auth docs: https://docs.alpaca.markets/docs/authentication and https://docs.alpaca.markets/docs/using-oauth2-and-trading-api

Implementation note:
- Kalshi authenticated requests use `KALSHI-ACCESS-KEY`, `KALSHI-ACCESS-TIMESTAMP`, and `KALSHI-ACCESS-SIGNATURE` RSA-PSS headers.
- Alpaca supports direct key headers for Trading API and OAuth2/Bearer flows for Connect/Broker integrations.

## Project layout

```text
backend/
frontend/
README.md
```

## 1. Backend setup

### Local Python run

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python seed.py --ensure-db
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API docs:

```text
http://localhost:8000/docs
```

### Docker run

```bash
cd backend
docker compose up --build
```

This starts:

- PostgreSQL/Timescale on `localhost:5432`
- Redis on `localhost:6379`
- FastAPI on `localhost:8000`

## 2. Frontend setup

```bash
cd frontend
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=WS_BASE_URL=ws://localhost:8000
```

For Chrome/web:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=WS_BASE_URL=ws://localhost:8000
```

## 3. Create a demo user and log in

The seed script creates:

- Email: `demo@predictodds.pro`
- Password: `DemoPass123!`

Or create your own:

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"StrongPass123"}'

curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"StrongPass123"}'
```

## 4. Test market creation

```bash
curl -X POST http://localhost:8000/markets \
  -H "Content-Type: application/json" \
  -d '{
    "title":"Will Nairobi hit 30C this week?",
    "event":"Nairobi weather",
    "end_date":"2026-04-30T18:00:00Z",
    "min_liquidity":3500,
    "provider":"mock"
  }'
```

## 5. Test live odds

List markets:

```bash
curl http://localhost:8000/markets
```

Get odds for market `1`:

```bash
curl http://localhost:8000/markets/1/odds
```

Get liquidity:

```bash
curl http://localhost:8000/liquidity/1
```

## 6. Test trading

First login and copy the bearer token:

```bash
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@predictodds.pro","password":"DemoPass123!"}' | python -c "import sys, json; print(json.load(sys.stdin)['access_token'])")
```

Buy YES for `$25`:

```bash
curl -X POST http://localhost:8000/trade/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"side":"BUY_YES","notional":25}'
```

Then inspect updated odds:

```bash
curl http://localhost:8000/markets/1/odds
```

## 7. Test real-time websocket

Example with `wscat`:

```bash
npx wscat -c ws://localhost:8000/ws/odds/1
```

You will receive a snapshot roughly every second and immediately after trades.

## 8. Kalshi API signup and usage

1. Sign up at https://kalshi.com or demo docs via https://docs.kalshi.com
2. Generate an API key pair in account security
3. Save:
   - API key ID
   - private key PEM
4. In the Flutter Settings screen, choose `Kalshi` and paste:
   - API key into `API key / client id`
   - private key into `Kalshi private key PEM`
5. The backend stores these encrypted with Fernet and can use them for authenticated Kalshi proxy calls

Current official Kalshi docs note that authenticated requests require:

- `KALSHI-ACCESS-KEY`
- `KALSHI-ACCESS-TIMESTAMP`
- `KALSHI-ACCESS-SIGNATURE`

## 9. Alpaca signup and usage

1. Create a paper trading account at https://alpaca.markets
2. Generate paper credentials
3. In Flutter Settings choose `Alpaca`
4. Save:
   - API key in `API key / client id`
   - API secret in `API secret / OAuth token`

Current official Alpaca docs say:

- Trading API supports `APCA-API-KEY-ID` and `APCA-API-SECRET-KEY` headers
- OAuth2/Bearer flows are available for broader app integrations

## 10. Sample data

`backend/seed.py` creates:

- Nairobi weather market
- Nairobi election turnout market
- Fed rates market
- Trump policy volatility market

Run again anytime:

```bash
cd backend
python seed.py --ensure-db
```

## 11. Testing

Backend:

```bash
cd backend
pytest tests/test_liquidity.py
```

Frontend:

```bash
cd frontend
flutter test
```

## 12. Notes

- The liquidity engine uses LMSR-style pricing with dynamic spread widening under volatility and near expiry.
- Real provider fetches fall back to mock liquidity when credentials or remote responses are unavailable.
- The MVP is runnable as-is in mock mode and ready for hardening into a production deployment on Railway, Fly.io, Render, or Heroku-style container hosts.
