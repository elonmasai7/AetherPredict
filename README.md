# AetherPredict

AetherPredict is an AI-powered on-chain prediction market on HashKey Chain that uses autonomous agents, smart liquidity, and AI-based resolution to deliver secure, real-time forecasting, prediction automation, and risk intelligence for DeFi and financial markets.

## Architecture

- `apps/flutter_app`: single Flutter codebase for web, Android, and iOS
- `apps/backend`: FastAPI backend with PostgreSQL, Redis, JWT auth, REST APIs, and WebSocket streaming
- `apps/ai-service`: FastAPI AI microservice for resolution, sentiment, probability updates, and anomaly detection
- `apps/contracts`: Foundry workspace for Solidity contracts and deployment scripts
- `infra/docker`: container definitions and runtime assets

## Blockchain Architecture: Token Contracts and HashKey Chain Integration

AetherPredict is designed as a HashKey Chain-native financial protocol where execution, settlement, and auditability are on-chain by default. HashKey Chain is the execution and settlement layer for market creation, position lifecycle, LP capital, dispute staking, vault strategy execution, governance, reward distribution, and final outcome storage. All financial state transitions are committed on-chain and validated against canonical contract state. Off-chain services (UI, backend, AI engine) are coordinators and provers, not financial ledgers.

### 1. Core On-Chain Infrastructure

- HashKey Chain is the single source of truth for market state and treasury state.
- Every position change is an on-chain state transition: open position, close position, LP deposit/withdrawal, vault subscription/redemption, dispute bond, resolution finalization, and reward claim.
- System boundaries include the execution plane (market, token, vault, and staking contracts on HashKey Chain), coordination plane (API/websocket indexing and signed transaction routing), and intelligence plane (AI resolution and risk models submitting attestations to on-chain resolvers).
- Integrity invariant: if an action does not produce a finalized HashKey transaction, the action is not financially valid.

### 2. Token Contract System

Production deployment uses a multi-contract topology with strict separation of concerns:

1. `AETHToken.sol`: ERC-20 governance and utility token with mint schedule controls and role-gated emissions.
2. `OutcomeTokenFactory.sol`: deterministic deployment (`CREATE2`) of market-scoped YES/NO ERC-20 outcome tokens.
3. `PredictionMarket.sol`: core market engine for collateralization, position mint/burn, resolution, and redemption.
4. `LiquidityVault.sol`: market liquidity vault handling LP shares, fee accounting, and incentive distribution.
5. `GovernanceStaking.sol`: staking, dispute bonding, vote weight accounting, slashing, and reward vesting.

`PredictionMarketFactory.sol` is the registry/controller layer that creates and governs these market contracts on HashKey Chain.

Contract-level privileges are managed with role-based access control (`DEFAULT_ADMIN_ROLE`, `MARKET_ADMIN_ROLE`, `RESOLVER_ROLE`, `RISK_GUARDIAN_ROLE`) behind multisig/timelock governance.

### 3. AETH Governance + Utility Token

`AETH` is the native ERC-20 protocol token with an example max supply of `100,000,000` and utility across governance and protocol economics.

- Core ERC-20 interface: `transfer()`, `approve()`, `transferFrom()`.
- Governance/staking extensions: `stake()`, `claimRewards()`, `vote()`.
- Utility surface: governance voting rights and proposal quorum participation; protocol fee discounts for staked balances; dispute participation collateral and juror staking; vault incentive emissions and liquidity mining rewards; boosted yield multipliers for long-duration staking cohorts.

Emission policy is designed for predictable dilution: treasury-controlled vesting, epoch-based reward streams, and transparent on-chain emission events.

### 4. Outcome Tokens

Each binary market mints two ERC-20 outcome tokens via `OutcomeTokenFactory.sol`:

- `pYES` (example: `BTC_120K_YES`)
- `pNO` (example: `BTC_120K_NO`)

Lifecycle:

- On position open, collateral is deposited and corresponding outcome tokens are minted to the trader.
- On close-before-expiry, tokens are burned and collateral is returned per pool pricing logic.
- On final resolution, winning tokens redeem `1:1` against settlement collateral; losing tokens are non-redeemable and economically expire.

Outcome tokens are market-isolated to prevent cross-market contamination and simplify risk accounting.

### 5. Market Factory Contract

`PredictionMarketFactory.sol` is the canonical market registry and deployment gateway on HashKey Chain.

- Responsibilities: `createMarket()` defines expiry, metadata, oracle source, resolution policy, and deploys outcome tokens; `pauseMarket()` acts as an emergency circuit breaker; `resolveMarket()` commits final outcome after resolver/dispute checks.
- Registry guarantees: globally unique `marketId`, immutable creation metadata hash, and append-only resolution/dispute event history.

No market is considered valid unless created and registered through the factory.

### 6. HashKey Chain Usage (Critical Path)

HashKey Chain is integrated into every critical protocol workflow:

- A. Low-cost transactions: prediction placement, position close, staking, and reward claims are executed as native on-chain transactions with fee-conscious calldata design.
- B. Fast finality: fast confirmation supports low-latency market updates, rapid settlement handoff, and AI-assisted execution loops.
- C. Compliance-ready infrastructure: institutional security posture, deterministic settlement logs, and immutable audit trails support future regulated product packaging.
- D. Ecosystem token support: stablecoin and HashKey-native asset collateral (`USDC`, `USDT`, HK ecosystem assets) are supported through token allowlists and risk parameters.

### 7. Smart Liquidity on HashKey

Each market is backed by smart liquidity segmented by outcome exposure:

- YES pool
- NO pool
- depth tracking and utilization metrics
- dynamic spread logic based on imbalance and volatility regimes

LPs deposit collateral into `PredictionLiquidityVault.sol` (production alias of `LiquidityVault.sol`) and receive vault shares representing pro-rata claims on pool NAV.

LP reward streams:

- protocol trading fees
- AETH liquidity incentives
- optional campaign boosts for strategic markets

### 8. AI Resolution + On-Chain Settlement

Resolution finality always terminates on-chain.

Settlement flow:

- market reaches expiry timestamp
- AI resolution engine computes outcome and confidence score
- resolver submits signed resolution payload to settlement contract
- dispute window opens for bonded challenges
- if undisputed (or appeal finalized), market status is finalized on-chain
- winning holders call `claimWinnings()`; settlement burns winning tokens and releases collateral

Primary settlement functions:

- `settleYes()`
- `settleNo()`
- `claimWinnings()`

Confidence scores and evidence URIs are stored as immutable resolution metadata for post-trade auditability.

### 9. Staking + Dispute Contract

`GovernanceStaking.sol` governs economic security around market integrity:

- Users stake `AETH` to dispute outcomes.
- Stakers vote on appeals and validate/challenge AI decisions.
- Vote power is stake-weighted and time-weighted.
- Invalid disputes can be penalized; successful challengers are compensated from dispute bonds.

HashKey Chain persists all dispute primitives:

- staked amount
- vote weight snapshots
- dispute lifecycle events
- final adjudication history

### 10. Vault + Copy Forecast Settlement

Vault strategy execution and copy-forecast replication are settled on HashKey Chain:

- user signs intent (`EIP-712`)
- relayer/keeper submits transaction to vault/market contract
- contract executes trade with risk guardrails
- execution and position ownership are confirmed on-chain

This ensures verifiable attribution, deterministic PnL accounting, and trust-minimized copy-forecast replication.

### 11. Explorer + Transparency

All user-visible financial actions are explorer-verifiable.

The product UI surfaces:

- transaction hash
- block number
- confirmation timestamp/finality status
- direct HashKey explorer link

This creates transparent, user-auditable proof for every material financial operation.

### 12. Final Architecture Goal

HashKey Chain is the financial settlement, security, liquidity, and trust infrastructure powering AetherPredict. It is not a passive hosting layer; it is the protocol's core execution environment for market integrity, capital movement, governance legitimacy, and institutional-grade auditability.

## Core capabilities

- Create and forecast on-chain YES/NO event markets
- Build, deploy, and monitor prediction-market strategies with the AetherPredict Strategy Engine
- Generate Canon CLI prediction projects from plain-language prompts and export real scaffold files
- Operate Forecast Strategy Vaults with AI- or human-managed allocation and on-chain verification
- Enable copy forecasts with proportional risk controls and real-time replication
- Stream live probabilities and AI confidence updates
- Monitor autonomous liquidity and sentinel agents
- Submit disputes and review evidence
- Connect wallets via WalletConnect
- Support responsive web and native mobile experiences from one Flutter app

## Strategy Engine

The `AetherPredict Strategy Engine` is a prediction-first workflow system for building and operating forecasting automations. It is explicitly aligned to prediction markets, event forecasting, probability intelligence, and AI-assisted decision-making.

It is not a forex bot framework, exchange arbitrage shell, or generic price-speculation console. Strategy Engine automations are designed for prediction-market microstructures and event probability edges.

### Canon workflow

- `canon init`: scaffold a prediction strategy project from a backend template
- `canon start`: advance the strategy through data ingestion, analysis, prediction, and execution readiness
- `canon deploy`: register a validated strategy for live prediction-market execution
- `canon monitor`: inspect workflow state and live forecast logs

### Strategy templates

- `Event Probability Model`
- `Sentiment-Based Forecast Engine`
- `Cross-Market Correlation Predictor`
- `Macro Event Forecast Template`

Each generated project includes:

- typed interfaces
- data ingestion modules
- prediction logic
- confidence scoring
- execution hooks for prediction markets

### AI Builder and automation modes

Users can describe a strategy in plain language and the backend will persist a live workflow record, generate a Canon project, and return scaffold files for export.

Supported prompt patterns include:

- `Arbitrage Detection`: exploit price discrepancies for the same event across related prediction markets
- `Cross-Market Analysis`: correlate related markets and act on repricing lag
- `Speed-Based Opportunity`: react to public statistical inputs before prices fully adjust
- `Innovative`: invent a new prediction-market strategy from scratch by combining novel signals and data sources

Example prompt:

```text
Build an arbitrage detection model for the same event across related BTC prediction markets using ETF flows and sentiment.
```

### Strategy Engine UI

The Flutter client exposes Strategy Engine as a first-class navigation section with these pages:

- `My Strategies`: live strategy registry, Canon actions, and export flow
- `Templates`: backend-backed forecasting templates
- `AI Builder`: plain-language strategy generation and Canon project creation
- `Automation Monitor`: terminal-style pipeline and forecast log view
- `Performance Ranking`: prediction strategy leaderboard focused on forecast quality

### Live data flow

The Strategy Engine UI now reads from real backend endpoints rather than seeded demo data.

High-level flow:

1. User submits a prompt in `AI Builder`
2. Backend selects a forecasting template and automation modes
3. Backend persists strategy workflow state under the authenticated user profile
4. Canon scaffold files are generated for export or local CLI execution
5. Flutter pages refresh from the Strategy Engine API for strategy state, monitor logs, and ranking
6. Canon commands (`init`, `start`, `deploy`) update the same persisted workflow record

### Backend Strategy Engine APIs

- `GET /strategy-engine/state`
- `GET /strategy-engine/templates`
- `POST /strategy-engine/build`
- `POST /strategy-engine/strategies/{strategy_id}/canon/{command}`
- `GET /strategy-engine/monitor`
- `GET /strategy-engine/ranking`
- `GET /strategy-engine/strategies/{strategy_id}/export?format=zip`
- `GET /strategy-engine/strategies/{strategy_id}/export?format=tar`
- `GET /strategy-engine/strategies/{strategy_id}/export/manifest`

The archive export endpoints return downloadable Canon project bundles, while the manifest endpoint returns the structured file list used by the UI.

Backend implementation lives in:

- `apps/backend/app/api/strategy_engine.py`
- `apps/backend/app/services/strategy_engine_service.py`
- `apps/backend/app/schemas/strategy_engine.py`

Flutter integration lives in:

- `apps/flutter_app/lib/src/features/strategy_engine/`
- `apps/flutter_app/lib/src/core/api_client.dart`
- `apps/flutter_app/lib/src/core/providers.dart`

### Canon CLI script

The backend includes a local CLI entrypoint at `apps/backend/app/scripts/canon_cli.py`.

CLI usage and endpoint notes are also documented in `apps/backend/app/scripts/README.md`.

Examples:

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

### OpenAPI and Swagger usage

When the backend is running, FastAPI exposes:

- `http://localhost:8000/docs`
- `http://localhost:8000/redoc`
- `http://localhost:8000/openapi.json`

Example authenticated Strategy Engine session with `curl`:

```bash
BASE_URL=http://localhost:8000
EMAIL="strategy$(date +%s)@example.com"
PASSWORD="password123"

curl -sS -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"display_name\":\"Strategy Docs Demo\"}"

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

curl -sS -X POST "$BASE_URL/strategy-engine/strategies/$STRATEGY_ID/canon/init" \
  -H "Authorization: Bearer $TOKEN"

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

For a backend-only smoke pass, there is also a Python helper:

```bash
cd apps/backend
PYTHONPATH=. .venv/bin/python -m app.scripts.strategy_engine_smoke --base-url http://localhost:8000
```

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

## Production config

Backend production startup now enforces a few non-negotiable safety rules:

- `APP_ENV=production`
- `JWT_SECRET` must be strong and at least 32 characters
- `CORS_ALLOWED_ORIGINS` must be explicitly set and cannot contain `*`
- API docs are disabled by default in production

Example:

```bash
APP_ENV=production
JWT_SECRET=replace-with-a-long-random-secret-value-at-least-32-chars
CORS_ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
API_DOCS_ENABLED=false
```

The Strategy Engine now persists production workflow state in dedicated database tables instead of `workspace_preferences`, so new deploys should run:

```bash
cd apps/backend
alembic upgrade head
```

## Strategy Engine quick demo

After the backend and Flutter app are running:

1. Sign in with a local account
2. Open `Strategy Engine -> AI Builder`
3. Submit a prompt for arbitrage, cross-market lag, speed-based, or innovative forecasting automation
4. Open `My Strategies` and run `canon init`, `canon start`, or `canon deploy`
5. Open `Automation Monitor` to review workflow logs
6. Open `Performance Ranking` to inspect forecast-quality metrics

## Demo login (local)

- Email: `demo@aetherpredict.ai`
- Password: `DemoPass123!`
- If this account does not exist yet, create it once after the backend is running:

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@aetherpredict.ai","password":"DemoPass123!","display_name":"Demo User"}'
```

- A `409 Email already registered` response means the demo login is already available and can be used as-is.

## Database and migrations

- Initialize schema with `cd apps/backend && alembic upgrade head`
- The backend does not auto-seed synthetic records at startup; production data comes from real user actions, persisted records, and live market sync jobs
- Redis is used for market update pub/sub and websocket fanout on `/ws/markets`
- Backend startup now fails fast if Alembic migrations have not been applied

## Strategy Vaults and Copy Forecasts

- Vaults support `auto_execute_enabled` with allowlist enforcement for automated strategy execution.
- Configure allowlists via `.env`: `VAULT_AUTO_EXECUTE_DEFAULT_SLUGS`, `VAULT_AUTO_EXECUTE_ALLOWLIST_IDS`, `VAULT_AUTO_EXECUTE_ALLOWLIST_MANAGER_ROLES`.
- Vault collateral decimals are pulled from ERC-20 `decimals()` at creation time and cached in-process for faster onboarding.
- New endpoint: `POST /vaults/{vault_id}/auto-execute` with body `{ "auto_execute_enabled": true }` (requires `admin` or `manager` role).

## Local verification

- Verified backend import: `AetherPredict API`
- Verified AI service import in `apps/ai-service/.venv312`: `AetherPredict AI Service`
- Verified Strategy Engine backend workflow test:
  - `cd apps/backend && PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 PYTHONPATH=. .venv/bin/pytest tests/test_strategy_engine_api.py`
- Verified Strategy Engine Flutter route/tab navigation test:
  - `cd apps/flutter_app && flutter test test/strategy_engine_navigation_test.dart`
- Verified Strategy Engine Flutter authenticated screen test:
  - `cd apps/flutter_app && flutter test test/strategy_engine_screens_test.dart`
- Local-backend Strategy Engine integration test:
  - `cd apps/flutter_app && flutter test integration_test/strategy_engine_flow_test.dart -d chrome --dart-define=API_BASE_URL=http://localhost:8000`
- Browser-based Strategy Engine integration execution:
  - `cd apps/flutter_app && ./scripts/run_web_strategy_engine_integration.sh`
  - Requires `chromedriver` plus a healthy backend on `http://localhost:8000` by default
  - Override the backend target with `API_BASE_URL=http://your-host:8000`
- If `docker compose up -d postgres redis` fails on Windows, start Docker Desktop first so the Linux engine pipe is available

## HashKey deployment envs

- Set `HASHKEY_RPC_URL`, `HASHKEY_CHAIN_ID`, `HASHKEY_PRIVATE_KEY`, and `TREASURY_ADDRESS`
- Optional deployment metadata fields are included in `.env.example` for explorer and deployed contract addresses

## Deployment targets

- Flutter web build for static hosting or CDN-backed edge deployment
- FastAPI services on Render, Railway, Fly.io, or container platforms
- PostgreSQL and Redis as managed services
- Foundry deployment scripts for HashKey Chain testnet and mainnet
