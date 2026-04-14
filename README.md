# AetherPredict

AetherPredict is an AI-powered on-chain prediction market on HashKey Chain that uses autonomous agents, smart liquidity, and AI-based resolution to deliver secure, real-time forecasting, trading, and risk intelligence for DeFi and financial markets.

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
- Operate Forecast Strategy Vaults with AI- or human-managed allocation and on-chain verification
- Enable copy forecasts with proportional risk controls and real-time replication
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
- If `docker compose up -d postgres redis` fails on Windows, start Docker Desktop first so the Linux engine pipe is available

## HashKey deployment envs

- Set `HASHKEY_RPC_URL`, `HASHKEY_CHAIN_ID`, `HASHKEY_PRIVATE_KEY`, and `TREASURY_ADDRESS`
- Optional deployment metadata fields are included in `.env.example` for explorer and deployed contract addresses

## Deployment targets

- Flutter web build for static hosting or CDN-backed edge deployment
- FastAPI services on Render, Railway, Fly.io, or container platforms
- PostgreSQL and Redis as managed services
- Foundry deployment scripts for HashKey Chain testnet and mainnet
