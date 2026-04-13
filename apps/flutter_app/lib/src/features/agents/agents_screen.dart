import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentItems = ref.watch(agentListProvider);
    return AppScaffold(
      title: 'Autonomous Agents',
      subtitle:
          'AI agents providing liquidity, rebalancing thin markets, detecting anomalies, and auto-hedging forecast exposure.',
      child: agentItems.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateCard(
              icon: Icons.smart_toy_outlined,
              title: 'No autonomous agents online',
              message:
                  'Agent capacity is currently unavailable. Retry after orchestration sync completes.',
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AetherSpacing.lg),
            itemBuilder: (_, index) {
              final agent = items[index];
              return EnterprisePanel(
                title: agent.name,
                subtitle: agent.summary,
                trailing:
                    StatusBadge(label: 'Status ${agent.status.toUpperCase()}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AetherSpacing.sm,
                      runSpacing: AetherSpacing.sm,
                      children: [
                        _metric('Strategy', agent.strategy),
                        _metric(
                          'Confidence',
                          '${(agent.confidence * 100).toStringAsFixed(1)}%',
                        ),
                        _metric(
                          'Historical Accuracy',
                          '${(agent.historicalAccuracy * 100).toStringAsFixed(1)}%',
                        ),
                        _metric('ROI', '${agent.roi.toStringAsFixed(1)}%'),
                        _metric(
                          'Active Markets',
                          agent.currentActiveMarkets.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AetherSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: agent.confidence.clamp(0, 1),
                            borderRadius: BorderRadius.circular(999),
                            backgroundColor: AetherColors.bgPanel,
                          ),
                        ),
                        const SizedBox(width: AetherSpacing.sm),
                        const Text(
                          'Confidence signal',
                          style: TextStyle(
                              color: AetherColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to load autonomous agents',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(AetherRadii.md),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AetherColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
