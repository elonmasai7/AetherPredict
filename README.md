# AetherPredict

AetherPredict is a production-oriented decentralized prediction market platform built with Flutter, FastAPI, AI services, and Solidity on HashKey Chain.

## Architecture

- `apps/flutter_app`: single Flutter codebase for web, Android, and iOS
- `apps/backend`: FastAPI backend with PostgreSQL, Redis, JWT auth, REST APIs, and WebSocket streaming
- `apps/ai-service`: FastAPI AI microservice for resolution, sentiment, probability updates, and anomaly detection
- `apps/contracts`: Foundry workspace for Solidity contracts and deployment scripts
- `infra/docker`: container definitions and runtime assets

## Core capabilities

- Create and trade on-chain YES/NO markets
- Operate Strategy Vaults with AI- or human-managed execution and on-chain verification
- Enable copy trading with proportional risk controls and real-time replication
- Stream live probabilities and AI confidence updates
- Monitor autonomous liquidity and sentinel agents
- Submit disputes and review evidence
- Connect wallets via WalletConnect
- Support responsive web and native mobile experiences from one Flutter app

## Quick start

1. Copy `.env.example` to `.env`
2. Start infrastructure:
   - `docker compose up -d`
3. Backend:
   - `cd apps/backend`
   - `python -m venv .venv`
   - `pip install -r requirements.txt`
   - `python -m alembic upgrade head`
   - `uvicorn app.main:app --reload --port 8000`
4. AI service:
   - `cd apps/ai-service`
   - `py -3.12 -m venv .venv312`
   - `.venv312\\Scripts\\python -m pip install -r requirements.txt`
   - `.venv312\\Scripts\\python -m uvicorn app.main:app --reload --port 8010`
5. Flutter app:
   - `cd apps/flutter_app`
   - `flutter pub get`
   - `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=WS_MARKETS_URL=ws://localhost:8000/ws/markets --dart-define=WALLETCONNECT_PROJECT_ID=your_project_id`
6. Contracts:
   - `cd apps/contracts`
   - `forge install`
   - `forge test`

## Database and migrations

- Initialize schema with `cd apps/backend && alembic upgrade head`
- The backend no longer seeds demo data at startup; production data comes from real user actions, persisted records, and live market sync jobs
- Redis is used for market update pub/sub and websocket fanout on `/ws/markets`
- Backend startup now fails fast if Alembic migrations have not been applied

## Strategy Vaults and Copy Trading

- Vaults support `auto_execute_enabled` with allowlist enforcement for automated strategy execution.
- Configure allowlists via `.env`: `VAULT_AUTO_EXECUTE_DEFAULT_SLUGS`, `VAULT_AUTO_EXECUTE_ALLOWLIST_IDS`, `VAULT_AUTO_EXECUTE_ALLOWLIST_MANAGER_ROLES`.
- Vault collateral decimals are pulled from ERC-20 `decimals()` at creation time and cached in-process for faster onboarding.
- New endpoint: `POST /vaults/{vault_id}/auto-execute` with body `{ "auto_execute_enabled": true }` (requires `admin` or `manager` role).

## Local verification

- Verified backend import: `AetherPredict API`
- Verified AI service import in `apps/ai-service/.venv312`: `AetherPredict AI Service`
- If `docker compose up -d postgres redis` fails on Windows, start Docker Desktop first so the Linux engine pipe is available

## HashKey deployment envs

- Set `HASHKEY_RPC_URL`, `HASHKEY_CHAIN_ID`, `HASHKEY_PRIVATE_KEY`, and `TREASURY_ADDRESS`
- Optional deployment metadata fields are included in `.env.example` for explorer and deployed contract addresses

## Deployment targets

- Flutter web build for static hosting or CDN-backed edge deployment
- FastAPI services on Render, Railway, Fly.io, or container platforms
- PostgreSQL and Redis as managed services
- Foundry deployment scripts for HashKey Chain testnet and mainnet
