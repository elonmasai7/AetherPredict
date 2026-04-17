# AetherPredict Flutter App

## Web integration smoke flow

The Strategy Engine UI smoke flow can run in a real browser target instead of requiring Linux desktop support.

Prerequisites:

- local backend healthy at `http://localhost:8000`
- `chromedriver` installed and on `PATH`

Run:

```bash
cd apps/flutter_app
./scripts/run_web_strategy_engine_integration.sh
```

Optional overrides:

```bash
API_BASE_URL=http://localhost:8000 \
CHROMEDRIVER_BIN=/path/to/chromedriver \
CHROMEDRIVER_PORT=4444 \
./scripts/run_web_strategy_engine_integration.sh
```

The script launches `chromedriver` and runs:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/strategy_engine_flow_test.dart \
  -d web-server \
  --browser-name=chrome \
  --headless \
  --dart-define=API_BASE_URL=http://localhost:8000
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
