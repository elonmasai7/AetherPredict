class CanonCommandSpec {
  const CanonCommandSpec({
    required this.command,
    required this.summary,
    required this.details,
  });

  final String command;
  final String summary;
  final List<String> details;
}

class StrategyTemplateDefinition {
  const StrategyTemplateDefinition({
    required this.name,
    required this.description,
    required this.useCase,
    required this.interfaces,
    required this.ingestionSources,
    required this.confidenceMethod,
    required this.executionHook,
  });

  final String name;
  final String description;
  final String useCase;
  final List<String> interfaces;
  final List<String> ingestionSources;
  final String confidenceMethod;
  final String executionHook;
}

class StrategyAgentRole {
  const StrategyAgentRole({
    required this.name,
    required this.job,
    required this.outputs,
  });

  final String name;
  final String job;
  final List<String> outputs;
}

class StrategyRecord {
  const StrategyRecord({
    required this.name,
    required this.template,
    required this.stage,
    required this.market,
    required this.confidence,
    required this.owner,
    required this.status,
  });

  final String name;
  final String template;
  final String stage;
  final String market;
  final double confidence;
  final String owner;
  final String status;
}

class MonitorLogEntry {
  const MonitorLogEntry({
    required this.timestamp,
    required this.stage,
    required this.message,
    required this.status,
    required this.confidence,
  });

  final String timestamp;
  final String stage;
  final String message;
  final String status;
  final double confidence;
}

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.strategy,
    required this.accuracy,
    required this.pnl,
    required this.consistency,
    required this.calibration,
    required this.riskAdjustedPerformance,
    required this.status,
  });

  final int rank;
  final String strategy;
  final double accuracy;
  final double pnl;
  final double consistency;
  final double calibration;
  final double riskAdjustedPerformance;
  final String status;
}

const canonCommandSpecs = [
  CanonCommandSpec(
    command: 'canon init',
    summary: 'Scaffold a prediction strategy project from a forecasting template.',
    details: [
      'Select event forecasting, sentiment model, or macro predictor starter.',
      'Generate typed TypeScript interfaces for markets, signals, probabilities, and execution hooks.',
      'Prepare ingestion adapters for market, news, social, and on-chain data sources.',
    ],
  ),
  CanonCommandSpec(
    command: 'canon start',
    summary: 'Detect project stage and guide the user through the full workflow.',
    details: [
      'Move through data ingestion, analysis, prediction, and execution automatically.',
      'Surface agent suggestions for signal quality, model design, and implementation tasks.',
      'Produce a validated forecasting pipeline ready for simulation.',
    ],
  ),
  CanonCommandSpec(
    command: 'canon deploy',
    summary: 'Deploy a validated strategy to live prediction markets.',
    details: [
      'Connect execution hooks to on-chain market endpoints.',
      'Require confidence and QA checks before enabling live deployment.',
      'Register the strategy for ongoing performance tracking.',
    ],
  ),
  CanonCommandSpec(
    command: 'canon monitor',
    summary: 'Track live predictions, model drift, and performance outcomes.',
    details: [
      'Stream ingestion status, signal changes, and probability updates.',
      'Compare predicted confidence to realized outcomes.',
      'Escalate when calibration or consistency moves outside thresholds.',
    ],
  ),
];

const strategyTemplates = [
  StrategyTemplateDefinition(
    name: 'Event Probability Model',
    description:
        'Predict market outcomes from historical patterns, live catalysts, and evolving event signals.',
    useCase: 'Election, ETF approval, protocol launch, and governance outcome forecasting.',
    interfaces: [
      'MarketEventInput',
      'FeatureSnapshot',
      'ProbabilityForecast',
      'PredictionExecutionRequest',
    ],
    ingestionSources: [
      'Historical market closes',
      'Live event feeds',
      'Protocol telemetry',
    ],
    confidenceMethod: 'Bayesian confidence bands with scenario weighting.',
    executionHook:
        'Submit probability thresholds to prediction market execution adapters.',
  ),
  StrategyTemplateDefinition(
    name: 'Sentiment-Based Forecast Engine',
    description:
        'Transform news, social, and on-chain discussion flows into directional probability updates.',
    useCase: 'Narrative shifts, sentiment shocks, and crowd-belief forecasting.',
    interfaces: [
      'SentimentDocument',
      'SignalCluster',
      'SentimentProbabilityModel',
      'MarketOrderIntent',
    ],
    ingestionSources: [
      'News APIs',
      'Social streams',
      'On-chain wallet commentary',
    ],
    confidenceMethod: 'Signal agreement and source credibility scoring.',
    executionHook:
        'Route conviction-weighted predictions into market participation hooks.',
  ),
  StrategyTemplateDefinition(
    name: 'Cross-Market Correlation Predictor',
    description:
        'Model relationships between market variables and event probabilities across correlated domains.',
    useCase:
        'BTC price vs DeFi TVL vs regulatory actions, adoption, and liquidity outcomes.',
    interfaces: [
      'CorrelationInputSeries',
      'MarketDependencyGraph',
      'ProbabilitySurface',
      'ExecutionPolicy',
    ],
    ingestionSources: [
      'Price feeds',
      'TVL datasets',
      'Regulation timelines',
    ],
    confidenceMethod: 'Cross-factor stability testing with rolling calibration.',
    executionHook:
        'Trigger prediction entries when correlation thresholds and confidence align.',
  ),
  StrategyTemplateDefinition(
    name: 'Macro Event Forecast Template',
    description:
        'Estimate probabilities for policy, rates, adoption, and liquidity-driven market events.',
    useCase:
        'Interest rate decisions, policy shocks, institutional adoption, and macro cycle turns.',
    interfaces: [
      'MacroIndicatorFrame',
      'PolicyScenario',
      'ForecastDistribution',
      'ExecutionWindow',
    ],
    ingestionSources: [
      'Economic calendar inputs',
      'Policy statements',
      'Adoption trend datasets',
    ],
    confidenceMethod: 'Scenario trees with catalyst-weighted confidence scoring.',
    executionHook:
        'Deploy timing-aware forecasts to markets linked to macro catalysts.',
  ),
];

const strategyAgentRoles = [
  StrategyAgentRole(
    name: 'Market Analyst Agent',
    job:
        'Scans prediction markets to identify mispriced probabilities and emerging opportunity signals.',
    outputs: [
      'Probability dislocation report',
      'Signal anomaly summary',
      'Market watchlist',
    ],
  ),
  StrategyAgentRole(
    name: 'Strategy Architect Agent',
    job:
        'Converts plain-language ideas into forecasting logic, model structure, and data requirements.',
    outputs: [
      'Probability model outline',
      'Feature input plan',
      'Validation checkpoints',
    ],
  ),
  StrategyAgentRole(
    name: 'Developer Agent',
    job:
        'Implements strategy logic, typed interfaces, data adapters, and execution hooks for prediction markets.',
    outputs: [
      'TypeScript modules',
      'Ingestion connectors',
      'Execution adapter wiring',
    ],
  ),
  StrategyAgentRole(
    name: 'QA Agent',
    job:
        'Validates consistency, simulates outcomes, and blocks deployment when the forecast stack is unstable.',
    outputs: [
      'Simulation report',
      'Calibration audit',
      'Deployment readiness score',
    ],
  ),
];

const activeStrategies = [
  StrategyRecord(
    name: 'ETF Flow Breakout',
    template: 'Event Probability Model',
    stage: 'Live deployment',
    market: 'BTC > 120k before Dec 2026',
    confidence: 0.74,
    owner: 'Strategy Architect Agent',
    status: 'Validated',
  ),
  StrategyRecord(
    name: 'Narrative Heat Monitor',
    template: 'Sentiment-Based Forecast Engine',
    stage: 'Simulation',
    market: 'ETH ETF volume doubles by Q4',
    confidence: 0.68,
    owner: 'Market Analyst Agent',
    status: 'Review',
  ),
  StrategyRecord(
    name: 'Policy Correlation Lattice',
    template: 'Cross-Market Correlation Predictor',
    stage: 'Data ingestion',
    market: 'DeFi TVL > 250B after rate cut',
    confidence: 0.62,
    owner: 'Developer Agent',
    status: 'Running',
  ),
  StrategyRecord(
    name: 'Macro Pulse',
    template: 'Macro Event Forecast Template',
    stage: 'QA validation',
    market: 'Fed cuts before September meeting',
    confidence: 0.79,
    owner: 'QA Agent',
    status: 'Pending',
  ),
];

const monitorLogs = [
  MonitorLogEntry(
    timestamp: '14:03:09Z',
    stage: 'Data Fetch',
    message: 'ETF inflow, rates, and on-chain activity sources synchronized.',
    status: 'Completed',
    confidence: 0.91,
  ),
  MonitorLogEntry(
    timestamp: '14:03:16Z',
    stage: 'Sentiment Analysis',
    message: 'Positive institutional narrative detected across 18 curated feeds.',
    status: 'Running',
    confidence: 0.76,
  ),
  MonitorLogEntry(
    timestamp: '14:03:24Z',
    stage: 'Probability Model',
    message: 'Posterior probability updated from 0.58 to 0.64 after catalyst weighting.',
    status: 'Completed',
    confidence: 0.84,
  ),
  MonitorLogEntry(
    timestamp: '14:03:31Z',
    stage: 'Decision Output',
    message: 'Execution threshold exceeded. Recommend staged position entry.',
    status: 'Queued',
    confidence: 0.81,
  ),
  MonitorLogEntry(
    timestamp: '14:03:39Z',
    stage: 'Prediction Execution',
    message: 'Preparing on-chain submission for validated live market hook.',
    status: 'Awaiting QA',
    confidence: 0.78,
  ),
  MonitorLogEntry(
    timestamp: '14:03:51Z',
    stage: 'Outcome Tracking',
    message: 'Calibration monitor scheduled for post-entry drift review.',
    status: 'Scheduled',
    confidence: 0.73,
  ),
];

const rankingEntries = [
  RankingEntry(
    rank: 1,
    strategy: 'ETF Flow Breakout',
    accuracy: 84.2,
    pnl: 18.6,
    consistency: 91.0,
    calibration: 88.4,
    riskAdjustedPerformance: 1.92,
    status: 'Registered',
  ),
  RankingEntry(
    rank: 2,
    strategy: 'Macro Pulse',
    accuracy: 81.7,
    pnl: 15.1,
    consistency: 87.8,
    calibration: 86.5,
    riskAdjustedPerformance: 1.63,
    status: 'Registered',
  ),
  RankingEntry(
    rank: 3,
    strategy: 'Narrative Heat Monitor',
    accuracy: 78.9,
    pnl: 12.8,
    consistency: 82.4,
    calibration: 84.1,
    riskAdjustedPerformance: 1.44,
    status: 'Validation',
  ),
  RankingEntry(
    rank: 4,
    strategy: 'Policy Correlation Lattice',
    accuracy: 75.5,
    pnl: 10.3,
    consistency: 80.1,
    calibration: 79.8,
    riskAdjustedPerformance: 1.27,
    status: 'Validation',
  ),
];
