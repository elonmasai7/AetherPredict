import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/market_provider.dart';
import '../widgets/probability_bar.dart';
import '../widgets/spread_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markets = ref.watch(marketListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PredictOdds Pro'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(marketListProvider.future),
        child: markets.when(
          data: (items) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final market = items[index];
              return Card(
                child: ListTile(
                  onTap: () => ref.read(selectedMarketIdProvider.notifier).state = market.id,
                  title: Text(market.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(market.event),
                      const SizedBox(height: 8),
                      ProbabilityBar(yesProbability: market.yesPrice),
                      const SizedBox(height: 8),
                      Text(
                        'YES ${(market.yesPrice * 100).toStringAsFixed(1)}¢ / NO ${(market.noPrice * 100).toStringAsFixed(1)}¢ · Liquidity \$${market.liquidityUsd.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  trailing: SpreadBadge(spreadCents: market.spreadCents, tier: market.spreadTier),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}
