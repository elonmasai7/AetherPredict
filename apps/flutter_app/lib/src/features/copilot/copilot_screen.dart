import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class CopilotScreen extends ConsumerWidget {
  const CopilotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copilot = ref.watch(copilotProvider);
    return AppScaffold(
      title: 'Aether Copilot',
      child: copilot.when(
        data: (item) => ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trade Recommendation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Action: ${item.action}'),
                  Text('Confidence: ${item.confidence}%'),
                  Text('Risk: ${item.risk}'),
                  Text('Position Size: ${item.positionSize}'),
                  const SizedBox(height: 12),
                  Text(item.reasoning),
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
