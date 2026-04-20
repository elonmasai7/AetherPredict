# AetherPredict

AetherPredict is a prediction-market platform built around binary outcomes, real-time probability pricing, liquidity intelligence, and retail-friendly execution. This repository contains the full local stack: a FastAPI backend, a Flutter client, an AI support service, and a Dart companion engine for simulated market behavior.

AetherPredict is designed to feel like institutional-grade liquidity infrastructure for prediction markets while staying accessible to everyday traders. The product focuses on probability-native market mechanics rather than generic exchange abstractions.

What makes the platform distinct:

- probability-based YES/NO pricing
- spread-aware liquidity tiers
- event-driven market intelligence
- slippage previews and risk-aware execution
- AI-assisted market support
- cross-platform Flutter delivery

If you want to get the stack running quickly, start here:

```bash
docker compose up -d
```

Then open:

- App/API: `http://localhost:8000`
- API docs: `http://localhost:8000/docs`
- Backend readiness: `http://localhost:8000/ready`

**Repository Structure**

```text
.
├── apps/
│   ├── ai-service/        # AI support service
│   ├── backend/           # FastAPI application
│   └── flutter_app/       # Flutter client
├── predictflow/           # Dart companion engine
├── docker-compose.yml     # Local full-stack orchestration
├── .env.example
└── README.md
```

**Architecture**

- `apps/backend`: primary API, auth, market logic, liquidity intelligence, vaults, and execution flows
- `apps/flutter_app`: main user app for web and mobile with market list, detail, trading, operations, and settings
- `apps/ai-service`: AI support endpoints used by backend workflows
- `predictflow`: standalone Dart companion service for local market simulation, previews, and simulated orders
- `postgres`: primary relational store
- `redis`: caching and real-time support

**Quick Start**

1. Review [.env.example](/workspaces/AetherPredict/.env.example) if you want to customize local settings.
2. Start the local Docker stack with `docker compose up -d`.
3. Open the backend at `http://localhost:8000`.
4. Optionally run the Flutter client locally.
5. Optionally start `predictflow/` for companion simulation features.

Start the main stack:

```bash
docker compose up -d
```

Main local endpoints:

- App/API: `http://localhost:8000`
- API docs: `http://localhost:8000/docs`
- Backend readiness: `http://localhost:8000/ready`
- AI service: `http://localhost:8010`
- Postgres: `localhost:5432`
- Redis: `localhost:6379`

**Environment**

Root environment values live in [.env.example](/workspaces/AetherPredict/.env.example).

Important settings:

- `DATABASE_URL`
- `REDIS_URL`
- `AI_SERVICE_URL`
- `JWT_SECRET`
- `OPENAI_API_KEY`
- `HASHKEY_RPC_URL`
- `FLUTTER_API_BASE_URL`
- `FLUTTER_WS_MARKETS_URL`

If `HASHKEY_RPC_URL` is not configured, blockchain-dependent wallet and portfolio flows may be partially degraded while the main market experience still works.

**What You Get**

The current AetherPredict stack includes:

- live market views with probability-aware spreads
- liquidity intelligence overlays across market cards and detail views
- slippage previews and execution-aware trading flows
- AI-supported market and anomaly workflows
- a dedicated operations surface for monitoring system activity
- a Dart companion engine for local simulated market reads and order flows

**Running the Backend Locally**

If you want to run the backend outside Docker:

```bash
cd apps/backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
PYTHONPATH=. .venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend docs:

- `http://localhost:8000/docs`
- `http://localhost:8000/openapi.json`

**Running the Flutter App**

The main Flutter application lives in `apps/flutter_app`.

Install dependencies:

```bash
cd apps/flutter_app
flutter pub get
```

Run on Chrome:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=WS_MARKETS_URL=ws://localhost:8000/ws/markets \
  --dart-define=PREDICTFLOW_BASE_URL=http://localhost:8081
```

You can also build for web:

```bash
flutter build web \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=WS_MARKETS_URL=ws://localhost:8000/ws/markets \
  --dart-define=PREDICTFLOW_BASE_URL=http://localhost:8081
```

More Flutter-specific notes are in [apps/flutter_app/README.md](/workspaces/AetherPredict/apps/flutter_app/README.md).

**PredictFlow Companion**

`predictflow/` is a pure Dart companion service. It replaces the older Node/TypeScript project and provides local simulated market snapshots, order previews, dashboard data, and simulated order execution for the Flutter app.

Run it separately when you want companion features online:

```bash
cd predictflow
dart pub get
dart run bin/server.dart
```

Default endpoint:

- `http://localhost:8081`

The Flutter app uses this service for:

- companion market snapshots
- simulated order previews
- simulated order placement
- companion dashboard and portfolio reads

**Core Product Areas**

The current AetherPredict experience emphasizes prediction-market-native liquidity tooling:

- bid/ask spread tiers on cards, details, and trading views
- YES/NO liquidity depth views
- probability ladder and liquidity imbalance metrics
- AI market-maker posture and uncertainty handling
- expiry liquidity decay warnings
- information shock response
- unified liquidity risk scoring
- smart liquidity vault concepts
- retail-friendly trade sizing and slippage previews

**Working with the API**

Useful local endpoints include:

- `GET /ready`
- `GET /docs`
- `GET /markets`
- `GET /markets/assets`
- `GET /liquidity/{market_id}`
- auth and trading routes exposed by the FastAPI backend

Example health check:

```bash
curl http://localhost:8000/ready
```

Example market asset request:

```bash
curl http://localhost:8000/markets/assets
```

The backend also exposes auth, market, trading, vault, and liquidity-related routes through the FastAPI application and interactive docs.

**Development Workflow**

Start infrastructure:

```bash
docker compose up -d
```

Run the backend locally if needed:

```bash
cd apps/backend
PYTHONPATH=. .venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Run Flutter locally:

```bash
cd apps/flutter_app
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Run PredictFlow locally:

```bash
cd predictflow
dart run bin/server.dart
```

Recommended local workflow:

1. Start `docker compose up -d`
2. Confirm backend readiness at `http://localhost:8000/ready`
3. Run Flutter locally if you want an interactive client session
4. Run `predictflow` when you want companion market simulation features enabled

**Testing and Verification**

Backend tests:

```bash
cd apps/backend
PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 PYTHONPATH=. .venv/bin/pytest -q
```

Flutter analysis:

```bash
cd apps/flutter_app
flutter analyze
```

Flutter tests:

```bash
cd apps/flutter_app
flutter test
```

PredictFlow tests:

```bash
cd predictflow
dart test
```

**Production Notes**

- The local Docker stack is intended for development and integration work.
- The backend depends on environment configuration for external providers and chain-connected features.
- The AI and liquidity components are designed to reinforce prediction markets as the core product, not to mimic forex or generic exchange infrastructure.
- Before production deployment, review secrets management, provider credentials, persistence, monitoring, and rate limiting.

**Troubleshooting**

- If the app loads but wallet data fails, check `HASHKEY_RPC_URL`.
- If companion market panels are empty, make sure `predictflow` is running on `http://localhost:8081` or update `PREDICTFLOW_BASE_URL`.
- If backend endpoints fail locally, confirm `docker compose ps` shows `backend`, `postgres`, `redis`, and `ai-service` as `Up`.
- If Flutter cannot connect to APIs, verify your `--dart-define` values match the backend host and websocket URL.
