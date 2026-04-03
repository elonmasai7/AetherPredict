import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class InsuranceCenterScreen extends ConsumerWidget {
  const InsuranceCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(insuranceQuoteProvider);
    final hedge = ref.watch(autoHedgeProvider);
    return AppScaffold(
      title: 'Insurance Center',
      child: ListView(
        children: [
          quote.when(
            data: (item) => GlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Coverage Quote', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Premium ${item.premiumBps} bps'),
                Text('Coverage \$${item.coverageAmount.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                ...item.eligibleRisks.map(Text.new),
              ]),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
          const SizedBox(height: 16),
          hedge.when(
            data: (item) => GlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Auto Hedge', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Enabled: ${item.enabled}'),
                Text('Hedge Ratio: ${(item.hedgeRatio * 100).toStringAsFixed(0)}%'),
                Text('Protection Score: ${item.protectionScore}'),
                Text('Estimated Loss Reduction: \$${item.estimatedLossReduction.toStringAsFixed(0)}'),
              ]),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
        ],
      ),
    );
  }
}
