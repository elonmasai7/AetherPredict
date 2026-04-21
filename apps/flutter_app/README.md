# AetherPredict Flutter App

This Flutter client is the main NBA prediction interface for AetherPredict.

It now centers the product around:

- live NBA game context
- NBA prediction markets
- AI agents
- a dedicated news module
- leaderboard tracking
- a prompt-driven strategy lab

## Main Routes

- `/overview`
- `/live-games`
- `/markets`
- `/my-predictions`
- `/ai-agents`
- `/news`
- `/leaderboard`
- `/strategy-lab`

## Local Run

```bash
cd apps/flutter_app
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=WS_MARKETS_URL=ws://localhost:8000/ws/markets \
  --dart-define=PREDICTFLOW_BASE_URL=http://localhost:8081
```

## Web Build

```bash
cd apps/flutter_app
flutter build web
```

The backend Docker image copies `build/web`, so build the web bundle before rebuilding the backend container if you want the newest frontend served from `http://localhost:8000`.

## Integration Notes

The Flutter app consumes the NBA-focused backend endpoints:

- `GET /platform/home`
- `POST /platform/strategy/preview`
- `GET /news`
- `GET /markets`
- `POST /trades`

## Existing Test Script

If you want to run the browser-based integration flow:

```bash
cd apps/flutter_app
./scripts/run_web_strategy_engine_integration.sh
```
