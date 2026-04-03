import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/market_chart.dart';

class MarketDetailScreen extends ConsumerWidget {
  const MarketDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(selectedMarketProvider);
    final copilot = ref.watch(copilotProvider);
    final sentiment = ref.watch(sentimentFeedProvider);
    final comments = ref.watch(discussionProvider);

    return AppScaffold(
      title: 'Market Detail',
      child: market.when(
        data: (item) => ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Text('AI confidence ${(item.aiConfidence * 100).round()}%  |  Liquidity \$${item.liquidity.toStringAsFixed(0)}'),
                  const SizedBox(height: 18),
                  SizedBox(height: 280, child: MarketChart(points: item.points)),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(onPressed: () => context.go('/trade'), child: const Text('Buy YES')),
                      OutlinedButton(onPressed: () => context.go('/trade'), child: const Text('Buy NO')),
                      OutlinedButton(onPressed: () => context.go('/discussion'), child: const Text('Discussion')),
                      OutlinedButton(onPressed: () => context.go('/insurance'), child: const Text('Insurance')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            copilot.when(
              data: (advice) => GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aether Copilot', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${advice.action}  |  ${advice.confidence}% confidence  |  ${advice.risk} risk'),
                    const SizedBox(height: 8),
                    Text(advice.reasoning),
                    const SizedBox(height: 10),
                    FilledButton(onPressed: () => context.go('/copilot'), child: const Text('Open Copilot')),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
            const SizedBox(height: 16),
            sentiment.when(
              data: (feed) => GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sentiment Feed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${feed.trend}  |  Score ${feed.sentimentScore.toStringAsFixed(2)}  |  Shift ${feed.confidenceShift}'),
                    const SizedBox(height: 8),
                    ...feed.newsItems.map((news) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${news.headline} • ${news.source}'),
                    )),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
            const SizedBox(height: 16),
            comments.when(
              data: (items) => GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discussion Highlights', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...items.take(2).map((comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('${comment.author}: ${comment.content}'),
                    )),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
