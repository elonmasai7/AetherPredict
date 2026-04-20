import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/portfolio_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: dashboard.when(
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric('Cash', '\$${data.cashBalance.toStringAsFixed(2)}'),
                    _metric('P&L', '\$${data.totalPnl.toStringAsFixed(2)}'),
                    _metric('Positions', '${data.positions.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: _volumeSpreadChart(data)),
            const SizedBox(height: 16),
            ...data.positions.map(
              (position) => Card(
                child: ListTile(
                  title: Text(position.title),
                  subtitle: Text('${position.side} · ${position.shares.toStringAsFixed(2)} shares'),
                  trailing: Text('\$${position.pnl.toStringAsFixed(2)}'),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ],
    );
  }

  Widget _volumeSpreadChart(data) {
    final positions = data.positions;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: const Color(0xFF4A85F6),
            barWidth: 3,
            spots: [
              for (var i = 0; i < positions.length; i++)
                FlSpot(i.toDouble(), positions[i].volume / (positions[i].spreadCents + 1)),
            ],
          ),
        ],
      ),
    );
  }
}
