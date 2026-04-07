import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import 'copy_settings_dialog.dart';

class CopyTradingScreen extends ConsumerWidget {
  const CopyTradingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(copyPortfolioProvider);
    final relationships = ref.watch(copyRelationshipsProvider);
    final trades = ref.watch(copiedTradesProvider);

    ref.listen(copyUpdatesProvider, (previous, next) {
      next.whenData((_) {
        ref.invalidate(copyPortfolioProvider);
        ref.invalidate(copyRelationshipsProvider);
        ref.invalidate(copiedTradesProvider);
      });
    });

    return AppScaffold(
      title: 'Copy Trading',
      child: ListView(
        children: [
          summary.when(
            data: (item) => _summary(item),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => GlassCard(child: Text(error.toString())),
          ),
          const SizedBox(height: 16),
          _relationships(context, ref, relationships),
          const SizedBox(height: 16),
          _copiedTrades(trades),
        ],
      ),
    );
  }

  Widget _summary(CopyPortfolioSummaryModel summary) {
    return GlassCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metric('Copied Traders', summary.copiedTraders.toString()),
          _metric('Live Positions', summary.liveCopiedPositions.toString()),
          _metric('Copied ROI', '${(summary.copiedRoi * 100).toStringAsFixed(1)}%'),
          _metric('Active Alerts', summary.activeAlerts.toString()),
        ],
      ),
    );
  }

  Widget _relationships(BuildContext context, WidgetRef ref, AsyncValue<List<CopyRelationshipModel>> relationships) {
    return relationships.when(
      data: (items) {
        if (items.isEmpty) {
          return const GlassCard(child: Text('No active copy relationships. Follow a trader to begin.'));
        }
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Followed Traders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final relation in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trader #${relation.sourceUserId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Risk ${relation.riskLevel} • ${relation.status}', style: const TextStyle(color: AetherColors.muted)),
                          ],
                        ),
                      ),
                      Text('${(relation.allocationPct * 100).toStringAsFixed(1)}% allocation'),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _showSettings(context, ref, relation),
                        child: const Text('Settings'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final api = ref.read(apiClientProvider);
                          await api.stopCopying(relation.id);
                          ref.invalidate(copyRelationshipsProvider);
                        },
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => GlassCard(child: Text(error.toString())),
    );
  }

  Widget _copiedTrades(AsyncValue<List<CopiedTradeModel>> trades) {
    return trades.when(
      data: (items) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copied Trades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No copied trades yet.', style: TextStyle(color: AetherColors.muted))
            else
              Column(
                children: [
                  for (final trade in items.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text('Trade #${trade.sourceTradeId}')),
                          Expanded(child: Text('Market ${trade.marketId}')),
                          Expanded(child: Text('${(trade.copiedAllocation * 100).toStringAsFixed(1)}%')),
                          Expanded(child: Text(trade.status)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => GlassCard(child: Text(error.toString())),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AetherColors.bgPanel,
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AetherColors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _showSettings(BuildContext context, WidgetRef ref, CopyRelationshipModel relation) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CopySettingsDialog(
        title: 'Copy Settings',
        initialAllocation: relation.allocationPct,
        initialMaxLoss: relation.maxLossPct,
        initialAutoStop: relation.autoStopThreshold,
        initialRisk: relation.riskLevel,
      ),
    );
    if (result == null) return;
    final api = ref.read(apiClientProvider);
    await api.updateCopySettings(relation.id, result);
    ref.invalidate(copyRelationshipsProvider);
  }
}
