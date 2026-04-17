import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';
import 'strategy_engine_models.dart';
import 'strategy_engine_widgets.dart';

class PerformanceRankingScreen extends ConsumerWidget {
  const PerformanceRankingScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingValue = ref.watch(strategyRankingProvider);
    final content = StrategyShell(
      title: 'Performance Ranking',
      subtitle:
          'Forecast quality leaderboard backed by the backend ranking endpoint.',
      currentPath: '/strategy-engine/performance-ranking',
      child: rankingValue.when(
          data: (entries) => ListView(
            children: [
              Wrap(
                spacing: AetherSpacing.md,
                runSpacing: AetherSpacing.md,
                children: [
                  StrategyMetricCard(
                    label: 'Registered Strategies',
                    value: '${entries.length}',
                    detail: 'Strategies included in live backend ranking output',
                  ),
                  StrategyMetricCard(
                    label: 'Median Accuracy',
                    value: _median(entries.map((item) => item.accuracy).toList()),
                    detail: 'Probability hit-rate across ranked strategies',
                    color: AetherColors.success,
                  ),
                  StrategyMetricCard(
                    label: 'Median Calibration',
                    value:
                        _median(entries.map((item) => item.calibration).toList()),
                    detail: 'Confidence-to-outcome alignment benchmark',
                    color: AetherColors.warning,
                  ),
                  StrategyMetricCard(
                    label: 'Risk-Adjusted Perf.',
                    value: entries.isEmpty
                        ? '0.00'
                        : entries.first.riskAdjustedPerformance
                            .toStringAsFixed(2),
                    detail: 'Top ranked strategy normalized for volatility',
                    color: AetherColors.accentSoft,
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.lg),
              const EnterprisePanel(
                title: 'Registration Rules',
                subtitle:
                    'The performance layer tracks forecasting quality with validation-first enrollment.',
                child: StrategyCodeBlock(
                  lines: [
                    'register_strategy(strategy) {',
                    '  require(strategy.qaPassed);',
                    '  require(strategy.executionHooks.target == "prediction_market");',
                    '  enableAccuracyTracking();',
                    '  enableCalibrationTracking();',
                    '  enableRiskAdjustedPerformance();',
                    '}',
                  ],
                ),
              ),
              const SizedBox(height: AetherSpacing.lg),
              EnterpriseDataTable<StrategyRankingEntryModel>(
                title: 'Prediction Strategy Ranking System',
                subtitle:
                    'Leaderboard for forecasting accuracy, PnL, calibration, consistency, and risk-adjusted performance.',
                rows: entries,
                rowId: (row) => row.strategy,
                searchHint: 'Search strategy name',
                filters: [
                  EnterpriseTableFilter(
                    label: 'Registered',
                    predicate: (row) => row.status == 'Registered',
                  ),
                  EnterpriseTableFilter(
                    label: 'Draft',
                    predicate: (row) => row.status == 'Draft',
                  ),
                ],
                columns: [
                  EnterpriseTableColumn(
                    label: 'Rank',
                    width: 80,
                    numeric: true,
                    cell: (row) => '#${row.rank}',
                    sortValue: (row) => row.rank,
                  ),
                  EnterpriseTableColumn(
                    label: 'Strategy',
                    width: 220,
                    cell: (row) => row.strategy,
                    sortValue: (row) => row.strategy,
                  ),
                  EnterpriseTableColumn(
                    label: 'Accuracy',
                    width: 100,
                    numeric: true,
                    cell: (row) => '${row.accuracy.toStringAsFixed(1)}%',
                    sortValue: (row) => row.accuracy,
                  ),
                  EnterpriseTableColumn(
                    label: 'PnL',
                    width: 90,
                    numeric: true,
                    cell: (row) => '${row.pnl.toStringAsFixed(1)}%',
                    sortValue: (row) => row.pnl,
                  ),
                  EnterpriseTableColumn(
                    label: 'Consistency',
                    width: 110,
                    numeric: true,
                    cell: (row) => row.consistency.toStringAsFixed(1),
                    sortValue: (row) => row.consistency,
                  ),
                  EnterpriseTableColumn(
                    label: 'Calibration',
                    width: 110,
                    numeric: true,
                    cell: (row) => row.calibration.toStringAsFixed(1),
                    sortValue: (row) => row.calibration,
                  ),
                  EnterpriseTableColumn(
                    label: 'Risk Adj.',
                    width: 100,
                    numeric: true,
                    cell: (row) =>
                        row.riskAdjustedPerformance.toStringAsFixed(2),
                    sortValue: (row) => row.riskAdjustedPerformance,
                  ),
                  EnterpriseTableColumn(
                    label: 'Status',
                    width: 120,
                    cell: (row) => row.status,
                    sortValue: (row) => row.status,
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EnterprisePanel(
            title: 'Unable to load ranking',
            child: Text(
              error.toString(),
              style: const TextStyle(color: AetherColors.critical),
            ),
          ),
        ),
      );
    if (embedded) {
      return Scaffold(
        backgroundColor: AetherColors.bg,
        body: SafeArea(child: content),
      );
    }
    return AppScaffold(
      title: 'Strategy Engine',
      subtitle:
          'Prediction Strategy Ranking System for validated performance, calibration, and risk-adjusted forecasting outcomes.',
      child: content,
    );
  }

  String _median(List<double> values) {
    if (values.isEmpty) return '0.0';
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2].toStringAsFixed(1);
  }
}
