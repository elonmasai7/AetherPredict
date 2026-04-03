import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentItems = ref.watch(agentListProvider);
    return AppScaffold(
      title: 'AI Agents',
      child: agentItems.when(
        data: (items) => ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, index) {
            final agent = items[index];
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Status: ${agent.status}'),
                  const SizedBox(height: 8),
                  Text(agent.summary),
                  const SizedBox(height: 12),
                  Text('PnL: \$${agent.pnl.toStringAsFixed(0)}'),
                ],
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
