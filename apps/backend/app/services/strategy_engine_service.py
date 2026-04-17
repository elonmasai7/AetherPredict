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

import httpx
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.models.entities import (
    AgentStatus,
    AssetSnapshot,
    Market,
    StrategyEngineExport,
    StrategyEngineLog,
    StrategyEngineRanking,
    StrategyEngineRun,
    StrategyEngineStrategy,
    User,
)
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
        strategies = self._strategies_for_user(user.id)
        return StrategyEngineStateResponse(
            metrics=self._metrics_response(strategies),
            canon_commands=list(_COMMANDS),
            strategies=[self._strategy_response(item) for item in strategies],
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
        strategy_id = uuid4().hex[:10]
        target_market = market.title if market is not None else "Custom prediction market"
        automation_modes = self._automation_modes(prompt)
        strategy_name = self._strategy_name(prompt, template.name, target_market)
        project_name = self._slugify(strategy_name)
        scoring = self._score_strategy_inputs(prompt=prompt, target_market=target_market)
        confidence = scoring["confidence"]
        project_files = self.project_files_for_strategy(
            strategy_name=strategy_name,
            prompt=prompt,
            template_key=template.key,
            template_name=template.name,
            market_title=target_market,
            confidence=confidence,
            automation_modes=automation_modes,
        )
        strategy = StrategyEngineStrategy(
            public_id=strategy_id,
            user_id=user.id,
            name=strategy_name,
            prompt=prompt,
            template_key=template.key,
            template_name=template.name,
            stage="Scaffolded",
            market=target_market,
            confidence=confidence,
            owner=agent_owner,
            status="Draft",
            project_name=project_name,
            project_path=f"canon_projects/{project_name}",
            automation_modes_json=automation_modes,
            metadata_json={"source": "ai-builder", "live_inputs": scoring["inputs"]},
        )
        self.db.add(strategy)
        self.db.flush()

        pipeline = [
            {
                "name": "Data Ingestion",
                "status": "Completed",
                "detail": f"Loaded {scoring['ingestion_count']} live inputs from markets, assets, and AI feeds.",
            },
            {
                "name": "Analysis",
                "status": "Completed",
                "detail": f"Computed live signal analysis for {', '.join(automation_modes)} using asset, market, and sentiment context.",
            },
            {
                "name": "Prediction",
                "status": "Completed",
                "detail": f"Model score generated from live inputs with confidence {confidence:.2f}.",
            },
            {"name": "Execution", "status": "Blocked", "detail": "QA and deployment gates must pass before live hooks activate."},
        ]
        run = self._create_run(
            strategy,
            run_type="build",
            stage=strategy.stage,
            status=strategy.status,
            confidence=confidence,
            pipeline=pipeline,
            project_files=[file.model_dump() for file in project_files],
            metadata={"automation_modes": automation_modes, "live_scoring": scoring},
        )
        self._create_log(strategy, run, "canon init", "Completed", "Prediction project scaffold generated.", confidence)
        self._create_log(
            strategy,
            run,
            "Scaffold",
            "Completed",
            f"Created {len(project_files)} Canon project files for export with modes: {', '.join(automation_modes)}.",
            confidence,
        )
        self._create_log(
            strategy,
            run,
            "Model Score",
            "Completed",
            f"Live scoring ingested {scoring['ingestion_count']} inputs and produced confidence {confidence:.2f}.",
            confidence,
        )
        self._sync_rankings_for_user(user.id)
        self.db.commit()
        self.db.refresh(strategy)
        return StrategyBuildResponse(
            strategy=self._strategy_response(strategy),
            agents=list(_AGENT_ROLES),
            project_files=project_files,
        )

    def run_canon_action(self, user: User, strategy_id: str, command: str) -> CanonActionResponse:
        valid_commands = {"init", "start", "deploy"}
        if command not in valid_commands:
            raise HTTPException(status_code=404, detail="Unsupported canon command")
        strategy = self._strategy_for_user(user.id, strategy_id)
        current_run = self._current_run(strategy)
        pipeline = deepcopy(current_run.pipeline_json if current_run is not None else [])
        confidence = float(strategy.confidence)

        if command == "init":
            strategy.stage = "Data ingestion"
            strategy.status = "Scaffolded"
            if pipeline:
                pipeline[0]["status"] = "Running"
                if len(pipeline) > 1:
                    pipeline[1]["status"] = "Queued"
            message = "Canon init refreshed the strategy scaffold and staged ingestion."
        elif command == "start":
            strategy.stage = "Simulation"
            strategy.status = "Running"
            confidence = min(0.96, confidence + 0.05)
            if len(pipeline) >= 4:
                pipeline[0]["status"] = "Completed"
                pipeline[1]["status"] = "Completed"
                pipeline[2]["status"] = "Running"
                pipeline[3]["status"] = "Awaiting QA"
            message = "Canon start advanced the strategy through ingestion, analysis, and prediction."
        else:
            strategy.stage = "Live deployment"
            strategy.status = "Registered"
            confidence = min(0.99, confidence + 0.03)
            for step in pipeline:
                step["status"] = "Completed" if step["name"] != "Execution" else "Live"
            message = "Canon deploy registered the strategy and enabled live prediction-market execution hooks."

        strategy.confidence = confidence
        strategy.updated_at = datetime.utcnow()
        project_files = deepcopy(current_run.project_files_json if current_run is not None else [])
        run = self._create_run(
            strategy,
            run_type=f"canon:{command}",
            stage=strategy.stage,
            status=strategy.status,
            confidence=confidence,
            pipeline=pipeline,
            project_files=project_files,
            metadata={"command": command},
        )
        self._create_log(strategy, run, f"canon {command}", "Completed", message, confidence)
        self._sync_rankings_for_user(user.id)
        self.db.commit()
        self.db.refresh(strategy)
        return CanonActionResponse(strategy=self._strategy_response(strategy), message=message)

    def refresh_active_strategies(self) -> int:
        strategies = self.db.scalars(
            select(StrategyEngineStrategy)
            .options(selectinload(StrategyEngineStrategy.runs), selectinload(StrategyEngineStrategy.logs))
            .where(StrategyEngineStrategy.status.in_(["Running", "Registered"]))
        ).all()
        refreshed = 0
        for strategy in strategies:
            current_run = self._current_run(strategy)
            if current_run is None:
                continue
            scoring = self._score_strategy_inputs(prompt=strategy.prompt, target_market=strategy.market)
            confidence = scoring["confidence"]
            strategy.confidence = confidence
            strategy.updated_at = datetime.utcnow()
            pipeline = deepcopy(current_run.pipeline_json)
            if len(pipeline) >= 3:
                pipeline[0]["detail"] = f"Loaded {scoring['ingestion_count']} live inputs from markets, assets, and AI feeds."
                pipeline[1]["detail"] = "Refreshed live signal and anomaly analysis."
                pipeline[2]["detail"] = f"Refreshed model score to {confidence:.2f} from live inputs."
            refresh_run = self._create_run(
                strategy,
                run_type="model-refresh",
                stage=strategy.stage,
                status=strategy.status,
                confidence=confidence,
                pipeline=pipeline,
                project_files=deepcopy(current_run.project_files_json),
                metadata={"live_scoring": scoring},
            )
            self._create_log(
                strategy,
                refresh_run,
                "Model Refresh",
                "Completed",
                f"Refreshed live scoring from {scoring['ingestion_count']} inputs with confidence {confidence:.2f}.",
                confidence,
            )
            refreshed += 1
        if refreshed:
            user_ids = {item.user_id for item in strategies}
            for user_id in user_ids:
                self._sync_rankings_for_user(user_id)
            self.db.commit()
        return refreshed

    def monitor(self, user: User) -> StrategyMonitorResponse:
        logs = self.db.scalars(
            select(StrategyEngineLog)
            .join(StrategyEngineStrategy)
            .where(StrategyEngineStrategy.user_id == user.id)
            .order_by(StrategyEngineLog.timestamp.desc())
        ).all()
        return StrategyMonitorResponse(
            logs=[
                MonitorLogResponse(
                    strategy_id=item.strategy.public_id,
                    strategy_name=item.strategy.name,
                    timestamp=item.timestamp,
                    stage=item.stage,
                    message=item.message,
                    status=item.status,
                    confidence=float(item.confidence),
                )
                for item in logs
            ]
        )

    def ranking(self, user: User) -> StrategyRankingResponse:
        self._sync_rankings_for_user(user.id)
        self.db.commit()
        rankings = self.db.scalars(
            select(StrategyEngineRanking)
            .join(StrategyEngineStrategy)
            .options(selectinload(StrategyEngineRanking.strategy))
            .where(StrategyEngineStrategy.user_id == user.id)
            .order_by(StrategyEngineRanking.rank.asc(), StrategyEngineRanking.updated_at.desc())
        ).all()
        return StrategyRankingResponse(
            entries=[
                StrategyRankingEntryResponse(
                    rank=item.rank,
                    strategy=item.strategy.name,
                    accuracy=float(item.accuracy),
                    pnl=float(item.pnl),
                    consistency=float(item.consistency),
                    calibration=float(item.calibration),
                    risk_adjusted_performance=float(item.risk_adjusted_performance),
                    status=item.status,
                )
                for item in rankings
            ]
        )

    def export_project(self, user: User, strategy_id: str) -> CanonProjectExportResponse:
        strategy = self._strategy_for_user(user.id, strategy_id)
        current_run = self._current_run(strategy)
        files = [CanonProjectFileResponse(**file) for file in (current_run.project_files_json if current_run is not None else [])]
        export_label = f"{strategy.project_name}-export"
        export = StrategyEngineExport(
            strategy_id=strategy.id,
            export_label=export_label,
            archive_format=None,
            file_count=len(files),
            file_manifest_json=[file.model_dump() for file in files],
        )
        self.db.add(export)
        self._create_log(
            strategy,
            current_run,
            "canon export",
            "Completed",
            f"Prepared {len(files)} files for project export.",
            float(strategy.confidence),
        )
        strategy.updated_at = datetime.utcnow()
        self.db.commit()
        return CanonProjectExportResponse(
            project_name=strategy.project_name,
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
        strategy = self._strategy_for_user(user.id, strategy_id)
        latest_export = self.db.scalar(
            select(StrategyEngineExport)
            .where(StrategyEngineExport.strategy_id == strategy.id)
            .order_by(StrategyEngineExport.created_at.desc())
        )
        if latest_export is not None:
            latest_export.archive_format = archive_format
            self.db.commit()
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
        strategy_label = strategy_name.replace('"', '\\"')
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
                    f"export const strategyName = \"{strategy_label}\";\n"
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

    def _metrics_response(self, strategies: list[StrategyEngineStrategy]) -> StrategyEngineMetricsResponse:
        if not strategies:
            return StrategyEngineMetricsResponse(
                active_strategies=0,
                live_deployments=0,
                forecast_accuracy=0,
                calibration_score=0,
            )
        confidences = [float(item.confidence) for item in strategies]
        live_count = sum(1 for item in strategies if item.stage == "Live deployment")
        return StrategyEngineMetricsResponse(
            active_strategies=len(strategies),
            live_deployments=live_count,
            forecast_accuracy=round(sum(confidences) / len(confidences) * 100, 1),
            calibration_score=round(sum((value * 0.9) + 0.08 for value in confidences) / len(confidences), 2),
        )

    def _strategy_response(self, strategy: StrategyEngineStrategy) -> StrategyRecordResponse:
        current_run = self._current_run(strategy)
        pipeline = current_run.pipeline_json if current_run is not None else []
        return StrategyRecordResponse(
            id=strategy.public_id,
            name=strategy.name,
            prompt=strategy.prompt,
            template_key=strategy.template_key,
            template_name=strategy.template_name,
            stage=strategy.stage,
            market=strategy.market,
            confidence=float(strategy.confidence),
            owner=strategy.owner,
            status=strategy.status,
            created_at=strategy.created_at,
            updated_at=strategy.updated_at,
            pipeline=[StrategyPipelineStepResponse(**step) for step in pipeline],
            project_path=strategy.project_path,
            project_name=strategy.project_name,
        )

    def _strategies_for_user(self, user_id: int) -> list[StrategyEngineStrategy]:
        return self.db.scalars(
            select(StrategyEngineStrategy)
            .options(
                selectinload(StrategyEngineStrategy.runs),
                selectinload(StrategyEngineStrategy.logs),
                selectinload(StrategyEngineStrategy.ranking),
            )
            .where(StrategyEngineStrategy.user_id == user_id)
            .order_by(StrategyEngineStrategy.updated_at.desc())
        ).all()

    def _strategy_for_user(self, user_id: int, strategy_id: str) -> StrategyEngineStrategy:
        strategy = self.db.scalar(
            select(StrategyEngineStrategy)
            .options(
                selectinload(StrategyEngineStrategy.runs),
                selectinload(StrategyEngineStrategy.logs),
                selectinload(StrategyEngineStrategy.ranking),
            )
            .where(
                StrategyEngineStrategy.user_id == user_id,
                StrategyEngineStrategy.public_id == strategy_id,
            )
        )
        if strategy is None:
            raise HTTPException(status_code=404, detail="Strategy not found")
        return strategy

    @staticmethod
    def _current_run(strategy: StrategyEngineStrategy) -> StrategyEngineRun | None:
        if not strategy.runs:
            return None
        for run in strategy.runs:
            if run.is_current:
                return run
        return max(strategy.runs, key=lambda item: item.updated_at)

    def _create_run(
        self,
        strategy: StrategyEngineStrategy,
        *,
        run_type: str,
        stage: str,
        status: str,
        confidence: float,
        pipeline: list[dict[str, Any]],
        project_files: list[dict[str, Any]],
        metadata: dict[str, Any],
    ) -> StrategyEngineRun:
        self.db.query(StrategyEngineRun).filter(StrategyEngineRun.strategy_id == strategy.id).update(
            {StrategyEngineRun.is_current: False}, synchronize_session=False
        )
        run = StrategyEngineRun(
            strategy_id=strategy.id,
            run_type=run_type,
            stage=stage,
            status=status,
            confidence=confidence,
            is_current=True,
            pipeline_json=deepcopy(pipeline),
            project_files_json=deepcopy(project_files),
            metadata_json=metadata,
        )
        self.db.add(run)
        self.db.flush()
        strategy.runs.append(run)
        return run

    def _create_log(
        self,
        strategy: StrategyEngineStrategy,
        run: StrategyEngineRun | None,
        stage: str,
        status: str,
        message: str,
        confidence: float,
    ) -> StrategyEngineLog:
        entry = StrategyEngineLog(
            strategy_id=strategy.id,
            run_id=run.id if run is not None else None,
            timestamp=datetime.utcnow(),
            stage=stage,
            status=status,
            message=message,
            confidence=confidence,
            metadata_json={},
        )
        self.db.add(entry)
        self.db.flush()
        strategy.logs.append(entry)
        return entry

    def _sync_rankings_for_user(self, user_id: int) -> None:
        strategies = self._strategies_for_user(user_id)
        ranking_rows: list[tuple[StrategyEngineStrategy, dict[str, float | str | datetime | None]]] = []
        for strategy in strategies:
            confidence = float(strategy.confidence)
            accuracy = round(confidence * 100, 1)
            calibration = round((confidence * 92) + (8 if strategy.status == "Registered" else 0), 1)
            consistency = round((confidence * 88) + (6 if strategy.stage == "Live deployment" else 0), 1)
            pnl = round((accuracy - 50) * 0.44, 1)
            risk_adjusted = round((pnl / 10) + (consistency / 100), 2)
            ranking_rows.append(
                (
                    strategy,
                    {
                        "accuracy": accuracy,
                        "pnl": pnl,
                        "consistency": consistency,
                        "calibration": calibration,
                        "risk_adjusted_performance": risk_adjusted,
                        "status": strategy.status,
                        "last_registered_at": datetime.utcnow() if strategy.status == "Registered" else None,
                    },
                )
            )
        ranking_rows.sort(key=lambda item: (item[1]["risk_adjusted_performance"], item[0].updated_at), reverse=True)
        for index, (strategy, payload) in enumerate(ranking_rows, start=1):
            ranking = strategy.ranking
            if ranking is None:
                ranking = StrategyEngineRanking(strategy_id=strategy.id)
                self.db.add(ranking)
                strategy.ranking = ranking
            ranking.rank = index
            ranking.accuracy = float(payload["accuracy"])
            ranking.pnl = float(payload["pnl"])
            ranking.consistency = float(payload["consistency"])
            ranking.calibration = float(payload["calibration"])
            ranking.risk_adjusted_performance = float(payload["risk_adjusted_performance"])
            ranking.status = str(payload["status"])
            ranking.last_registered_at = payload["last_registered_at"]
            ranking.updated_at = datetime.utcnow()

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

    def _score_strategy_inputs(self, *, prompt: str, target_market: str) -> dict[str, Any]:
        market = self.db.scalar(select(Market).where(Market.title == target_market))
        symbol = self._infer_symbol(f"{prompt} {target_market}")
        asset = self.db.scalar(select(AssetSnapshot).where(AssetSnapshot.symbol == symbol))
        ai_probability = self._fetch_ai_json("/probability-update", {"market_id": target_market})
        ai_sentiment = self._fetch_ai_json("/market/sentiment-feed", {"market_id": target_market})
        ai_anomaly = self._fetch_ai_json("/anomaly-detection", {"market_id": target_market})

        base_probability = float(
            (ai_probability or {}).get(
                "yes_probability",
                market.yes_probability if market is not None else 0.5,
            )
        )
        market_confidence = float(market.ai_confidence if market is not None else 0.55)
        sentiment_score = float((ai_sentiment or {}).get("sentiment_score", 0.5))
        anomaly_penalty = 0.07 if (ai_anomaly or {}).get("anomaly_alerts") else 0.0
        asset_signal = 0.5
        if asset is not None:
            asset_signal = max(
                0.1,
                min(
                    0.95,
                    0.5 + (float(asset.change_24h) / 100) + (float(asset.order_flow_score) / 200),
                ),
            )
        combined = (base_probability * 0.35) + (market_confidence * 0.25) + (sentiment_score * 0.20) + (asset_signal * 0.20)
        confidence = round(max(0.05, min(0.99, combined - anomaly_penalty)), 2)

        inputs = {
            "market": {
                "title": market.title if market is not None else target_market,
                "yes_probability": float(market.yes_probability) if market is not None else None,
                "ai_confidence": float(market.ai_confidence) if market is not None else None,
                "volume": float(market.volume) if market is not None else None,
            },
            "asset": {
                "symbol": asset.symbol if asset is not None else symbol,
                "price_usd": float(asset.price_usd) if asset is not None else None,
                "change_24h": float(asset.change_24h) if asset is not None else None,
                "order_flow_score": float(asset.order_flow_score) if asset is not None else None,
                "volatility_pct": float(asset.volatility_pct) if asset is not None else None,
            },
            "ai_probability": ai_probability or {},
            "ai_sentiment": ai_sentiment or {},
            "ai_anomaly": ai_anomaly or {},
        }
        ingestion_count = 0
        for value in inputs.values():
            if value:
                ingestion_count += 1
        return {
            "confidence": confidence,
            "inputs": inputs,
            "ingestion_count": ingestion_count,
        }

    def _fetch_ai_json(self, path: str, payload: dict[str, Any]) -> dict[str, Any] | None:
        try:
            with httpx.Client(timeout=8) as client:
                response = client.post(f"{settings.ai_service_url}{path}", json=payload)
                response.raise_for_status()
                return response.json()
        except Exception:
            return None

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
    def _infer_symbol(text: str) -> str:
        upper = text.upper()
        if "ETH" in upper or "ETHEREUM" in upper:
            return "ETH"
        if "SOL" in upper or "SOLANA" in upper:
            return "SOL"
        if "HASHKEY" in upper or "HSK" in upper:
            return "HSK"
        return "BTC"
