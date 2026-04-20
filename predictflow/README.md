# PredictFlow Dart

This directory used to contain the old Node/TypeScript `predictflow/` project.
It has been replaced with a pure Dart package.

## What is here now

- `lib/src/models.dart`: market, order, trade, liquidity, and portfolio models
- `lib/src/engine.dart`: in-memory prediction market engine
- `bin/server.dart`: Shelf HTTP server exposing REST endpoints
- `test/engine_test.dart`: basic Dart tests

## Run

```bash
cd predictflow
dart pub get
dart run bin/server.dart
```

Server default:

- `http://localhost:8081`

## Endpoints

- `GET /health`
- `GET /api/markets`
- `GET /api/markets/:marketId`
- `GET /api/dashboard/:wallet`
- `POST /api/preview`
- `POST /api/orders`
- `POST /api/liquidity`
- `POST /api/resolve`

## Test

```bash
cd predictflow
dart test
```
