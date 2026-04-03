import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class MarketListScreen extends ConsumerWidget {
  const MarketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketItems = ref.watch(marketListProvider);
    return AppScaffold(
      title: 'Markets',
      child: marketItems.when(
        data: (items) => ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, index) {
            final market = items[index];
            return InkWell(
              onTap: () {
                ref.read(selectedMarketIndexProvider.notifier).state = index;
                context.go('/markets/detail');
              },
              child: GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(market.category, style: TextStyle(color: Colors.white.withOpacity(0.6))),
                          const SizedBox(height: 10),
                          Text(market.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Text('${(market.yesProbability * 100).round()}% YES'),
                    const SizedBox(width: 18),
                    FilledButton(onPressed: () => context.go('/trade'), child: const Text('Trade')),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
