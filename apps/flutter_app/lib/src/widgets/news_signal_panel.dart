import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'glass_card.dart';

class NewsSignalPanel extends StatelessWidget {
  const NewsSignalPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const feed = [
      'BTC whale transferred 5,000 BTC to exchange cluster',
      'Confidence increased from 72% to 81%',
      'Anomaly alert: sudden basis expansion on perpetuals',
      'ETF inflow print exceeded 30D average by 18%',
      'HashKey ecosystem token basket momentum turned positive',
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market News + Signals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...feed
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record,
                          size: 10, color: AetherColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
