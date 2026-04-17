# Canon CLI

This directory contains the local Canon CLI entrypoint for the AetherPredict Strategy Engine.

## Purpose

`canon_cli.py` scaffolds and updates prediction-market strategy projects outside the Flutter UI. It uses the same Canon project generation logic as the backend Strategy Engine service.

The CLI is designed for:

- event forecasting workflows
- prediction automation
- AI-driven probability modeling
- prediction-market microstructure strategies such as arbitrage detection, cross-market lag capture, speed-based opportunity, and novel custom signal design

It is not intended for forex bots or generic exchange trading automation.

## Commands

- `init`: generate a new Canon project scaffold on disk
- `start`: advance a local Canon project into active workflow state
- `deploy`: mark a local Canon project as live-deployment ready
- `monitor`: inspect the local `canon.lock.json` state

## Usage

```bash
cd apps/backend

PYTHONPATH=. .venv/bin/python -m app.scripts.canon_cli init \
  --name "BTC Arbitrage Pulse" \
  --prompt "Build an arbitrage detection model across related BTC prediction markets using ETF flows and sentiment." \
  --template sentiment-model \
  --market "BTC > 120k before Dec 2026" \
  --target-dir /tmp/btc-arbitrage-pulse

PYTHONPATH=. .venv/bin/python -m app.scripts.canon_cli start --target-dir /tmp/btc-arbitrage-pulse
PYTHONPATH=. .venv/bin/python -m app.scripts.canon_cli deploy --target-dir /tmp/btc-arbitrage-pulse
PYTHONPATH=. .venv/bin/python -m app.scripts.canon_cli monitor --target-dir /tmp/btc-arbitrage-pulse
```

## Files generated

A typical Canon project includes:

- `canon.json`
- `canon.lock.json`
- `README.md`
- `src/interfaces.ts`
- `src/index.ts`
- `src/execution.ts`

## Related backend endpoints

- `GET /strategy-engine/state`
- `GET /strategy-engine/templates`
- `POST /strategy-engine/build`
- `POST /strategy-engine/strategies/{strategy_id}/canon/{command}`
- `GET /strategy-engine/monitor`
- `GET /strategy-engine/ranking`
- `GET /strategy-engine/strategies/{strategy_id}/export?format=zip`
- `GET /strategy-engine/strategies/{strategy_id}/export?format=tar`
- `GET /strategy-engine/strategies/{strategy_id}/export/manifest`

## OpenAPI and Swagger

When the backend is running locally, FastAPI publishes interactive API docs at:

- `http://localhost:8000/docs`
- `http://localhost:8000/redoc`
- `http://localhost:8000/openapi.json`

Example authenticated Strategy Engine flow with `curl`:

```bash
BASE_URL=http://localhost:8000
EMAIL="swagger$(date +%s)@example.com"
PASSWORD="password123"

curl -sS -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"display_name\":\"Swagger Demo\"}"

LOGIN_JSON=$(curl -sS -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(printf '%s' "$LOGIN_JSON" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

curl -sS "$BASE_URL/strategy-engine/state" \
  -H "Authorization: Bearer $TOKEN"

BUILD_JSON=$(curl -sS -X POST "$BASE_URL/strategy-engine/build" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Build an innovative cross-market arbitrage model for BTC prediction markets using ETF flows, sentiment, and public catalyst data."}')

STRATEGY_ID=$(printf '%s' "$BUILD_JSON" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -n 1)

curl -sS -X POST "$BASE_URL/strategy-engine/strategies/$STRATEGY_ID/canon/start" \
  -H "Authorization: Bearer $TOKEN"

curl -sS -X POST "$BASE_URL/strategy-engine/strategies/$STRATEGY_ID/canon/deploy" \
  -H "Authorization: Bearer $TOKEN"

curl -sS "$BASE_URL/strategy-engine/monitor" \
  -H "Authorization: Bearer $TOKEN"

curl -sS "$BASE_URL/strategy-engine/ranking" \
  -H "Authorization: Bearer $TOKEN"

curl -L "$BASE_URL/strategy-engine/strategies/$STRATEGY_ID/export?format=zip" \
  -H "Authorization: Bearer $TOKEN" \
  -o /tmp/strategy-export.zip
```

## Backend smoke script

For a backend-only verification pass, run:

```bash
cd apps/backend
PYTHONPATH=. .venv/bin/python -m app.scripts.strategy_engine_smoke --base-url http://localhost:8000
```
