import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class RiskDashboardScreen extends ConsumerStatefulWidget {
  const RiskDashboardScreen({super.key});

  @override
  ConsumerState<RiskDashboardScreen> createState() => _RiskDashboardScreenState();
}

class _RiskDashboardScreenState extends ConsumerState<RiskDashboardScreen> {
  double btcShock = -15;

  @override
  Widget build(BuildContext context) {
    final risk = ref.watch(riskProvider);
    final exposure = ref.watch(exposureProvider);
    final performance = ref.watch(performanceProvider);

    return AppScaffold(
      title: 'Portfolio Risk Dashboard',
      child: risk.when(
        data: (riskData) {
          final projectedPnl = riskData.totalExposure * (btcShock / 100) * 0.82;
          final liquidationRisk = projectedPnl.abs() > riskData.maxLoss * 0.6 ? 'Elevated' : 'Contained';
          final hedge = projectedPnl.abs() > riskData.var95 ? 'Increase protective NO exposure by 12%' : 'Current hedge is sufficient';

          return ListView(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _metric('Total Exposure', '\$${riskData.totalExposure.toStringAsFixed(0)}'),
                  _metric('Volatility Score', riskData.volatilityScore.toStringAsFixed(2)),
                  _metric('VaR Estimate', '\$${riskData.var95.toStringAsFixed(0)}'),
                  _metric('Max Loss Simulation', '\$${riskData.maxLoss.toStringAsFixed(0)}'),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: 420, child: _exposurePie(exposure)),
                  SizedBox(width: 520, child: _riskHeatmap()),
                  SizedBox(width: 520, child: _performanceGraph(performance)),
                  SizedBox(
                    width: 420,
                    child: _scenarioEngine(
                      projectedPnl: projectedPnl,
                      liquidationRisk: liquidationRisk,
                      hedgeRecommendation: hedge,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Widget _metric(String title, String value) {
    return SizedBox(
      width: 260,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AetherColors.muted)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _exposurePie(AsyncValue<List<ExposureSlice>> exposure) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category Exposure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          exposure.when(
            data: (items) => SizedBox(
              height: 260,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 46,
                  sections: [
                    for (var i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].allocation,
                        title: '${items[i].allocation.toStringAsFixed(0)}%',
                        radius: 56,
                        color: [AetherColors.accent, AetherColors.success, AetherColors.warning, AetherColors.accentSoft][i % 4],
                      ),
                  ],
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 100),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _riskHeatmap() {
    final rows = [
      ['BTC', '0.82', 'High'],
      ['ETH', '0.64', 'Medium'],
      ['HashKey Ecosystem', '0.58', 'Medium'],
      ['Macro', '0.41', 'Low'],
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risk Heatmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          DataTable(
            columns: const [
              DataColumn(label: Text('Bucket')),
              DataColumn(label: Text('Intensity')),
              DataColumn(label: Text('Risk')),
            ],
            rows: [
              for (final row in rows)
                DataRow(cells: [
                  DataCell(Text(row[0])),
                  DataCell(Text(row[1])),
                  DataCell(Text(row[2])),
                ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceGraph(AsyncValue<List<PerformancePoint>> performance) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Graph', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          performance.when(
            data: (points) => SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: AetherColors.accent,
                      barWidth: 2.5,
                      belowBarData: BarAreaData(show: true, color: AetherColors.accent.withValues(alpha: 0.18)),
                      spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].pnl)],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 100),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _scenarioEngine({
    required double projectedPnl,
    required String liquidationRisk,
    required String hedgeRecommendation,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scenario Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text('What if BTC drops ${btcShock.toStringAsFixed(0)}%?'),
          Slider(
            value: btcShock,
            min: -40,
            max: 20,
            divisions: 60,
            onChanged: (value) => setState(() => btcShock = value),
          ),
          const SizedBox(height: 8),
          Text('Projected PnL: ${projectedPnl >= 0 ? '+' : ''}\$${projectedPnl.toStringAsFixed(0)}', style: TextStyle(color: projectedPnl >= 0 ? AetherColors.success : AetherColors.critical)),
          const SizedBox(height: 6),
          Text('Liquidation Risk: $liquidationRisk'),
          const SizedBox(height: 6),
          Text('Hedge Recommendation: $hedgeRecommendation'),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_graph), label: const Text('Apply Hedge Plan')),
        ],
      ),
    );
  }
}
