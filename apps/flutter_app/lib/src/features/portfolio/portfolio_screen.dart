import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    return AppScaffold(
      title: 'Portfolio',
      child: portfolio.when(
        data: (items) => ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Net PnL', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${items.fold<double>(0, (sum, item) => sum + item.pnl).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('${item.marketTitle}  |  ${item.side}  |  PnL \$${item.pnl.toStringAsFixed(0)}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
