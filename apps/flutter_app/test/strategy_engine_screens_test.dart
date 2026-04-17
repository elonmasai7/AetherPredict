import 'dart:async';

import 'package:aetherpredict_flutter/src/core/api_client.dart';
import 'package:aetherpredict_flutter/src/core/models.dart';
import 'package:aetherpredict_flutter/src/core/providers.dart';
import 'package:aetherpredict_flutter/src/core/wallet_service.dart';
import 'package:aetherpredict_flutter/src/features/strategy_engine/automation_monitor_screen.dart';
import 'package:aetherpredict_flutter/src/features/strategy_engine/my_strategies_screen.dart';
import 'package:aetherpredict_flutter/src/features/strategy_engine/performance_ranking_screen.dart';
import 'package:aetherpredict_flutter/src/features/strategy_engine/strategy_ai_builder_screen.dart';
import 'package:aetherpredict_flutter/src/features/strategy_engine/strategy_engine_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthNotifier extends AuthSessionNotifier {
  _FakeAuthNotifier() : super() {
    state = const AuthSessionState(
      accessToken: 'token',
      refreshToken: 'refresh',
      restored: true,
    );
  }

  @override
  Future<void> restore() async {}
}

class _FakeWalletService extends WalletService {}

class _FakeWalletNotifier extends WalletSessionNotifier {
  _FakeWalletNotifier(Ref ref) : super(_FakeWalletService(), ref);

  @override
  Future<void> restore() async {
    state = const WalletSessionState(connected: false);
  }

  @override
  Future<void> connect(WalletType type) async {}

  @override
  Future<void> disconnect() async {
    state = const WalletSessionState();
  }
}

class _FakeStrategyApiClient extends ApiClient {
  _FakeStrategyApiClient();

  @override
  Future<StrategyEngineStateModel> fetchStrategyEngineState() async {
    return _sampleState();
  }

  @override
  Future<List<StrategyTemplateModel>> fetchStrategyTemplates() async {
    return const [
      StrategyTemplateModel(
        key: 'sentiment-model',
        name: 'Sentiment-Based Forecast Engine',
        description: 'Forecast from narrative data.',
        useCase: 'Arbitrage and lag capture',
        interfaces: ['ProbabilityForecast'],
        ingestionSources: ['Markets', 'News'],
        confidenceMethod: 'Signal agreement',
        executionHook: 'Prediction market adapter',
      ),
    ];
  }

  @override
  Future<List<StrategyMonitorLogModel>> fetchStrategyMonitor() async {
    return [
      StrategyMonitorLogModel(
        strategyId: 'strategy-1',
        strategyName: 'BTC Arbitrage Pulse',
        timestamp: DateTime.utc(2026, 4, 17, 12, 0, 0),
        stage: 'canon deploy',
        message: 'Live deployment enabled.',
        status: 'Completed',
        confidence: 0.84,
      ),
    ];
  }

  @override
  Future<List<StrategyRankingEntryModel>> fetchStrategyRanking() async {
    return const [
      StrategyRankingEntryModel(
        rank: 1,
        strategy: 'BTC Arbitrage Pulse',
        accuracy: 84.2,
        pnl: 12.4,
        consistency: 88.1,
        calibration: 86.5,
        riskAdjustedPerformance: 1.72,
        status: 'Registered',
      ),
    ];
  }

  @override
  Future<CanonActionResultModel> runCanonCommand(
      String strategyId, String command) async {
    return CanonActionResultModel(
      strategy: _sampleState().strategies.first,
      message: 'Ran canon $command for $strategyId',
    );
  }

  @override
  Future<CanonProjectExportModel> exportStrategyProject(String strategyId) async {
    return const CanonProjectExportModel(
      projectName: 'btc-arbitrage-pulse',
      exportLabel: 'btc-arbitrage-pulse-export',
      files: [
        CanonProjectFileModel(path: 'canon.json', content: '{}'),
        CanonProjectFileModel(path: 'README.md', content: '# Project'),
      ],
    );
  }

  @override
  Future<StrategyBuildResultModel> buildStrategyFromPrompt(String prompt) async {
    return StrategyBuildResultModel(
      strategy: StrategyRecordModel(
        id: 'strategy-2',
        name: 'Generated Opportunity Grid',
        prompt: prompt,
        templateKey: 'sentiment-model',
        templateName: 'Sentiment-Based Forecast Engine',
        stage: 'Scaffolded',
        market: 'BTC > 120k before Dec 2026',
        confidence: 0.82,
        owner: 'Strategy Architect Agent',
        status: 'Draft',
        createdAt: DateTime.utc(2026, 4, 17),
        updatedAt: DateTime.utc(2026, 4, 17),
        pipeline: const [
          StrategyPipelineStepModel(
            name: 'Data Ingestion',
            status: 'Ready',
            detail: 'Inputs mapped',
          ),
        ],
        projectPath: 'canon_projects/generated-opportunity-grid',
        projectName: 'generated-opportunity-grid',
      ),
      agents: const [
        StrategyAgentRoleModel(
          name: 'Market Analyst Agent',
          job: 'Scans markets',
          outputs: ['Probability dislocation report'],
        ),
      ],
      projectFiles: const [
        CanonProjectFileModel(path: 'canon.json', content: '{}'),
        CanonProjectFileModel(path: 'src/index.ts', content: 'export {};'),
      ],
    );
  }
}

StrategyEngineStateModel _sampleState() {
  return StrategyEngineStateModel(
    metrics: const StrategyEngineMetrics(
      activeStrategies: 1,
      liveDeployments: 1,
      forecastAccuracy: 84.2,
      calibrationScore: 0.88,
    ),
    canonCommands: const [
      CanonCommandModel(
        command: 'canon init',
        summary: 'Scaffold project',
        details: ['Generate files'],
      ),
      CanonCommandModel(
        command: 'canon deploy',
        summary: 'Deploy project',
        details: ['Enable live execution'],
      ),
    ],
    strategies: [
      StrategyRecordModel(
        id: 'strategy-1',
        name: 'BTC Arbitrage Pulse',
        prompt: 'Arbitrage and cross-market lag forecast',
        templateKey: 'sentiment-model',
        templateName: 'Sentiment-Based Forecast Engine',
        stage: 'Live deployment',
        market: 'BTC > 120k before Dec 2026',
        confidence: 0.84,
        owner: 'Strategy Architect Agent',
        status: 'Registered',
        createdAt: DateTime.utc(2026, 4, 17),
        updatedAt: DateTime.utc(2026, 4, 17),
        pipeline: const [
          StrategyPipelineStepModel(
            name: 'Data Ingestion',
            status: 'Completed',
            detail: 'Complete',
          ),
          StrategyPipelineStepModel(
            name: 'Execution',
            status: 'Live',
            detail: 'Running in prediction markets',
          ),
        ],
        projectPath: 'canon_projects/btc-arbitrage-pulse',
        projectName: 'btc-arbitrage-pulse',
      ),
    ],
  );
}

List<Override> _commonOverrides() {
  return [
    authSessionProvider.overrideWith((ref) => _FakeAuthNotifier()),
    walletSessionProvider.overrideWith((ref) => _FakeWalletNotifier(ref)),
    portfolioProvider.overrideWith((ref) async => <PortfolioPosition>[]),
    txUpdatesProvider.overrideWith((ref) => const Stream<TxUpdate>.empty()),
    strategyEngineStateProvider.overrideWith((ref) async => _sampleState()),
    strategyMonitorProvider.overrideWith((ref) async => [
          StrategyMonitorLogModel(
            strategyId: 'strategy-1',
            strategyName: 'BTC Arbitrage Pulse',
            timestamp: DateTime.utc(2026, 4, 17, 12, 0, 0),
            stage: 'canon deploy',
            message: 'Live deployment enabled.',
            status: 'Completed',
            confidence: 0.84,
          ),
        ]),
    strategyRankingProvider.overrideWith((ref) async => const [
          StrategyRankingEntryModel(
            rank: 1,
            strategy: 'BTC Arbitrage Pulse',
            accuracy: 84.2,
            pnl: 12.4,
            consistency: 88.1,
            calibration: 86.5,
            riskAdjustedPerformance: 1.72,
            status: 'Registered',
          ),
        ]),
    apiClientProvider.overrideWithValue(_FakeStrategyApiClient()),
  ];
}

Widget _buildScreenApp(Widget screen) {
  return ProviderScope(
    overrides: _commonOverrides(),
    child: MaterialApp(home: screen),
  );
}

void main() {
  testWidgets('My Strategies screen renders live workflow controls',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildScreenApp(const MyStrategiesScreen(embedded: true)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.text('Command Center'),
      400,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Command Center'), findsOneWidget);
    expect(find.text('BTC Arbitrage Pulse'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Export Project'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Export Project'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Export ready'), findsOneWidget);
  });

  testWidgets('AI Builder screen generates a strategy from prompt',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildScreenApp(const StrategyAiBuilderScreen(embedded: true)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Plain-Language Strategy Prompt'), findsOneWidget);

    await tester.tap(find.text('Generate Pipeline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Generated Opportunity Grid'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Generated Opportunity Grid'), findsOneWidget);
    expect(find.text('Generated Project Files'), findsOneWidget);
  });

  testWidgets('Monitor and ranking screens render authenticated live data',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildScreenApp(const AutomationMonitorScreen(embedded: true)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.text('Execution Timeline'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Execution Timeline'), findsOneWidget);
    expect(find.text('BTC Arbitrage Pulse'), findsWidgets);

    await tester.pumpWidget(
      _buildScreenApp(const PerformanceRankingScreen(embedded: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prediction Strategy Ranking System'), findsOneWidget);
    expect(find.text('BTC Arbitrage Pulse'), findsWidgets);
  });
}
