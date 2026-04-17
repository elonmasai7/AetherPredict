from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


def _request(
    method: str,
    url: str,
    *,
    token: str | None = None,
    payload: dict | None = None,
) -> tuple[int, bytes, dict[str, str]]:
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            return response.status, response.read(), dict(response.headers.items())
    except urllib.error.HTTPError as error:
        return error.code, error.read(), dict(error.headers.items())


def _json_request(
    method: str,
    url: str,
    *,
    token: str | None = None,
    payload: dict | None = None,
) -> tuple[int, dict]:
    status, body, _ = _request(method, url, token=token, payload=payload)
    if not body:
        return status, {}
    return status, json.loads(body.decode("utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Smoke-test the Strategy Engine API against a local backend."
    )
    parser.add_argument(
        "--base-url",
        default="http://localhost:8000",
        help="Backend base URL. Default: http://localhost:8000",
    )
    parser.add_argument(
        "--download-dir",
        default="/tmp",
        help="Directory where archive downloads should be written.",
    )
    args = parser.parse_args()

    suffix = int(time.time())
    email = f"strategy-smoke-{suffix}@example.com"
    password = "password123"
    base_url = args.base_url.rstrip("/")

    status, health = _json_request("GET", f"{base_url}/health")
    if status != 200:
        print(f"health check failed: {status} {health}", file=sys.stderr)
        return 1

    register_status, register_payload = _json_request(
        "POST",
        f"{base_url}/auth/register",
        payload={
            "email": email,
            "password": password,
            "display_name": "Strategy Smoke",
        },
    )
    if register_status not in (200, 201):
        print(
            f"registration failed: {register_status} {register_payload}",
            file=sys.stderr,
        )
        return 1

    login_status, login_payload = _json_request(
        "POST",
        f"{base_url}/auth/login",
        payload={"email": email, "password": password},
    )
    if login_status != 200:
        print(f"login failed: {login_status} {login_payload}", file=sys.stderr)
        return 1

    token = login_payload["access_token"]
    build_status, build_payload = _json_request(
        "POST",
        f"{base_url}/strategy-engine/build",
        token=token,
        payload={
            "prompt": "Build an innovative cross-market arbitrage model for BTC prediction markets using ETF flows, sentiment, and public catalyst data."
        },
    )
    if build_status != 200:
        print(f"build failed: {build_status} {build_payload}", file=sys.stderr)
        return 1

    strategy_id = build_payload["strategy"]["id"]

    for command in ("init", "start", "deploy"):
        action_status, action_payload = _json_request(
            "POST",
            f"{base_url}/strategy-engine/strategies/{strategy_id}/canon/{command}",
            token=token,
        )
        if action_status != 200:
            print(
                f"canon {command} failed: {action_status} {action_payload}",
                file=sys.stderr,
            )
            return 1

    for path in (
        "/strategy-engine/state",
        "/strategy-engine/templates",
        "/strategy-engine/monitor",
        "/strategy-engine/ranking",
        f"/strategy-engine/strategies/{strategy_id}/export/manifest",
    ):
        api_status, api_payload = _json_request(
            "GET",
            f"{base_url}{path}",
            token=token,
        )
        if api_status != 200:
            print(f"request failed for {path}: {api_status} {api_payload}", file=sys.stderr)
            return 1

    for archive_format in ("zip", "tar"):
        archive_status, archive_body, _ = _request(
            "GET",
            f"{base_url}/strategy-engine/strategies/{strategy_id}/export?format={urllib.parse.quote(archive_format)}",
            token=token,
        )
        if archive_status != 200:
            print(
                f"archive export failed for {archive_format}: {archive_status}",
                file=sys.stderr,
            )
            return 1
        output_path = f"{args.download_dir.rstrip('/')}/strategy-engine-smoke.{archive_format}"
        with open(output_path, "wb") as handle:
            handle.write(archive_body)
        print(f"wrote {output_path}")

    print("Strategy Engine smoke test passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
