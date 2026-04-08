import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class RiskDashboardScreen extends ConsumerStatefulWidget {
  const RiskDashboardScreen({super.key});

  @override
  ConsumerState<RiskDashboardScreen> createState() => _RiskDashboardScreenState();
}

class _RiskDashboardScreenState extends ConsumerState<RiskDashboardScreen> {
  double _shockPct = -15;
  ActionButtonState _simulationState = ActionButtonState.idle;
  String? _simulationMessage;

  @override
  Widget build(BuildContext context) {
    final riskValue = ref.watch(riskProvider);
    final exposureValue = ref.watch(exposureProvider);

    return AppScaffold(
      title: 'Risk',
      subtitle: 'Concentration controls, stress tests, and portfolio safeguard policies.',
      child: riskValue.when(
        data: (risk) {
          final projectedPnl = risk.totalExposure * (_shockPct / 100) * 0.82;
          final liquidationRisk = projectedPnl.abs() > risk.maxLoss * 0.7
              ? 'High'
              : projectedPnl.abs() > risk.maxLoss * 0.4
                  ? 'Moderate'
                  : 'Contained';

          return ListView(
            children: [
              KpiStrip(
                items: [
                  KpiStripItem(label: 'Total Exposure', value: formatUsd(risk.totalExposure)),
                  KpiStripItem(label: 'Max Loss', value: formatUsd(risk.maxLoss)),
                  KpiStripItem(label: 'VaR 95', value: formatUsd(risk.var95)),
                  KpiStripItem(
                    label: 'Volatility Score',
                    value: risk.volatilityScore.toStringAsFixed(2),
                  ),
                  KpiStripItem(label: 'Risk Score', value: risk.riskScore),
                ],
              ),
              const SizedBox(height: AetherSpacing.lg),
              exposureValue.when(
                data: (exposure) => EnterpriseDataTable<ExposureSlice>(
                  title: 'Exposure Concentration',
                  subtitle: 'Category-level allocation and concentration monitor.',
                  rows: exposure,
                  rowId: (row) => row.category,
                  searchHint: 'Search category',
                  filters: [
                    EnterpriseTableFilter(
                      label: 'Allocation > 25%',
                      predicate: (row) => row.allocation >= 25,
                    ),
                  ],
                  columns: [
                    EnterpriseTableColumn(
                      label: 'Category',
                      width: 220,
                      cell: (row) => row.category,
                      sortValue: (row) => row.category,
                    ),
                    EnterpriseTableColumn(
                      label: 'Allocation',
                      width: 140,
                      numeric: true,
                      cell: (row) => '${row.allocation.toStringAsFixed(2)}%',
                      sortValue: (row) => row.allocation,
                    ),
                  ],
                  expandedBuilder: (row) => Text(
                    'Concentration bucket ${row.allocation > 30 ? 'overwatch' : 'within threshold'} for ${row.category}.',
                    style: const TextStyle(color: AetherColors.muted),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _errorPanel(error.toString()),
              ),
              const SizedBox(height: AetherSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1200;
                  if (compact) {
                    return Column(
                      children: [
                        _limitMonitorPanel(risk),
                        const SizedBox(height: AetherSpacing.lg),
                        _scenarioEnginePanel(
                          risk: risk,
                          projectedPnl: projectedPnl,
                          liquidationRisk: liquidationRisk,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _limitMonitorPanel(risk)),
                      const SizedBox(width: AetherSpacing.lg),
                      Expanded(
                        child: _scenarioEnginePanel(
                          risk: risk,
                          projectedPnl: projectedPnl,
                          liquidationRisk: liquidationRisk,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorPanel(error.toString()),
      ),
    );
  }

  Widget _limitMonitorPanel(PortfolioRiskSnapshot risk) {
    final rows = [
      _LimitRow('Single Market Max', '25%', '21%', 'Healthy'),
      _LimitRow('Sector Concentration', '40%', '37%', 'Watch'),
      _LimitRow('Intraday Loss Cap', formatUsd(risk.maxLoss), formatUsd(risk.maxLoss * 0.63), 'Healthy'),
      _LimitRow('Leverage Utilization', '2.5x', '2.2x', 'Watch'),
      _LimitRow('Liquidity Coverage', '1.3x', '1.41x', 'Healthy'),
    ];

    return EnterpriseDataTable<_LimitRow>(
      title: 'Limit Monitor',
      subtitle: 'Control thresholds compared against current utilization.',
      rows: rows,
      rowId: (row) => row.control,
      searchHint: 'Search controls',
      filters: [
        EnterpriseTableFilter(
          label: 'Watch',
          predicate: (row) => row.status == 'Watch',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Control',
          width: 220,
          cell: (row) => row.control,
          sortValue: (row) => row.control,
        ),
        EnterpriseTableColumn(
          label: 'Threshold',
          width: 120,
          numeric: true,
          cell: (row) => row.threshold,
          sortValue: (row) => row.threshold,
        ),
        EnterpriseTableColumn(
          label: 'Current',
          width: 120,
          numeric: true,
          cell: (row) => row.current,
          sortValue: (row) => row.current,
        ),
        EnterpriseTableColumn(
          label: 'Status',
          width: 100,
          cell: (row) => row.status,
          sortValue: (row) => row.status,
        ),
      ],
      expandedBuilder: (row) => Row(
        children: [
          StatusBadge(
            label: row.status,
            color: row.status == 'Healthy'
                ? AetherColors.success
                : AetherColors.warning,
          ),
          const SizedBox(width: AetherSpacing.sm),
          Text(
            'Control owner: Risk Desk',
            style: const TextStyle(color: AetherColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _scenarioEnginePanel({
    required PortfolioRiskSnapshot risk,
    required double projectedPnl,
    required String liquidationRisk,
  }) {
    final projectedLossAbs = projectedPnl.abs();
    final hedgeBump = min(45, max(8, ((projectedLossAbs / max(risk.var95, 1)) * 12).round()));

    return EnterprisePanel(
      title: 'Scenario Engine',
      subtitle: 'What-if stress simulation for pre-hedge planning.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Underlying shock ${_shockPct.toStringAsFixed(0)}%'),
          Slider(
            min: -45,
            max: 20,
            divisions: 65,
            value: _shockPct,
            label: '${_shockPct.toStringAsFixed(0)}%',
            onChanged: (value) => setState(() => _shockPct = value),
          ),
          const SizedBox(height: AetherSpacing.sm),
          _scenarioRow('Projected PnL', formatUsd(projectedPnl)),
          _scenarioRow('Liquidation Risk', liquidationRisk),
          _scenarioRow('Suggested Hedge Increase', '$hedgeBump%'),
          const SizedBox(height: AetherSpacing.sm),
          if (_simulationMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AetherSpacing.sm),
              child: Text(
                _simulationMessage!,
                style: TextStyle(
                  color: _simulationState == ActionButtonState.failure
                      ? AetherColors.critical
                      : _simulationState == ActionButtonState.success
                          ? AetherColors.success
                          : AetherColors.muted,
                ),
              ),
            ),
          ActionStateButton(
            label: 'Run Stress Test',
            state: _simulationState,
            retryLabel: 'Retry Stress Test',
            onPressed: _runScenario,
          ),
        ],
      ),
    );
  }

  Widget _scenarioRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(key, style: const TextStyle(color: AetherColors.muted))),
          Text(value),
        ],
      ),
    );
  }

  Widget _errorPanel(String message) {
    return EnterprisePanel(
      title: 'Unable to load risk data',
      child: Text(message, style: const TextStyle(color: AetherColors.critical)),
    );
  }

  Future<void> _runScenario() async {
    if (_simulationState == ActionButtonState.loading) return;

    if (_simulationState == ActionButtonState.failure) {
      setState(() {
        _simulationState = ActionButtonState.idle;
        _simulationMessage = null;
      });
      return;
    }

    setState(() {
      _simulationState = ActionButtonState.loading;
      _simulationMessage = 'Running scenario across stress surfaces...';
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final fail = _shockPct <= -40;
    if (fail) {
      setState(() {
        _simulationState = ActionButtonState.failure;
        _simulationMessage =
            'Stress engine timeout at extreme shock levels. Retry or reduce shock magnitude.';
      });
      return;
    }

    setState(() {
      _simulationState = ActionButtonState.success;
      _simulationMessage =
          'Scenario completed. Hedge recommendation published to execution desk.';
    });
  }
}

class _LimitRow {
  const _LimitRow(this.control, this.threshold, this.current, this.status);

  final String control;
  final String threshold;
  final String current;
  final String status;
}
