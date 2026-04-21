# AetherPredict

AetherPredict is an AI-powered NBA prediction market platform built around game outcomes, player performance markets, season-long futures, real-time news impact, and wallet-aware settlement.

The product is intentionally not a crypto exchange, not a forex terminal, and not a generic trading dashboard. It is designed to feel like a sports intelligence system with prediction execution built in.

## Product Focus

Users can:

- predict NBA game winners
- forecast player stats such as points, assists, and rebounds
- trade season markets such as MVP and Finals qualification
- follow AI-generated predictions
- build custom prompt-driven strategies
- review liquidity, depth, slippage, and activity in one workflow

Core platform surfaces:

- `Overview`
- `Live Games`
- `Markets`
- `My Predictions`
- `AI Agents`
- `News`
- `Leaderboard`
- `Strategy Lab`

## Architecture

```text
.
├── apps/
│   ├── ai-service/        # AI support service
│   ├── backend/           # FastAPI API and NBA market services
│   └── flutter_app/       # Flutter web/mobile client
├── predictflow/           # Dart companion engine
├── docker-compose.yml     # Local infra + API stack
└── README.md
```

Main backend modules now include:

- `nba_data_service`
- `news_service`
- `market_service`
- `prediction_engine`
- `agent_engine`
- `execution_service`

## Local Stack

The simplest way to run the platform locally is:

```bash
docker compose up -d --build
```

Then verify:

- App/API: `http://localhost:8000`
- Ready check: `http://localhost:8000/ready`
- API docs: `http://localhost:8000/docs`
- AI service: `http://localhost:8010`

The backend serves the built Flutter web bundle from `apps/flutter_app/build/web`, so the main product is available from the backend once the web app has been built.

## First-Time Setup

1. Review [.env.example](/workspaces/AetherPredict/.env.example) if you need custom local values.
2. Build the Flutter web client:

```bash
cd apps/flutter_app
flutter build web
```

3. Start the stack:

```bash
cd /workspaces/AetherPredict
docker compose up -d --build
```

4. If the database is fresh, run migrations:

```bash
cd apps/backend
PYTHONPATH=. .venv/bin/alembic upgrade head
```

5. Confirm the backend:

```bash
curl http://localhost:8000/ready
```

## Running Without Docker

### Backend

```bash
cd apps/backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
PYTHONPATH=. .venv/bin/alembic upgrade head
PYTHONPATH=. .venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Flutter App

```bash
cd apps/flutter_app
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=WS_MARKETS_URL=ws://localhost:8000/ws/markets \
  --dart-define=PREDICTFLOW_BASE_URL=http://localhost:8081
```

### PredictFlow Companion

```bash
cd predictflow
dart pub get
dart run bin/server.dart
```

## Key API Surfaces

NBA-first endpoints include:

- `GET /platform/home`
- `POST /platform/strategy/preview`
- `GET /news`
- `GET /markets`
- `POST /trades`
- `GET /leaderboard/*`
- `GET /agents`
- `GET /ready`

WebSocket streams:

- `ws://localhost:8000/ws/markets`
- `ws://localhost:8000/ws/tx`

## Current Local Behavior

The codebase is now structured as a production-ready NBA product, but this workspace may still run without external API credentials. In that mode:

- NBA market/news/agent data is seeded with realistic domain-shaped content
- probability updates stream locally
- predictions execute through the MVP settlement path
- no fake blockchain hashes are generated

When live providers are configured, the seeded services are the swap points for:

- ESPN/news feeds
- official NBA data sources
- live injury and player update providers
- real on-chain execution

## Verification

Useful checks:

```bash
curl http://localhost:8000/ready
curl http://localhost:8000/platform/home
curl http://localhost:8000/news
```

Backend compile check:

```bash
python -m compileall apps/backend/app
```

Flutter checks:

```bash
cd apps/flutter_app
flutter analyze
flutter build web
```
