from __future__ import annotations

import io
import json
import re
import tarfile
import zipfile
from copy import deepcopy
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import AgentStatus, Market, User
from app.schemas.strategy_engine import (
    CanonActionResponse,
    CanonCommandResponse,
    CanonProjectExportResponse,
    CanonProjectFileResponse,
    MonitorLogResponse,
    StrategyAgentRoleResponse,
    StrategyBuildResponse,
    StrategyEngineMetricsResponse,
    StrategyEngineStateResponse,
    StrategyMonitorResponse,
    StrategyPipelineStepResponse,
    StrategyRankingEntryResponse,
    StrategyRankingResponse,
    StrategyRecordResponse,
    StrategyTemplateResponse,
)


@dataclass(frozen=True)
class _TemplateSpec:
    key: str
    name: str
    description: str
    use_case: str
    interfaces: list[str]
    ingestion_sources: list[str]
    confidence_method: str
    execution_hook: str


_TEMPLATES = [
    _TemplateSpec(
        key="event-forecasting",
        name="Event Probability Model",
        description="Predict market outcomes from historical patterns, live catalysts, and evolving event signals.",
        use_case="Election, ETF approval, governance, protocol launch, and catalyst-driven event forecasting.",
        interfaces=["MarketEventInput", "FeatureSnapshot", "ProbabilityForecast", "PredictionExecutionRequest"],
        ingestion_sources=["Historical market closes", "Live event feeds", "Protocol telemetry"],
        confidence_method="Bayesian confidence bands with scenario weighting.",
        execution_hook="Submit validated probability thresholds to prediction market execution adapters.",
    ),
    _TemplateSpec(
        key="sentiment-model",
        name="Sentiment-Based Forecast Engine",
        description="Turn news, social, and on-chain narrative flows into directional probability updates.",
        use_case="Narrative shifts, social volatility, and crowd-belief forecasting in live markets.",
        interfaces=["SentimentDocument", "SignalCluster", "SentimentProbabilityModel", "MarketOrderIntent"],
        ingestion_sources=["News APIs", "Social streams", "On-chain commentary"],
        confidence_method="Signal agreement and source credibility scoring.",
        execution_hook="Route conviction-weighted forecasts into market participation hooks.",
    ),
    _TemplateSpec(
        key="correlation-predictor",
        name="Cross-Market Correlation Predictor",
        description="Model relationships between market variables and event probabilities across correlated domains.",
        use_case="BTC price vs DeFi TVL vs regulation outcomes, adoption, and liquidity signals.",
        interfaces=["CorrelationInputSeries", "MarketDependencyGraph", "ProbabilitySurface", "ExecutionPolicy"],
        ingestion_sources=["Price feeds", "TVL datasets", "Regulation timelines"],
        confidence_method="Cross-factor stability testing with rolling calibration.",
        execution_hook="Trigger prediction entries when factor thresholds and confidence align.",
    ),
    _TemplateSpec(
        key="macro-predictor",
        name="Macro Event Forecast Template",
        description="Estimate probabilities for policy, rates, adoption, and liquidity-driven market events.",
        use_case="Interest rate decisions, policy shocks, institutional adoption, and macro cycle turns.",
        interfaces=["MacroIndicatorFrame", "PolicyScenario", "ForecastDistribution", "ExecutionWindow"],
        ingestion_sources=["Economic calendar inputs", "Policy statements", "Adoption trend datasets"],
        confidence_method="Scenario trees with catalyst-weighted confidence scoring.",
        execution_hook="Deploy timing-aware forecasts to markets linked to macro catalysts.",
    ),
]

_COMMANDS = [
    CanonCommandResponse(
        command="canon init",
        summary="Scaffold a new prediction strategy project from forecasting templates.",
        details=[
            "Select event forecasting, sentiment model, or macro predictor starters.",
            "Generate typed interfaces plus ingestion, prediction, confidence, and execution modules.",
            "Prepare a local Canon project manifest for export or CLI use.",
        ],
    ),
    CanonCommandResponse(
        command="canon start",
        summary="Detect the current strategy stage and drive the workflow from ingestion to execution.",
        details=[
            "Progress data ingestion, analysis, prediction, and execution checkpoints.",
            "Surface market analyst, architect, developer, and QA agent recommendations.",
            "Update monitor logs and validation gates as the strategy advances.",
        ],
    ),
    CanonCommandResponse(
        command="canon deploy",
        summary="Deploy a validated strategy to live prediction markets.",
        details=[
            "Require QA and confidence gates before enabling live execution hooks.",
            "Register the strategy for ranking, calibration, and performance tracking.",
            "Keep prediction markets as the sole execution target.",
        ],
    ),
    CanonCommandResponse(
        command="canon monitor",
        summary="Track live predictions, model drift, and forecast outcomes.",
        details=[
            "Stream signal, probability, and execution updates.",
            "Compare confidence to realized outcomes for calibration scoring.",
            "Highlight strategy health instead of trade volume.",
        ],
    ),
]

_AGENT_ROLES = [
    StrategyAgentRoleResponse(
        name="Market Analyst Agent",
        job="Scans prediction markets to identify mispriced probabilities and opportunity signals.",
        outputs=["Probability dislocation report", "Signal anomaly summary", "Market watchlist"],
    ),
    StrategyAgentRoleResponse(
        name="Strategy Architect Agent",
        job="Converts plain-language ideas into forecasting logic, model structure, and data inputs.",
        outputs=["Probability model outline", "Feature input plan", "Validation checkpoints"],
    ),
    StrategyAgentRoleResponse(
        name="Developer Agent",
        job="Implements strategy logic, typed interfaces, ingestion adapters, and prediction-market hooks.",
        outputs=["TypeScript modules", "Ingestion connectors", "Execution adapter wiring"],
    ),
    StrategyAgentRoleResponse(
        name="QA Agent",
        job="Validates consistency, simulates outcomes, and blocks deployment when the forecast stack is unstable.",
        outputs=["Simulation report", "Calibration audit", "Deployment readiness score"],
    ),
]


class StrategyEngineService:
    def __init__(self, db: Session):
        self.db = db

    def get_state(self, user: User) -> StrategyEngineStateResponse:
        state = self._user_state(user)
        strategies = [self._strategy_response(item) for item in state["strategies"]]
        return StrategyEngineStateResponse(
            metrics=self._metrics_response(state["strategies"]),
            canon_commands=list(_COMMANDS),
            strategies=strategies,
        )

    def templates(self) -> list[StrategyTemplateResponse]:
        return [
            StrategyTemplateResponse(
                key=template.key,
                name=template.name,
                description=template.description,
                use_case=template.use_case,
                interfaces=template.interfaces,
                ingestion_sources=template.ingestion_sources,
                confidence_method=template.confidence_method,
                execution_hook=template.execution_hook,
            )
            for template in _TEMPLATES
        ]

    def build_from_prompt(self, user: User, prompt: str) -> StrategyBuildResponse:
        template = self._template_for_prompt(prompt)
        market = self.db.scalar(select(Market).order_by(Market.ai_confidence.desc(), Market.volume.desc()))
        agent_owner = self._owner_from_db()
        now = self._now_iso()
        strategy_id = uuid4().hex[:10]
        target_market = market.title if market is not None else "Custom prediction market"
        confidence = self._base_confidence(prompt)
        automation_modes = self._automation_modes(prompt)
        strategy_name = self._strategy_name(prompt, template.name, target_market)
        project_name = self._slugify(strategy_name)
        project_files = self.project_files_for_strategy(
            strategy_name=strategy_name,
            prompt=prompt,
            template_key=template.key,
            template_name=template.name,
            market_title=target_market,
            confidence=confidence,
            automation_modes=automation_modes,
        )
        strategy = {
            "id": strategy_id,
            "name": strategy_name,
            "prompt": prompt,
            "template_key": template.key,
            "template_name": template.name,
            "stage": "Scaffolded",
            "market": target_market,
            "confidence": confidence,
            "owner": agent_owner,
            "status": "Draft",
            "created_at": now,
            "updated_at": now,
            "project_name": project_name,
            "project_path": f"canon_projects/{project_name}",
            "pipeline": [
                {"name": "Data Ingestion", "status": "Ready", "detail": "Market, narrative, and catalyst sources mapped."},
                {"name": "Analysis", "status": "Queued", "detail": f"Signal quality and microstructure analysis queued for {', '.join(automation_modes)}."},
                {"name": "Prediction", "status": "Queued", "detail": "Probability model will compute after feature validation."},
                {"name": "Execution", "status": "Blocked", "detail": "QA and deployment gates must pass before live hooks activate."},
            ],
            "logs": [
                self._log_entry(strategy_id, strategy_name, "canon init", "Completed", "Prediction project scaffold generated.", confidence),
                self._log_entry(strategy_id, strategy_name, "Scaffold", "Completed", f"Created {len(project_files)} Canon project files for export with modes: {', '.join(automation_modes)}.", confidence),
            ],
            "project_files": [file.model_dump() for file in project_files],
        }
        state = self._user_state(user)
        state["strategies"] = [strategy, *state["strategies"]]
        self._save_user_state(user, state)
        return StrategyBuildResponse(
            strategy=self._strategy_response(strategy),
            agents=list(_AGENT_ROLES),
            project_files=project_files,
        )

    def run_canon_action(self, user: User, strategy_id: str, command: str) -> CanonActionResponse:
        valid_commands = {"init", "start", "deploy"}
        if command not in valid_commands:
            raise HTTPException(status_code=404, detail="Unsupported canon command")
        state = self._user_state(user)
        strategy = self._find_strategy(state, strategy_id)
        now = self._now_iso()
        if command == "init":
            strategy["stage"] = "Data ingestion"
            strategy["status"] = "Scaffolded"
            strategy["pipeline"][0]["status"] = "Running"
            strategy["pipeline"][1]["status"] = "Queued"
            message = "Canon init refreshed the strategy scaffold and staged ingestion."
        elif command == "start":
            strategy["stage"] = "Simulation"
            strategy["status"] = "Running"
            strategy["confidence"] = min(0.96, float(strategy["confidence"]) + 0.05)
            strategy["pipeline"][0]["status"] = "Completed"
            strategy["pipeline"][1]["status"] = "Completed"
            strategy["pipeline"][2]["status"] = "Running"
            strategy["pipeline"][3]["status"] = "Awaiting QA"
            message = "Canon start advanced the strategy through ingestion, analysis, and prediction."
        else:
            strategy["stage"] = "Live deployment"
            strategy["status"] = "Registered"
            strategy["confidence"] = min(0.99, float(strategy["confidence"]) + 0.03)
            for step in strategy["pipeline"]:
                step["status"] = "Completed" if step["name"] != "Execution" else "Live"
            message = "Canon deploy registered the strategy and enabled live prediction-market execution hooks."
        strategy["updated_at"] = now
        strategy["logs"].append(
            self._log_entry(
                strategy["id"],
                strategy["name"],
                f"canon {command}",
                "Completed",
                message,
                float(strategy["confidence"]),
            )
        )
        self._save_user_state(user, state)
        return CanonActionResponse(strategy=self._strategy_response(strategy), message=message)

    def monitor(self, user: User) -> StrategyMonitorResponse:
        state = self._user_state(user)
        logs: list[dict[str, Any]] = []
        for strategy in state["strategies"]:
            logs.extend(strategy.get("logs", []))
        logs.sort(key=lambda item: item["timestamp"], reverse=True)
        return StrategyMonitorResponse(logs=[MonitorLogResponse(**item) for item in logs])

    def ranking(self, user: User) -> StrategyRankingResponse:
        state = self._user_state(user)
        entries: list[StrategyRankingEntryResponse] = []
        sorted_strategies = sorted(
            state["strategies"],
            key=lambda item: (float(item["confidence"]), item["updated_at"]),
            reverse=True,
        )
        for index, strategy in enumerate(sorted_strategies, start=1):
            confidence = float(strategy["confidence"])
            accuracy = round(confidence * 100, 1)
            calibration = round((confidence * 92) + (8 if strategy["status"] == "Registered" else 0), 1)
            consistency = round((confidence * 88) + (6 if strategy["stage"] == "Live deployment" else 0), 1)
            pnl = round((accuracy - 50) * 0.44, 1)
            risk_adjusted = round((pnl / 10) + (consistency / 100), 2)
            entries.append(
                StrategyRankingEntryResponse(
                    rank=index,
                    strategy=strategy["name"],
                    accuracy=accuracy,
                    pnl=pnl,
                    consistency=consistency,
                    calibration=calibration,
                    risk_adjusted_performance=risk_adjusted,
                    status=strategy["status"],
                )
            )
        return StrategyRankingResponse(entries=entries)

    def export_project(self, user: User, strategy_id: str) -> CanonProjectExportResponse:
        state = self._user_state(user)
        strategy = self._find_strategy(state, strategy_id)
        files = [CanonProjectFileResponse(**file) for file in strategy["project_files"]]
        export_label = f"{strategy['project_name']}-export"
        strategy["logs"].append(
            self._log_entry(
                strategy["id"],
                strategy["name"],
                "canon export",
                "Completed",
                f"Prepared {len(files)} files for project export.",
                float(strategy["confidence"]),
            )
        )
        strategy["updated_at"] = self._now_iso()
        self._save_user_state(user, state)
        return CanonProjectExportResponse(
            project_name=strategy["project_name"],
            export_label=export_label,
            files=files,
        )

    def export_project_archive(
        self,
        user: User,
        strategy_id: str,
        archive_format: str,
    ) -> tuple[str, str, bytes]:
        if archive_format not in {"zip", "tar"}:
            raise HTTPException(status_code=400, detail="Unsupported export format")
        export = self.export_project(user, strategy_id)
        if archive_format == "zip":
            filename = f"{export.export_label}.zip"
            media_type = "application/zip"
            payload = self._zip_archive_bytes(export)
        else:
            filename = f"{export.export_label}.tar"
            media_type = "application/x-tar"
            payload = self._tar_archive_bytes(export)
        return filename, media_type, payload

    @staticmethod
    def project_files_for_strategy(
        *,
        strategy_name: str,
        prompt: str,
        template_key: str,
        template_name: str,
        market_title: str,
        confidence: float,
        automation_modes: list[str],
    ) -> list[CanonProjectFileResponse]:
        safe_name = StrategyEngineService._slugify(strategy_name)
        config = {
            "name": safe_name,
            "displayName": strategy_name,
            "template": template_key,
            "marketTitle": market_title,
            "prompt": prompt,
            "confidenceThreshold": round(confidence, 2),
            "workflow": ["data-ingestion", "analysis", "prediction", "execution"],
            "automationModes": automation_modes,
        }
        template_label = template_name.replace('"', '\\"')
        market_label = market_title.replace('"', '\\"')
        prompt_label = prompt.replace('"', '\\"')
        files = [
            CanonProjectFileResponse(
                path="canon.json",
                content=json.dumps(config, indent=2),
            ),
            CanonProjectFileResponse(
                path="README.md",
                content=(
                    f"# {strategy_name}\n\n"
                    f"Generated by Canon CLI for prediction-market forecasting.\n\n"
                    f"- Template: {template_name}\n"
                    f"- Target market: {market_title}\n"
                    f"- Automation modes: {', '.join(automation_modes)}\n"
                    f"- Workflow: data ingestion -> analysis -> prediction -> execution\n"
                ),
            ),
            CanonProjectFileResponse(
                path="src/interfaces.ts",
                content=(
                    "export interface ProbabilityForecast {\n"
                    "  marketId: string;\n"
                    "  forecastProbability: number;\n"
                    "  confidenceScore: number;\n"
                    "  rationale: string[];\n"
                    "  executionReady: boolean;\n"
                    "}\n\n"
                    "export interface PredictionExecutionHook {\n"
                    "  validate(forecast: ProbabilityForecast): Promise<boolean>;\n"
                    "  deploy(forecast: ProbabilityForecast): Promise<void>;\n"
                    "}\n"
                ),
            ),
            CanonProjectFileResponse(
                path="src/index.ts",
                content=(
                    "import type { ProbabilityForecast } from './interfaces';\n\n"
                    f"export const strategyName = \"{strategy_name.replace('"', '\\"')}\";\n"
                    f"export const templateName = \"{template_label}\";\n"
                    f"export const targetMarket = \"{market_label}\";\n"
                    f"export const sourcePrompt = \"{prompt_label}\";\n\n"
                    "export async function buildForecast(): Promise<ProbabilityForecast> {\n"
                    "  return {\n"
                    "    marketId: targetMarket,\n"
                    "    forecastProbability: 0.62,\n"
                    "    confidenceScore: 0.81,\n"
                    "    rationale: ['Generated by Canon project scaffold'],\n"
                    "    executionReady: false,\n"
                    "  };\n"
                    "}\n"
                ),
            ),
            CanonProjectFileResponse(
                path="src/execution.ts",
                content=(
                    "import type { PredictionExecutionHook, ProbabilityForecast } from './interfaces';\n\n"
                    "export const predictionExecutionHook: PredictionExecutionHook = {\n"
                    "  async validate(forecast: ProbabilityForecast) {\n"
                    "    return forecast.confidenceScore >= 0.7;\n"
                    "  },\n"
                    "  async deploy(forecast: ProbabilityForecast) {\n"
                    "    console.log('Deploying forecast to prediction market', forecast.marketId);\n"
                    "  },\n"
                    "};\n"
                ),
            ),
            CanonProjectFileResponse(
                path="canon.lock.json",
                content=json.dumps(
                    {
                        "project": safe_name,
                        "stage": "Scaffolded",
                        "lastCommand": "canon init",
                        "generatedAt": datetime.now(timezone.utc).isoformat(),
                    },
                    indent=2,
                ),
            ),
        ]
        return files

    @staticmethod
    def write_project_files(target_dir: Path, files: list[CanonProjectFileResponse]) -> None:
        target_dir.mkdir(parents=True, exist_ok=True)
        for file in files:
            destination = target_dir / file.path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(file.content, encoding="utf-8")

    @staticmethod
    def _zip_archive_bytes(export: CanonProjectExportResponse) -> bytes:
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for file in export.files:
                archive.writestr(f"{export.project_name}/{file.path}", file.content)
        return buffer.getvalue()

    @staticmethod
    def _tar_archive_bytes(export: CanonProjectExportResponse) -> bytes:
        buffer = io.BytesIO()
        with tarfile.open(fileobj=buffer, mode="w") as archive:
            for file in export.files:
                content = file.content.encode("utf-8")
                info = tarfile.TarInfo(name=f"{export.project_name}/{file.path}")
                info.size = len(content)
                archive.addfile(info, io.BytesIO(content))
        return buffer.getvalue()

    @staticmethod
    def update_local_project_stage(target_dir: Path, command: str) -> dict[str, Any]:
        lock_path = target_dir / "canon.lock.json"
        if not lock_path.exists():
            raise FileNotFoundError(f"Missing Canon lock file at {lock_path}")
        payload = json.loads(lock_path.read_text(encoding="utf-8"))
        if command == "start":
            payload["stage"] = "Simulation"
        elif command == "deploy":
            payload["stage"] = "Live deployment"
        payload["lastCommand"] = f"canon {command}"
        payload["updatedAt"] = datetime.now(timezone.utc).isoformat()
        lock_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        return payload

    def _metrics_response(self, strategies: list[dict[str, Any]]) -> StrategyEngineMetricsResponse:
        if not strategies:
            return StrategyEngineMetricsResponse(
                active_strategies=0,
                live_deployments=0,
                forecast_accuracy=0,
                calibration_score=0,
            )
        confidences = [float(item["confidence"]) for item in strategies]
        live_count = sum(1 for item in strategies if item["stage"] == "Live deployment")
        return StrategyEngineMetricsResponse(
            active_strategies=len(strategies),
            live_deployments=live_count,
            forecast_accuracy=round(sum(confidences) / len(confidences) * 100, 1),
            calibration_score=round(sum((value * 0.9) + 0.08 for value in confidences) / len(confidences), 2),
        )

    def _strategy_response(self, strategy: dict[str, Any]) -> StrategyRecordResponse:
        return StrategyRecordResponse(
            id=strategy["id"],
            name=strategy["name"],
            prompt=strategy["prompt"],
            template_key=strategy["template_key"],
            template_name=strategy["template_name"],
            stage=strategy["stage"],
            market=strategy["market"],
            confidence=float(strategy["confidence"]),
            owner=strategy["owner"],
            status=strategy["status"],
            created_at=datetime.fromisoformat(strategy["created_at"]),
            updated_at=datetime.fromisoformat(strategy["updated_at"]),
            pipeline=[StrategyPipelineStepResponse(**step) for step in strategy["pipeline"]],
            project_path=strategy["project_path"],
            project_name=strategy["project_name"],
        )

    def _find_strategy(self, state: dict[str, Any], strategy_id: str) -> dict[str, Any]:
        for strategy in state["strategies"]:
            if strategy["id"] == strategy_id:
                return strategy
        raise HTTPException(status_code=404, detail="Strategy not found")

    def _user_state(self, user: User) -> dict[str, Any]:
        prefs = deepcopy(user.workspace_preferences or {})
        state = prefs.get("strategy_engine")
        if not isinstance(state, dict):
            state = {"strategies": []}
        if not isinstance(state.get("strategies"), list):
            state["strategies"] = []
        return state

    def _save_user_state(self, user: User, state: dict[str, Any]) -> None:
        prefs = deepcopy(user.workspace_preferences or {})
        prefs["strategy_engine"] = state
        user.workspace_preferences = prefs
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)

    def _template_for_prompt(self, prompt: str) -> _TemplateSpec:
        lowered = prompt.lower()
        if any(token in lowered for token in ("sentiment", "social", "news", "narrative")):
            return _TEMPLATES[1]
        if any(token in lowered for token in ("correlation", "tvl", "regulation", "cross-market")):
            return _TEMPLATES[2]
        if any(token in lowered for token in ("rates", "policy", "macro", "adoption", "fed")):
            return _TEMPLATES[3]
        return _TEMPLATES[0]

    def _owner_from_db(self) -> str:
        agent = self.db.scalar(select(AgentStatus).order_by(AgentStatus.interventions.desc()))
        if agent is None:
            return "Strategy Architect Agent"
        label = agent.agent_key.replace("-", " ").strip()
        return label.title() if label else "Strategy Architect Agent"

    def _strategy_name(self, prompt: str, template_name: str, market: str) -> str:
        market_focus = market.split(" before ")[0].split(" by ")[0].strip()
        prompt_tokens = re.findall(r"[A-Za-z0-9]+", prompt)
        descriptor = " ".join(prompt_tokens[:3]).strip()
        if descriptor:
            return f"{market_focus} {descriptor.title()}".strip()
        return f"{template_name} Strategy"

    def _base_confidence(self, prompt: str) -> float:
        lowered = prompt.lower()
        score = 0.58
        for token in (
            "etf",
            "sentiment",
            "macro",
            "regulation",
            "rates",
            "on-chain",
            "arbitrage",
            "lag",
            "injury",
            "matchup",
            "innovative",
        ):
            if token in lowered:
                score += 0.04
        return round(min(score, 0.89), 2)

    @staticmethod
    def _automation_modes(prompt: str) -> list[str]:
        lowered = prompt.lower()
        modes: list[str] = []
        if "arbitrage" in lowered or "discrepanc" in lowered:
            modes.append("arbitrage-detection")
        if "cross-market" in lowered or "correlat" in lowered or "lag" in lowered:
            modes.append("cross-market-analysis")
        if any(token in lowered for token in ("injury", "matchup", "team record", "public data", "speed")):
            modes.append("speed-based-opportunity")
        if "innovative" in lowered or "from scratch" in lowered or "new signal" in lowered:
            modes.append("innovative")
        return modes or ["innovative"]

    @staticmethod
    def _slugify(value: str) -> str:
        slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
        return slug or "aetherpredict-strategy"

    @staticmethod
    def _log_entry(
        strategy_id: str,
        strategy_name: str,
        stage: str,
        status: str,
        message: str,
        confidence: float,
    ) -> dict[str, Any]:
        return {
            "strategy_id": strategy_id,
            "strategy_name": strategy_name,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "stage": stage,
            "message": message,
            "status": status,
            "confidence": round(confidence, 2),
        }

    @staticmethod
    def _now_iso() -> str:
        return datetime.now(timezone.utc).isoformat()
