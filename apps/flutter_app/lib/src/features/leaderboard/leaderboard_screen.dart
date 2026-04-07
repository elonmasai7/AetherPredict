import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../copy_trading/copy_settings_dialog.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String query = '';
  String range = '30D';

  @override
  Widget build(BuildContext context) {
    final traders = ref.watch(traderLeaderboardProvider);
    final agents = ref.watch(agentLeaderboardProvider);
    final jurors = ref.watch(jurorLeaderboardProvider);

    return AppScaffold(
      title: 'Leaderboard',
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search participant'),
                    onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: range,
                  items: const [
                    DropdownMenuItem(value: '7D', child: Text('7D')),
                    DropdownMenuItem(value: '30D', child: Text('30D')),
                    DropdownMenuItem(value: '90D', child: Text('90D')),
                    DropdownMenuItem(value: 'YTD', child: Text('YTD')),
                  ],
                  onChanged: (value) => setState(() => range = value ?? '30D'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const TabBar(
              tabs: [
                Tab(text: 'Top Traders'),
                Tab(text: 'Best Agents'),
                Tab(text: 'Top Jurors'),
                Tab(text: 'Market Creators'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _tableFor(traders, enableActions: true),
                  _tableFor(agents),
                  _tableFor(jurors),
                  _marketCreatorsMock(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableFor(AsyncValue<List<LeaderboardEntry>> source, {bool enableActions = false}) {
    return source.when(
      data: (items) {
        final filtered = items.where((i) => query.isEmpty || i.name.toLowerCase().contains(query)).toList();
        return GlassCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Rank')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('7D ROI')),
                DataColumn(label: Text('30D ROI')),
                DataColumn(label: Text('Lifetime Accuracy')),
                DataColumn(label: Text('Win Rate')),
                DataColumn(label: Text('Copied Followers')),
                DataColumn(label: Text('Assets Copied')),
                DataColumn(label: Text('Score')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                for (final item in filtered)
                  DataRow(cells: [
                    DataCell(_badge(item.rank)),
                    DataCell(Text(item.name)),
                    DataCell(Text('${item.roi7d.toStringAsFixed(1)}%')),
                    DataCell(Text('${item.roi30d.toStringAsFixed(1)}%')),
                    DataCell(Text('${item.lifetimeAccuracy.toStringAsFixed(1)}%')),
                    DataCell(Text('${item.winRate.toStringAsFixed(1)}%')),
                    DataCell(Text('${item.copiedFollowers}')),
                    DataCell(Text('\$${item.assetsCopied.toStringAsFixed(1)}')),
                    DataCell(Text(item.score.toStringAsFixed(1))),
                    DataCell(
                      enableActions
                          ? _actions(context, item)
                          : const SizedBox.shrink(),
                    ),
                  ]),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }

  Widget _marketCreatorsMock() {
    final rows = const [
      (1, 'MacroAlpha Lab', 28.4, 81.2, 72.0, 94.2),
      (2, 'Axiom Markets', 22.1, 76.3, 68.5, 90.0),
      (3, 'Delta Foundry', 18.9, 74.8, 66.9, 87.6),
    ];

    return GlassCard(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Rank')),
          DataColumn(label: Text('Creator')),
          DataColumn(label: Text('ROI')),
          DataColumn(label: Text('Accuracy')),
          DataColumn(label: Text('Win Rate')),
          DataColumn(label: Text('Score')),
        ],
        rows: [
          for (final row in rows)
            DataRow(cells: [
              DataCell(_badge(row.$1)),
              DataCell(Text(row.$2)),
              DataCell(Text('${row.$3.toStringAsFixed(1)}%')),
              DataCell(Text(row.$4.toStringAsFixed(1))),
              DataCell(Text('${row.$5.toStringAsFixed(1)}%')),
              DataCell(Text(row.$6.toStringAsFixed(1))),
            ]),
        ],
      ),
    );
  }

  Widget _badge(int rank) {
    final color = rank == 1
        ? AetherColors.warning
        : rank == 2
            ? Colors.blueGrey
            : rank == 3
                ? const Color(0xFF9C6E4A)
                : AetherColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text('#$rank'),
    );
  }

  Widget _actions(BuildContext context, LeaderboardEntry item) {
    if (item.userId == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        FilledButton.tonal(
          onPressed: () => _followTrader(context, item),
          child: const Text('Follow'),
        ),
        const SizedBox(width: 6),
        FilledButton(
          onPressed: () => _copyNow(context, item),
          child: const Text('Copy Now'),
        ),
      ],
    );
  }

  Future<void> _followTrader(BuildContext context, LeaderboardEntry item) async {
    if (item.userId == null) return;
    try {
      await ref.read(apiClientProvider).followTrader({
        'source_user_id': item.userId,
        'source_type': 'TRADER',
        'allocation_pct': 0.2,
        'max_loss_pct': 0.08,
        'risk_level': 'MEDIUM',
        'auto_stop_threshold': 0.08,
        'max_follower_exposure': 5000,
        'allowed_market_ids': <int>[],
      });
      ref.invalidate(copyRelationshipsProvider);
      ref.invalidate(copyPortfolioProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Followed ${item.name}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Follow failed: $error')),
        );
      }
    }
  }

  Future<void> _copyNow(BuildContext context, LeaderboardEntry item) async {
    if (item.userId == null) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CopySettingsDialog(
        title: 'Copy Settings',
        initialAllocation: 0.2,
        initialMaxLoss: 0.08,
        initialAutoStop: 0.08,
        initialRisk: 'MEDIUM',
      ),
    );
    if (result == null) return;
    final payload = {
      'source_user_id': item.userId,
      'source_type': 'TRADER',
      ...result,
      'max_follower_exposure': 5000,
      'allowed_market_ids': <int>[],
    };
    try {
      await ref.read(apiClientProvider).followTrader(payload);
      ref.invalidate(copyRelationshipsProvider);
      ref.invalidate(copyPortfolioProvider);
      if (mounted) {
        context.go('/copy-trading');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copy failed: $error')),
        );
      }
    }
  }
}
