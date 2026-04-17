#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_URL="${API_BASE_URL:-http://localhost:8000}"
CHROMEDRIVER_BIN="${CHROMEDRIVER_BIN:-chromedriver}"
CHROMEDRIVER_PORT="${CHROMEDRIVER_PORT:-4444}"

if ! command -v "$CHROMEDRIVER_BIN" >/dev/null 2>&1; then
  echo "Missing chromedriver. Install it or set CHROMEDRIVER_BIN to the executable path." >&2
  exit 1
fi

if ! curl -sS "$BASE_URL/health" >/dev/null; then
  echo "Backend is not healthy at $BASE_URL. Start the backend first." >&2
  exit 1
fi

"$CHROMEDRIVER_BIN" --port="$CHROMEDRIVER_PORT" >/tmp/aetherpredict-chromedriver.log 2>&1 &
CHROMEDRIVER_PID=$!
cleanup() {
  kill "$CHROMEDRIVER_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cd "$ROOT_DIR"

/home/codespace/flutter/bin/flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/strategy_engine_flow_test.dart \
  -d web-server \
  --browser-name=chrome \
  --headless \
  --dart-define=API_BASE_URL="$BASE_URL"
