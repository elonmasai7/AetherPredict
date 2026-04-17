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
