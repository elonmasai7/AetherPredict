import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';
import 'strategy_engine_models.dart';
import 'strategy_engine_widgets.dart';

class MyStrategiesScreen extends ConsumerStatefulWidget {
  const MyStrategiesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<MyStrategiesScreen> createState() => _MyStrategiesScreenState();
}

class _MyStrategiesScreenState extends ConsumerState<MyStrategiesScreen> {
  String? _selectedStrategyId;
  bool _runningAction = false;
  String? _lastExportSummary;

  @override
  Widget build(BuildContext context) {
    final stateValue = ref.watch(strategyEngineStateProvider);
    final content = StrategyShell(
      title: 'My Strategies',
      subtitle:
          'Live backend state for forecasting systems, Canon workflow actions, and prediction-market deployment readiness.',
      currentPath: '/strategy-engine',
      child: stateValue.when(
          data: (state) {
            final selected = _resolveSelection(state.strategies);
            if (state.strategies.isEmpty) {
              return ListView(
                children: [
                  _metricWrap(state),
                  const SizedBox(height: AetherSpacing.lg),
                  _automationFocusPanel(),
                  const SizedBox(height: AetherSpacing.lg),
                  EmptyStateCard(
                    icon: Icons.hub_outlined,
                    title: 'No strategy workflows yet',
                    message:
                        'Use the AI Builder to create a live Canon project for arbitrage, cross-market lag, speed-based, or custom forecasting automation.',
                    actionLabel: 'Open AI Builder',
                    onAction: () => context.go('/strategy-engine/ai-builder'),
                  ),
                ],
              );
            }
            return ListView(
              children: [
                _metricWrap(state),
                const SizedBox(height: AetherSpacing.lg),
                EnterprisePanel(
                  title: 'Canon CLI Prediction Workflow',
                  subtitle:
                      'Live backend commands driving scaffold, execution, deployment, and monitoring state.',
                  child: Column(
                    children: [
                      for (final command in state.canonCommands) ...[
                        _CommandRow(command: command),
                        if (command != state.canonCommands.last)
                          const Divider(height: 24),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AetherSpacing.lg),
                _automationFocusPanel(),
                const SizedBox(height: AetherSpacing.lg),
                EnterprisePanel(
                  title: 'Command Center',
                  subtitle:
                      'Run Canon actions against a real strategy record and keep the UI synced to backend workflow state.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selected?.id,
                        decoration: const InputDecoration(
                          labelText: 'Active strategy',
                        ),
                        items: [
                          for (final strategy in state.strategies)
                            DropdownMenuItem(
                              value: strategy.id,
                              child: Text(strategy.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedStrategyId = value),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: AetherSpacing.md),
                        Wrap(
                          spacing: AetherSpacing.sm,
                          runSpacing: AetherSpacing.sm,
                          children: [
                            FilledButton.icon(
                              onPressed:
                                  _runningAction ? null : () => _runCanon('init'),
                              icon: const Icon(Icons.build_circle_outlined),
                              label: const Text('canon init'),
                            ),
                            FilledButton.icon(
                              onPressed: _runningAction
                                  ? null
                                  : () => _runCanon('start'),
                              icon: const Icon(Icons.play_circle_outline_rounded),
                              label: const Text('canon start'),
                            ),
                            FilledButton.icon(
                              onPressed: _runningAction
                                  ? null
                                  : () => _runCanon('deploy'),
                              icon: const Icon(Icons.rocket_launch_outlined),
                              label: const Text('canon deploy'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _runningAction ? null : _exportProject,
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Export Project'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AetherSpacing.md),
                        Text(
                          'Selected stage: ${selected.stage} • ${selected.status} • ${selected.projectPath}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (_lastExportSummary != null) ...[
                          const SizedBox(height: AetherSpacing.xs),
                          Text(
                            _lastExportSummary!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AetherColors.accent,
                                    ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AetherSpacing.lg),
                EnterpriseDataTable<StrategyRecordModel>(
                  title: 'Strategy Registry',
                  subtitle:
                      'Authenticated backend strategy records with live pipeline state.',
                  rows: state.strategies,
                  rowId: (row) => row.id,
                  searchHint: 'Search strategy or market',
                  searchText: (row) =>
                      '${row.name} ${row.market} ${row.templateName} ${row.prompt}',
                  filters: [
                    EnterpriseTableFilter(
                      label: 'Live deployment',
                      predicate: (row) => row.stage == 'Live deployment',
                    ),
                    EnterpriseTableFilter(
                      label: 'Simulation',
                      predicate: (row) => row.stage == 'Simulation',
                    ),
                  ],
                  columns: [
                    EnterpriseTableColumn(
                      label: 'Strategy',
                      width: 180,
                      cell: (row) => row.name,
                      sortValue: (row) => row.name,
                    ),
                    EnterpriseTableColumn(
                      label: 'Template',
                      width: 220,
                      cell: (row) => row.templateName,
                      sortValue: (row) => row.templateName,
                    ),
                    EnterpriseTableColumn(
                      label: 'Stage',
                      width: 140,
                      cell: (row) => row.stage,
                      sortValue: (row) => row.stage,
                    ),
                    EnterpriseTableColumn(
                      label: 'Target Market',
                      width: 260,
                      cell: (row) => row.market,
                      sortValue: (row) => row.market,
                    ),
                    EnterpriseTableColumn(
                      label: 'Confidence',
                      width: 120,
                      numeric: true,
                      cell: (row) =>
                          '${(row.confidence * 100).toStringAsFixed(1)}%',
                      sortValue: (row) => row.confidence,
                    ),
                    EnterpriseTableColumn(
                      label: 'Owner',
                      width: 180,
                      cell: (row) => row.owner,
                      sortValue: (row) => row.owner,
                    ),
                  ],
                  expandedBuilder: (row) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.prompt,
                        style: const TextStyle(color: AetherColors.text),
                      ),
                      const SizedBox(height: AetherSpacing.sm),
                      Wrap(
                        spacing: AetherSpacing.sm,
                        runSpacing: AetherSpacing.sm,
                        children: [
                          for (final step in row.pipeline)
                            Container(
                              width: 220,
                              padding: const EdgeInsets.all(AetherSpacing.sm),
                              decoration: BoxDecoration(
                                color: AetherColors.bgPanel,
                                borderRadius:
                                    BorderRadius.circular(AetherRadii.md),
                                border:
                                    Border.all(color: AetherColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AetherColors.accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: AetherSpacing.xs),
                                  StatusBadge(label: step.status),
                                  const SizedBox(height: AetherSpacing.xs),
                                  Text(
                                    step.detail,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EnterprisePanel(
            title: 'Unable to load strategy workflows',
            child: Text(
              error.toString(),
              style: const TextStyle(color: AetherColors.critical),
            ),
          ),
        ),
      );
    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AetherColors.bg,
        body: SafeArea(child: content),
      );
    }
    return AppScaffold(
      title: 'Strategy Engine',
      subtitle:
          'Canon CLI-powered forecasting workflows for building, validating, deploying, and monitoring prediction strategies.',
      child: content,
    );
  }

  Widget _metricWrap(StrategyEngineStateModel state) {
    return Wrap(
      spacing: AetherSpacing.md,
      runSpacing: AetherSpacing.md,
      children: [
        StrategyMetricCard(
          label: 'Active Strategies',
          value: '${state.metrics.activeStrategies}',
          detail: 'Persisted backend workflow records for this account',
        ),
        StrategyMetricCard(
          label: 'Forecast Accuracy',
          value: '${state.metrics.forecastAccuracy.toStringAsFixed(1)}%',
          detail: 'Average probability quality across registered strategies',
          color: AetherColors.success,
        ),
        StrategyMetricCard(
          label: 'Calibration Score',
          value: state.metrics.calibrationScore.toStringAsFixed(2),
          detail: 'Confidence alignment tracked from live workflow state',
          color: AetherColors.warning,
        ),
        StrategyMetricCard(
          label: 'Live Deployments',
          value: '${state.metrics.liveDeployments}',
          detail: 'Canon deploy activations currently targeting prediction markets',
          color: AetherColors.accentSoft,
        ),
      ],
    );
  }

  Widget _automationFocusPanel() {
    return EnterprisePanel(
      title: 'Microstructure Automation Lenses',
      subtitle:
          'AI-powered automations tailored to prediction market microstructures and lag capture.',
      child: Wrap(
        spacing: AetherSpacing.md,
        runSpacing: AetherSpacing.md,
        children: const [
          _AutomationCard(
            title: 'Arbitrage Detection',
            body:
                'Detect the same event trading at inconsistent implied probabilities across markets or within the platform.',
          ),
          _AutomationCard(
            title: 'Cross-Market Analysis',
            body:
                'Track correlated markets and capitalize when one market reacts slower than another.',
          ),
          _AutomationCard(
            title: 'Speed-Based Opportunity',
            body:
                'Act on public statistical inputs like records, matchups, or injury reports before the market updates.',
          ),
          _AutomationCard(
            title: 'Innovative',
            body:
                'Design custom signals from mixed sources and let the AI builder invent a new probability edge from scratch.',
          ),
        ],
      ),
    );
  }

  StrategyRecordModel? _resolveSelection(List<StrategyRecordModel> strategies) {
    if (strategies.isEmpty) return null;
    final selected = _selectedStrategyId;
    if (selected == null) {
      _selectedStrategyId = strategies.first.id;
      return strategies.first;
    }
    for (final strategy in strategies) {
      if (strategy.id == selected) return strategy;
    }
    _selectedStrategyId = strategies.first.id;
    return strategies.first;
  }

  Future<void> _runCanon(String command) async {
    final strategyId = _selectedStrategyId;
    if (strategyId == null) return;
    setState(() => _runningAction = true);
    try {
      final result =
          await ref.read(apiClientProvider).runCanonCommand(strategyId, command);
      ref.invalidate(strategyEngineStateProvider);
      ref.invalidate(strategyMonitorProvider);
      ref.invalidate(strategyRankingProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Canon command failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _runningAction = false);
      }
    }
  }

  Future<void> _exportProject() async {
    final strategyId = _selectedStrategyId;
    if (strategyId == null) return;
    setState(() => _runningAction = true);
    try {
      final export =
          await ref.read(apiClientProvider).exportStrategyProject(strategyId);
      ref.invalidate(strategyMonitorProvider);
      if (!mounted) return;
      setState(() {
        _lastExportSummary =
            'Prepared ${export.files.length} files for ${export.projectName}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export ready: ${export.exportLabel} (${export.files.length} files)',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _runningAction = false);
      }
    }
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({required this.command});

  final CanonCommandModel command;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 124,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AetherColors.bgPanel,
            borderRadius: BorderRadius.circular(AetherRadii.md),
            border: Border.all(color: AetherColors.border),
          ),
          child: Text(
            command.command,
            style: numericStyle(context, size: 13),
          ),
        ),
        const SizedBox(width: AetherSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                command.summary,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AetherSpacing.xs),
              for (final detail in command.details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $detail',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AutomationCard extends StatelessWidget {
  const _AutomationCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(AetherSpacing.md),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(AetherRadii.lg),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AetherSpacing.xs),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
