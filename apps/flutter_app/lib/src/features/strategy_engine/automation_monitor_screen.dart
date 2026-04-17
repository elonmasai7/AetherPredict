import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';
import 'strategy_engine_models.dart';
import 'strategy_engine_widgets.dart';

class AutomationMonitorScreen extends ConsumerWidget {
  const AutomationMonitorScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsValue = ref.watch(strategyMonitorProvider);
    final stateValue = ref.watch(strategyEngineStateProvider);
    final content = StrategyShell(
      title: 'Automation Monitor',
      subtitle:
          'Real-time system view for AI forecasting infrastructure with backend log streams and Canon workflow status.',
      currentPath: '/strategy-engine/automation-monitor',
      child: logsValue.when(
          data: (logs) {
            final latestState = stateValue.valueOrNull;
            final latestPipeline =
                latestState?.strategies.isNotEmpty == true
                    ? latestState!.strategies.first.pipeline
                    : <StrategyPipelineStepModel>[];
            return ListView(
              children: [
                Wrap(
                  spacing: AetherSpacing.md,
                  runSpacing: AetherSpacing.md,
                  children: [
                    StrategyMetricCard(
                      label: 'Pipelines Online',
                      value: '${latestState?.metrics.activeStrategies ?? 0}',
                      detail: 'Persisted strategy workflows feeding the monitor',
                    ),
                    StrategyMetricCard(
                      label: 'Average Confidence',
                      value:
                          '${latestState?.metrics.forecastAccuracy.toStringAsFixed(1) ?? '0.0'}%',
                      detail: 'Backend accuracy rollup across strategy records',
                      color: AetherColors.success,
                    ),
                    StrategyMetricCard(
                      label: 'Execution Status',
                      value:
                          '${latestState?.metrics.liveDeployments ?? 0} live',
                      detail:
                          'Live prediction-market deployments under tracking',
                      color: AetherColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AetherSpacing.lg),
                EnterprisePanel(
                  title: 'Pipeline Topology',
                  subtitle:
                      'Current pipeline state derived from the most recently updated strategy.',
                  child: latestPipeline.isEmpty
                      ? const Text(
                          'No active pipeline stages yet. Generate a strategy from AI Builder to start monitoring.',
                          style: TextStyle(color: AetherColors.muted),
                        )
                      : Wrap(
                          spacing: AetherSpacing.sm,
                          runSpacing: AetherSpacing.sm,
                          children: [
                            for (final step in latestPipeline)
                              _FlowNode(label: step.name, status: step.status),
                          ],
                        ),
                ),
                const SizedBox(height: AetherSpacing.lg),
                EnterprisePanel(
                  title: 'Terminal View',
                  subtitle:
                      'Streaming logs from the backend automation service, including Canon command and deployment events.',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AetherSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF091019),
                      borderRadius: BorderRadius.circular(AetherRadii.lg),
                      border: Border.all(color: AetherColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final log in logs.take(12))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '[${_time(log.timestamp)}] ${log.stage.padRight(20)} ${log.status.padRight(12)} confidence=${log.confidence.toStringAsFixed(2)}  ${log.message}',
                              style: numericStyle(context, size: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AetherSpacing.lg),
                EnterpriseDataTable<StrategyMonitorLogModel>(
                  title: 'Execution Timeline',
                  subtitle:
                      'Operational log of pipeline state, agent decisions, and execution readiness.',
                  rows: logs,
                  rowId: (row) =>
                      '${row.strategyId}-${row.timestamp?.toIso8601String() ?? row.stage}',
                  searchHint: 'Search log stage or message',
                  searchText: (row) =>
                      '${row.strategyName} ${row.stage} ${row.message} ${row.status}',
                  columns: [
                    EnterpriseTableColumn(
                      label: 'Timestamp',
                      width: 110,
                      cell: (row) => _time(row.timestamp),
                      sortValue: (row) => _time(row.timestamp),
                    ),
                    EnterpriseTableColumn(
                      label: 'Strategy',
                      width: 180,
                      cell: (row) => row.strategyName,
                      sortValue: (row) => row.strategyName,
                    ),
                    EnterpriseTableColumn(
                      label: 'Stage',
                      width: 150,
                      cell: (row) => row.stage,
                      sortValue: (row) => row.stage,
                    ),
                    EnterpriseTableColumn(
                      label: 'Message',
                      width: 360,
                      cell: (row) => row.message,
                      sortValue: (row) => row.message,
                    ),
                    EnterpriseTableColumn(
                      label: 'Status',
                      width: 120,
                      cell: (row) => row.status,
                      sortValue: (row) => row.status,
                    ),
                    EnterpriseTableColumn(
                      label: 'Confidence',
                      width: 100,
                      numeric: true,
                      cell: (row) =>
                          '${(row.confidence * 100).toStringAsFixed(0)}%',
                      sortValue: (row) => row.confidence,
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EnterprisePanel(
            title: 'Unable to load monitor stream',
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
          'Terminal-style monitoring for ingestion, signal detection, probability calculation, decisioning, execution, and outcome tracking.',
      child: content,
    );
  }

  String _time(DateTime? value) {
    if (value == null) return '--:--:--';
    final utc = value.toUtc();
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    final ss = utc.second.toString().padLeft(2, '0');
    return '$hh:$mm:${ss}Z';
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(AetherSpacing.md),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(AetherRadii.md),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AetherSpacing.sm),
          StatusBadge(label: status),
        ],
      ),
    );
  }
}
