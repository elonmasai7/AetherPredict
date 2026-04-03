import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/market_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketItems = ref.watch(marketListProvider);
    final agentItems = ref.watch(agentListProvider);

    return AppScaffold(
      title: 'Command Center',
      child: ListView(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _metricCard('Live Markets', '${marketItems.length}', '12 streaming in real time'),
              _metricCard('AI Confidence', '89%', 'Aggregate confidence across active markets'),
              _metricCard('Liquidity Depth', '\$745k', 'Autonomous LP support active'),
              _metricCard('Alerts', '3', '1 high-priority anomaly flagged'),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 780,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trending probabilities', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      SizedBox(height: 260, child: MarketChart(points: marketItems.first.points)),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 360,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Agent status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      ...agentItems.map(
                        (agent) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text('${agent.name}: ${agent.status}  |  PnL \$${agent.pnl.toStringAsFixed(0)}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, String detail) {
    return SizedBox(
      width: 280,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.72))),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(detail, style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}
