import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'glass_card.dart';

class NewsSignalPanel extends StatelessWidget {
  const NewsSignalPanel({super.key, required this.feed});

  final SentimentFeed feed;

  @override
  Widget build(BuildContext context) {
    if (feed.newsItems.isEmpty) {
      return const GlassCard(
        child: Text(
          'No live news or sentiment signals are available for this market yet.',
          style: TextStyle(color: AetherColors.muted),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market News + Signals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...feed.newsItems
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
                          '${item.headline} • ${item.source}',
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
