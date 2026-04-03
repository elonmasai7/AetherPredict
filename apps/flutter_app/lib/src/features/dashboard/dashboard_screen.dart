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
    final liveUpdate = ref.watch(marketUpdatesProvider);

    return AppScaffold(
      title: 'Command Center',
      child: marketItems.when(
        data: (markets) => agentItems.when(
          data: (agents) => ListView(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _metricCard('Live Markets', '${markets.length}', 'Streaming from FastAPI'),
                  _metricCard('AI Confidence', '${(markets.first.aiConfidence * 100).round()}%', 'Latest top-market confidence'),
                  _metricCard(
                    'Liquidity Depth',
                    '\$${markets.fold<double>(0, (sum, item) => sum + item.liquidity).toStringAsFixed(0)}',
                    'Across active markets',
                  ),
                  _metricCard(
                    'Alerts',
                    liveUpdate.maybeWhen(data: (_) => '1', orElse: () => '0'),
                    liveUpdate.maybeWhen(
                      data: (value) => '${value.market} moved to ${(value.yesProbability * 100).round()}% YES',
                      orElse: () => 'Waiting for stream',
                    ),
                  ),
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
                          SizedBox(height: 260, child: MarketChart(points: markets.first.points)),
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
                          ...agents.map(
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
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
