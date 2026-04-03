import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class TradeScreen extends StatelessWidget {
  const TradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Trade',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Execute position', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                const TextField(decoration: InputDecoration(labelText: 'Collateral amount')),
                const SizedBox(height: 12),
                const TextField(decoration: InputDecoration(labelText: 'Slippage tolerance')),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: () {}, child: const Text('Buy YES'))),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Buy NO'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
