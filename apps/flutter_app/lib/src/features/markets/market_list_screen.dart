import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/trading_view_chart.dart';

class MarketListScreen extends ConsumerStatefulWidget {
  const MarketListScreen({super.key});

  @override
  ConsumerState<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends ConsumerState<MarketListScreen> {
  String timeframe = '15m';

  @override
  Widget build(BuildContext context) {
    final marketItems = ref.watch(marketListProvider);
    return AppScaffold(
      title: 'Markets',
      child: marketItems.when(
        data: (items) => ListView(
          children: [
            GlassCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tf in const ['1m', '5m', '15m', '1h', '4h', '1D'])
                    ChoiceChip(
                      label: Text(tf),
                      selected: timeframe == tf,
                      onSelected: (_) => setState(() => timeframe = tf),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final market = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    ref.read(selectedMarketIndexProvider.notifier).state =
                        index;
                    context.go('/markets/detail');
                  },
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          market.category,
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                        const SizedBox(height: 8),
                        Text(market.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'AI ${(market.aiConfidence * 100).toStringAsFixed(0)}% • Vol \$${market.volume.toStringAsFixed(0)}',
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                        const SizedBox(height: 12),
                        TradingViewChart(
                          symbol: _marketSymbol(market.title),
                          timeframe: timeframe,
                          height: 280,
                          overlayProbability: market.yesProbability,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                                '${(market.yesProbability * 100).round()}% YES',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(selectedMarketIndexProvider.notifier)
                                    .state = index;
                                context.go('/markets/detail');
                              },
                              child: const Text('Open Market'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                ref
                                    .read(selectedMarketIndexProvider.notifier)
                                    .state = index;
                                context.go('/markets/detail');
                              },
                              child: const Text('Trade'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  String _marketSymbol(String title) {
    final upper = title.toUpperCase();
    if (upper.contains('BTC')) return 'BTC/USD';
    if (upper.contains('ETH')) return 'ETH/USD';
    if (upper.contains('SOL')) return 'SOL/USD';
    if (upper.contains('HASHKEY')) return 'HSK/USD';
    return 'BTC/USD';
  }
}
