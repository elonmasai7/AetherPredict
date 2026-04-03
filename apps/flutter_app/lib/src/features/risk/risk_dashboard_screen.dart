import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class RiskDashboardScreen extends ConsumerWidget {
  const RiskDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risk = ref.watch(riskProvider);
    final exposure = ref.watch(exposureProvider);
    final performance = ref.watch(performanceProvider);

    return AppScaffold(
      title: 'Risk Dashboard',
      child: risk.when(
        data: (riskData) => ListView(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _card('Exposure', '${riskData.totalExposure.toStringAsFixed(1)}'),
                _card('Risk Score', riskData.riskScore),
                _card('Max Loss', '\$${riskData.maxLoss.toStringAsFixed(0)}'),
                _card('VaR 95', '\$${riskData.var95.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category Allocation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  exposure.when(
                    data: (items) => Column(children: items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${item.category}: ${item.allocation.toStringAsFixed(1)}%'),
                    )).toList()),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Text(error.toString()),
                  ),
                  const SizedBox(height: 12),
                  const Text('Performance'),
                  performance.when(
                    data: (items) => Column(children: items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${item.label}: \$${item.pnl.toStringAsFixed(0)}'),
                    )).toList()),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Text(error.toString()),
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

  Widget _card(String title, String value) {
    return SizedBox(
      width: 260,
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
