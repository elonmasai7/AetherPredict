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
  ConsumerState<RiskDashboardScreen> createState() =>
      _RiskDashboardScreenState();
}

class _RiskDashboardScreenState extends ConsumerState<RiskDashboardScreen> {
  double _consensusShockPct = -12;
  ActionButtonState _simulationState = ActionButtonState.idle;
  String? _simulationMessage;

  @override
  Widget build(BuildContext context) {
    final riskValue = ref.watch(riskProvider);
    final exposureValue = ref.watch(exposureProvider);

    return AppScaffold(
      title: 'Risk Intelligence',
      subtitle:
          'Institutional risk analytics for event probability volatility, manipulation exposure, dispute likelihood, and liquidity stress.',
      child: riskValue.when(
        data: (risk) {
          final confidenceVolatility =
              (risk.volatilityScore * 100).clamp(8, 95).toDouble();
          final manipulationRisk =
              min(100, max(5, (risk.confidenceWeightedRisk * 100).round()))
                  .toDouble();
          final disputeLikelihood = min(100,
                  max(4, ((risk.var95 / max(risk.maxLoss, 1)) * 100).round()))
              .toDouble();
          final liquidityRisk = min(
                  100,
                  max(3,
                      ((risk.totalExposure / max(risk.var95, 1)) * 4).round()))
              .toDouble();
          final resolutionAmbiguity = min(
                  100,
                  max(6,
                      ((confidenceVolatility + disputeLikelihood) / 2).round()))
              .toDouble();

          return ListView(
            children: [
              KpiStrip(
                items: [
                  KpiStripItem(
                    label: 'Event Risk',
                    value: risk.riskScore,
                  ),
                  KpiStripItem(
                    label: 'Confidence Volatility',
                    value: '${confidenceVolatility.toStringAsFixed(1)}%',
                  ),
                  KpiStripItem(
                    label: 'Manipulation Risk',
                    value: '${manipulationRisk.toStringAsFixed(0)}/100',
                  ),
                  KpiStripItem(
                    label: 'Dispute Likelihood',
                    value: '${disputeLikelihood.toStringAsFixed(0)}%',
                  ),
                  KpiStripItem(
                    label: 'Liquidity Risk',
                    value: '${liquidityRisk.toStringAsFixed(0)}%',
                  ),
                  KpiStripItem(
                    label: 'Resolution Ambiguity',
                    value: '${resolutionAmbiguity.toStringAsFixed(0)}%',
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.lg),
              exposureValue.when(
                data: (exposure) => EnterpriseDataTable<ExposureSlice>(
                  title: 'Event Concentration Map',
                  subtitle:
                      'Category-level allocation and concentration risk across active prediction markets.',
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
                    'Risk band ${row.allocation > 30 ? 'elevated' : 'contained'} for ${row.category} event cluster.',
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
                        _riskControlPanel(risk),
                        const SizedBox(height: AetherSpacing.lg),
                        _scenarioEnginePanel(
                          risk: risk,
                          confidenceVolatility: confidenceVolatility,
                          disputeLikelihood: disputeLikelihood,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _riskControlPanel(risk)),
                      const SizedBox(width: AetherSpacing.lg),
                      Expanded(
                        child: _scenarioEnginePanel(
                          risk: risk,
                          confidenceVolatility: confidenceVolatility,
                          disputeLikelihood: disputeLikelihood,
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

  Widget _riskControlPanel(PortfolioRiskSnapshot risk) {
    final rows = [
      _RiskControlRow('Single Event Exposure', '25%', '21%', 'Healthy'),
      _RiskControlRow('Category Concentration', '40%', '37%', 'Watch'),
      _RiskControlRow('Max Confidence Volatility', '65%',
          '${(risk.volatilityScore * 100).toStringAsFixed(0)}%', 'Healthy'),
      _RiskControlRow('Dispute Escalation Buffer', '30%', '24%', 'Watch'),
      _RiskControlRow('Resolution Ambiguity Cap', '45%', '32%', 'Healthy'),
    ];

    return EnterpriseDataTable<_RiskControlRow>(
      title: 'Risk Control Monitor',
      subtitle:
          'Institutional control thresholds vs current forecast risk utilization.',
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
          width: 240,
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
          const Text(
            'Control owner: Risk Intelligence Desk',
            style: TextStyle(color: AetherColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _scenarioEnginePanel({
    required PortfolioRiskSnapshot risk,
    required double confidenceVolatility,
    required double disputeLikelihood,
  }) {
    final projectedConfidenceDrawdown =
        confidenceVolatility * (_consensusShockPct.abs() / 100);
    final projectedDisputeSpike =
        min(100, disputeLikelihood + (_consensusShockPct.abs() * 0.7));
    final mitigationBoost = min(45,
        max(8, ((projectedDisputeSpike / max(risk.var95, 1)) * 12).round()));

    return EnterprisePanel(
      title: 'Scenario Intelligence Engine',
      subtitle:
          'What-if simulation for consensus shocks, dispute pressure, and liquidity dislocation.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consensus shock ${_consensusShockPct.toStringAsFixed(0)}%'),
          Slider(
            min: -45,
            max: 20,
            divisions: 65,
            value: _consensusShockPct,
            label: '${_consensusShockPct.toStringAsFixed(0)}%',
            onChanged: (value) => setState(() => _consensusShockPct = value),
          ),
          const SizedBox(height: AetherSpacing.sm),
          _scenarioRow('Projected confidence drawdown',
              '${projectedConfidenceDrawdown.toStringAsFixed(1)}%'),
          _scenarioRow('Projected dispute likelihood',
              '${projectedDisputeSpike.toStringAsFixed(1)}%'),
          _scenarioRow('Suggested mitigation increase', '$mitigationBoost%'),
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
            label: 'Run Risk Simulation',
            state: _simulationState,
            retryLabel: 'Retry Simulation',
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
          Expanded(
              child:
                  Text(key, style: const TextStyle(color: AetherColors.muted))),
          Text(value),
        ],
      ),
    );
  }

  Widget _errorPanel(String message) {
    return EnterprisePanel(
      title: 'Unable to load risk intelligence data',
      child:
          Text(message, style: const TextStyle(color: AetherColors.critical)),
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
      _simulationMessage = 'Running risk intelligence simulation...';
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final fail = _consensusShockPct <= -40;
    if (fail) {
      setState(() {
        _simulationState = ActionButtonState.failure;
        _simulationMessage =
            'Simulation timeout under extreme shock profile. Retry with lower magnitude or staged assumptions.';
      });
      return;
    }

    setState(() {
      _simulationState = ActionButtonState.success;
      _simulationMessage =
          'Simulation completed. Mitigation recommendations published to Operations and Resolution teams.';
    });
  }
}

class _RiskControlRow {
  const _RiskControlRow(
      this.control, this.threshold, this.current, this.status);

  final String control;
  final String threshold;
  final String current;
  final String status;
}
