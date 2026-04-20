import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class LiquidityDashboardScreen extends ConsumerWidget {
  const LiquidityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardValue = ref.watch(liquidityDashboardProvider);

    return AppScaffold(
      title: 'Liquidity Intelligence',
      subtitle:
          'Institutional-grade probability liquidity monitoring for prediction markets, with spread, depth, concentration, and slippage intelligence.',
      child: dashboardValue.when(
        data: (dashboard) {
          final topMarket =
              dashboard.marketRankings.isEmpty ? null : dashboard.marketRankings.first;
          final widestSpread = dashboard.leastLiquidMarkets.isEmpty
              ? null
              : dashboard.leastLiquidMarkets.first;
          return ListView(
            children: [
              KpiStrip(
                items: [
                  KpiStripItem(
                    label: 'Tracked Markets',
                    value: dashboard.marketCount.toString(),
                  ),
                  KpiStripItem(
                    label: 'Most Liquid Market',
                    value: (topMarket?['title'] as String?) ?? 'N/A',
                  ),
                  KpiStripItem(
                    label: 'Best Spread',
                    value: topMarket == null
                        ? 'N/A'
                        : '${topMarket['spread_cents']}c',
                  ),
                  KpiStripItem(
                    label: 'Widest Spread',
                    value: widestSpread == null
                        ? 'N/A'
                        : '${widestSpread['spread_cents']}c',
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1180;
                  final left = _tablePanel(
                    title: 'Spread Leaderboard',
                    subtitle: 'Tightest prediction spreads and strongest execution quality.',
                    rows: dashboard.spreadLeaderboard,
                    metricLabel: 'Spread',
                    metricBuilder: (row) => '${row['spread_cents']}c',
                  );
                  final right = _tablePanel(
                    title: 'Slippage Heatmap',
                    subtitle: 'Markets where small-ticket execution needs extra care.',
                    rows: dashboard.slippageHeatmap,
                    metricLabel: 'Slippage',
                    metricBuilder: (row) =>
                        '${((row['small_ticket_slippage_pct'] as num?) ?? 0).toStringAsFixed(2)}%',
                  );
                  if (compact) {
                    return Column(
                      children: [
                        left,
                        const SizedBox(height: AetherSpacing.lg),
                        right,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: AetherSpacing.lg),
                      Expanded(child: right),
                    ],
                  );
                },
              ),
              const SizedBox(height: AetherSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1180;
                  final left = _tablePanel(
                    title: 'Most Liquid Markets',
                    subtitle: 'Deepest YES/NO pools with strong support.',
                    rows: dashboard.mostLiquidMarkets,
                    metricLabel: 'Liquidity Score',
                    metricBuilder: (row) =>
                        ((row['liquidity_score'] as num?) ?? 0).toStringAsFixed(1),
                  );
                  final right = _tablePanel(
                    title: 'Least Liquid Markets',
                    subtitle: 'Markets with widening spreads and thinner probability depth.',
                    rows: dashboard.leastLiquidMarkets,
                    metricLabel: 'Risk',
                    metricBuilder: (row) => (row['risk_label'] as String?) ?? 'N/A',
                  );
                  if (compact) {
                    return Column(
                      children: [
                        left,
                        const SizedBox(height: AetherSpacing.lg),
                        right,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: AetherSpacing.lg),
                      Expanded(child: right),
                    ],
                  );
                },
              ),
              const SizedBox(height: AetherSpacing.lg),
              _tablePanel(
                title: 'LP Distribution',
                subtitle:
                    'Concentration risk across supported prediction markets and decentralization health.',
                rows: dashboard.lpDistribution,
                metricLabel: 'Top LP Share',
                metricBuilder: (row) =>
                    '${((row['top_lp_share_pct'] as num?) ?? 0).toStringAsFixed(1)}%',
                trailingBuilder: (row) => StatusBadge(
                  label:
                      'Decentralization ${((row['decentralization_index'] as num?) ?? 0).toStringAsFixed(0)}',
                  color: (((row['top_lp_share_pct'] as num?) ?? 0) >= 60)
                      ? AetherColors.warning
                      : AetherColors.success,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to load liquidity intelligence',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Widget _tablePanel({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> rows,
    required String metricLabel,
    required String Function(Map<String, dynamic> row) metricBuilder,
    Widget Function(Map<String, dynamic> row)? trailingBuilder,
  }) {
    return EnterprisePanel(
      title: title,
      subtitle: subtitle,
      child: rows.isEmpty
          ? const Text(
              'No liquidity intelligence rows available yet.',
              style: TextStyle(color: AetherColors.muted),
            )
          : Column(
              children: [
                for (final row in rows)
                  Container(
                    margin: const EdgeInsets.only(bottom: AetherSpacing.sm),
                    padding: const EdgeInsets.all(AetherSpacing.md),
                    decoration: BoxDecoration(
                      color: AetherColors.bgPanel,
                      borderRadius: BorderRadius.circular(AetherRadii.md),
                      border: Border.all(color: AetherColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (row['title'] as String?) ?? 'Unknown market',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${row['category'] ?? row['risk_label'] ?? 'Prediction market'} • $metricLabel ${metricBuilder(row)}',
                                style: const TextStyle(color: AetherColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AetherSpacing.sm),
                        trailingBuilder?.call(row) ??
                            StatusBadge(
                              label: metricBuilder(row),
                              color: ((row['risk_label'] as String?) == 'High Risk')
                                  ? AetherColors.warning
                                  : AetherColors.accent,
                            ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
