from __future__ import annotations

import argparse
import json
from pathlib import Path

from app.services.strategy_engine_service import StrategyEngineService


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Canon CLI for AetherPredict Strategy Engine")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="Scaffold a new prediction strategy project")
    init_parser.add_argument("--name", required=True)
    init_parser.add_argument("--prompt", required=True)
    init_parser.add_argument("--template", default="event-forecasting")
    init_parser.add_argument("--market", default="Custom prediction market")
    init_parser.add_argument("--target-dir", default=".")

    start_parser = subparsers.add_parser("start", help="Advance a Canon project into active workflow execution")
    start_parser.add_argument("--target-dir", default=".")

    deploy_parser = subparsers.add_parser("deploy", help="Mark a Canon project ready for live deployment")
    deploy_parser.add_argument("--target-dir", default=".")

    monitor_parser = subparsers.add_parser("monitor", help="Inspect the local Canon project workflow state")
    monitor_parser.add_argument("--target-dir", default=".")

    return parser


def main() -> int:
    args = _parser().parse_args()
    if args.command == "init":
        files = StrategyEngineService.project_files_for_strategy(
            strategy_name=args.name,
            prompt=args.prompt,
            template_key=args.template,
            template_name=args.template.replace("-", " ").title(),
            market_title=args.market,
            confidence=0.72,
            automation_modes=StrategyEngineService._automation_modes(args.prompt),
        )
        target_dir = Path(args.target_dir).resolve()
        StrategyEngineService.write_project_files(target_dir, files)
        print(f"Canon project scaffolded at {target_dir}")
        return 0

    target_dir = Path(args.target_dir).resolve()
    if args.command in {"start", "deploy"}:
        payload = StrategyEngineService.update_local_project_stage(target_dir, args.command)
        print(json.dumps(payload, indent=2))
        return 0

    lock_path = target_dir / "canon.lock.json"
    if not lock_path.exists():
        raise SystemExit(f"Missing Canon project at {target_dir}")
    print(lock_path.read_text(encoding="utf-8"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
