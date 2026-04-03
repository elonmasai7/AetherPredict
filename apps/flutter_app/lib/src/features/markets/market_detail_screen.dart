import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/market_chart.dart';

class MarketDetailScreen extends ConsumerWidget {
  const MarketDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(selectedMarketProvider);
    return AppScaffold(
      title: 'Market Detail',
      child: ListView(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(market.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Text('AI confidence ${(market.aiConfidence * 100).round()}%  |  Liquidity \$${market.liquidity.toStringAsFixed(0)}'),
                const SizedBox(height: 18),
                SizedBox(height: 280, child: MarketChart(points: market.points)),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(onPressed: () => context.go('/trade'), child: const Text('Buy YES')),
                    OutlinedButton(onPressed: () => context.go('/trade'), child: const Text('Buy NO')),
                    OutlinedButton(onPressed: () {}, child: const Text('Dispute')),
                    OutlinedButton(onPressed: () {}, child: const Text('Claim Rewards')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
