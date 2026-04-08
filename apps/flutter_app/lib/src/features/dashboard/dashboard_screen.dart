import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketsValue = ref.watch(marketListProvider);
    final portfolioValue = ref.watch(portfolioProvider);
    final notificationsValue = ref.watch(notificationsProvider);
    final riskValue = ref.watch(riskProvider);

    return AppScaffold(
      title: 'Overview',
      subtitle: 'Live cross-desk posture, execution flow, and operational risk context.',
      child: portfolioValue.when(
        data: (positions) {
          final activeExposure = positions.fold<double>(
            0,
            (sum, item) => sum + (item.size * item.markPrice),
          );
          final netPnl =
              positions.fold<double>(0, (sum, item) => sum + item.pnl);
          final winners = positions.where((item) => item.pnl > 0).length;

          return marketsValue.when(
            data: (markets) {
              final avgConfidence = markets.isEmpty
                  ? 0.0
                  : markets
                          .map((item) => item.aiConfidence)
                          .reduce((a, b) => a + b) /
                      markets.length;

              return riskValue.when(
                data: (risk) {
                  final kpis = [
                    KpiStripItem(
                      label: 'Net Exposure',
                      value: formatUsd(activeExposure),
                    ),
                    KpiStripItem(
                      label: 'Open Position PnL',
                      value: formatUsd(netPnl),
                      delta: netPnl >= 0 ? 'Up session' : 'Drawdown session',
                      positiveDelta: netPnl >= 0,
                    ),
                    KpiStripItem(
                      label: 'Hit Ratio',
                      value: positions.isEmpty
                          ? '--'
                          : '${((winners / positions.length) * 100).toStringAsFixed(1)}%',
                    ),
                    KpiStripItem(
                      label: 'Portfolio VaR 95',
                      value: formatUsd(risk.var95),
                      delta: 'Risk score ${risk.riskScore}',
                    ),
                    KpiStripItem(
                      label: 'Model Confidence (Avg)',
                      value: '${(avgConfidence * 100).toStringAsFixed(1)}%',
                    ),
                  ];

                  final executionFeed = _buildExecutionFeed(positions);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 1380;
                      return ListView(
                        children: [
                          KpiStrip(items: kpis),
                          const SizedBox(height: AetherSpacing.lg),
                          if (positions.isEmpty)
                            EmptyStateCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'No active positions',
                              message:
                                  'Execution desk has no open risk. Open Markets and place the first trade to initialize the book.',
                              actionLabel: 'Open Markets',
                              onAction: () => context.go('/markets'),
                            )
                          else
                            EnterpriseDataTable<PortfolioPosition>(
                              title: 'Active Positions',
                              subtitle:
                                  'Desk-level positions marked to market and sortable by exposure and performance.',
                              rows: positions,
                              rowId: (row) => '${row.marketId}-${row.side}',
                              searchHint: 'Search market, side, or ticket',
                              filters: [
                                EnterpriseTableFilter(
                                  label: 'YES Side',
                                  predicate: (row) =>
                                      row.side.toUpperCase() == 'YES',
                                ),
                                EnterpriseTableFilter(
                                  label: 'NO Side',
                                  predicate: (row) =>
                                      row.side.toUpperCase() == 'NO',
                                ),
                                EnterpriseTableFilter(
                                  label: 'Positive PnL',
                                  predicate: (row) => row.pnl >= 0,
                                ),
                              ],
                              columns: [
                                EnterpriseTableColumn(
                                  label: 'Market',
                                  width: 260,
                                  cell: (row) => row.marketTitle,
                                  sortValue: (row) => row.marketTitle,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Side',
                                  width: 90,
                                  cell: (row) => row.side,
                                  sortValue: (row) => row.side,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Notional',
                                  numeric: true,
                                  width: 130,
                                  cell: (row) =>
                                      formatUsd(row.size * row.markPrice),
                                  sortValue: (row) => row.size * row.markPrice,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Avg Px',
                                  numeric: true,
                                  width: 90,
                                  cell: (row) => row.avgPrice.toStringAsFixed(3),
                                  sortValue: (row) => row.avgPrice,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Mark Px',
                                  numeric: true,
                                  width: 90,
                                  cell: (row) => row.markPrice.toStringAsFixed(3),
                                  sortValue: (row) => row.markPrice,
                                ),
                                EnterpriseTableColumn(
                                  label: 'PnL',
                                  numeric: true,
                                  width: 120,
                                  cell: (row) => formatUsd(row.pnl),
                                  sortValue: (row) => row.pnl,
                                ),
                              ],
                              expandedBuilder: (row) {
                                final direction = row.side.toUpperCase() == 'YES'
                                    ? 'Directional long in event probability.'
                                    : 'Directional short in event probability.';
                                final riskBucket =
                                    (row.size * row.markPrice) > 25000
                                        ? 'Tier 1'
                                        : (row.size * row.markPrice) > 10000
                                            ? 'Tier 2'
                                            : 'Tier 3';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        StatusBadge(label: 'Risk $riskBucket'),
                                        StatusBadge(
                                          label: row.pnl >= 0
                                              ? 'In-the-money'
                                              : 'Underwater',
                                          color: row.pnl >= 0
                                              ? AetherColors.success
                                              : AetherColors.warning,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      direction,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                );
                              },
                              actionsBuilder: (row) => [
                                IconButton(
                                  tooltip: 'Open market',
                                  onPressed: () {
                                    final index = markets.indexWhere(
                                      (market) =>
                                          int.tryParse(market.id) == row.marketId,
                                    );
                                    if (index >= 0) {
                                      ref
                                          .read(selectedMarketIndexProvider.notifier)
                                          .state = index;
                                      context.go('/markets/detail');
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                ),
                                IconButton(
                                  tooltip: 'Open risk controls',
                                  onPressed: () => context.go('/risk'),
                                  icon: const Icon(Icons.shield_outlined, size: 18),
                                ),
                              ],
                            ),
                          const SizedBox(height: AetherSpacing.lg),
                          if (compact) ...[
                            _alertsPanel(notificationsValue),
                            const SizedBox(height: AetherSpacing.lg),
                            _executionPanel(executionFeed),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _alertsPanel(notificationsValue)),
                                const SizedBox(width: AetherSpacing.lg),
                                Expanded(child: _executionPanel(executionFeed)),
                              ],
                            ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _errorCard(error.toString()),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _errorCard(error.toString()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorCard(error.toString()),
      ),
    );
  }

  Widget _alertsPanel(AsyncValue<List<AppNotification>> notificationsValue) {
    return notificationsValue.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.notifications_off_outlined,
            title: 'No active alerts',
            message:
                'Monitoring is active across markets and portfolios. New risk events will appear here in real time.',
          );
        }

        return EnterpriseDataTable<AppNotification>(
          title: 'Live Alerts Queue',
          subtitle: 'Prioritized by severity for the trading and risk desks.',
          rows: alerts,
          rowId: (row) => '${row.level}-${row.message.hashCode}',
          searchHint: 'Search alerts',
          filters: [
            EnterpriseTableFilter(
              label: 'Critical',
              predicate: (row) => row.level.toLowerCase().contains('critical'),
            ),
            EnterpriseTableFilter(
              label: 'Warning',
              predicate: (row) => row.level.toLowerCase().contains('warning'),
            ),
          ],
          columns: [
            EnterpriseTableColumn(
              label: 'Severity',
              width: 100,
              cell: (row) => row.level.toUpperCase(),
              sortValue: (row) => row.level,
            ),
            EnterpriseTableColumn(
              label: 'Message',
              width: 360,
              cell: (row) => row.message,
              sortValue: (row) => row.message,
            ),
            EnterpriseTableColumn(
              label: 'Desk',
              width: 110,
              cell: (row) => row.level.toLowerCase().contains('critical')
                  ? 'Risk'
                  : 'Trading',
              sortValue: (row) => row.level,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _errorCard(error.toString()),
    );
  }

  Widget _executionPanel(List<_ExecutionRow> rows) {
    if (rows.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.receipt_long_outlined,
        title: 'No recent executions',
        message:
            'Execution feed will populate after the first confirmed trade settlement.',
      );
    }

    return EnterpriseDataTable<_ExecutionRow>(
      title: 'Recent Executions',
      subtitle: 'Settlement outcomes and slippage audit by trade ticket.',
      rows: rows,
      rowId: (row) => row.ticket,
      searchHint: 'Search ticket or market',
      filters: [
        EnterpriseTableFilter(
          label: 'Settled',
          predicate: (row) => row.status == 'Settled',
        ),
        EnterpriseTableFilter(
          label: 'Pending',
          predicate: (row) => row.status == 'Pending',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Ticket',
          width: 100,
          cell: (row) => row.ticket,
          sortValue: (row) => row.ticket,
        ),
        EnterpriseTableColumn(
          label: 'Market',
          width: 190,
          cell: (row) => row.market,
          sortValue: (row) => row.market,
        ),
        EnterpriseTableColumn(
          label: 'Side',
          width: 70,
          cell: (row) => row.side,
          sortValue: (row) => row.side,
        ),
        EnterpriseTableColumn(
          label: 'Notional',
          width: 105,
          numeric: true,
          cell: (row) => formatUsd(row.notional),
          sortValue: (row) => row.notional,
        ),
        EnterpriseTableColumn(
          label: 'Status',
          width: 90,
          cell: (row) => row.status,
          sortValue: (row) => row.status,
        ),
        EnterpriseTableColumn(
          label: 'Latency',
          width: 90,
          numeric: true,
          cell: (row) => '${row.latencyMs} ms',
          sortValue: (row) => row.latencyMs,
        ),
      ],
      expandedBuilder: (row) => Row(
        children: [
          StatusBadge(
            label: row.status,
            color: row.status == 'Settled'
                ? AetherColors.success
                : AetherColors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            'Execution venue ${row.venue} • Slippage ${row.slippageBps} bps • ${row.timestamp}',
            style: const TextStyle(color: AetherColors.muted),
          ),
        ],
      ),
    );
  }

  List<_ExecutionRow> _buildExecutionFeed(List<PortfolioPosition> positions) {
    final now = DateTime.now().toUtc();
    return [
      for (var i = 0; i < min(positions.length, 10); i++)
        _ExecutionRow(
          ticket: 'TRD-${4200 + i}',
          market: positions[i].marketTitle,
          side: positions[i].side,
          notional: positions[i].size * positions[i].markPrice,
          status: i % 4 == 0 ? 'Pending' : 'Settled',
          latencyMs: 740 + (i * 61),
          venue: i.isEven ? 'HashKey L2' : 'Cross-router',
          slippageBps: 4 + (i % 5),
          timestamp: now.subtract(Duration(minutes: i * 9)).toIso8601String(),
        ),
    ];
  }

  Widget _errorCard(String message) {
    return EnterprisePanel(
      title: 'Unable to load overview',
      child: Text(message, style: const TextStyle(color: AetherColors.critical)),
    );
  }
}

class _ExecutionRow {
  const _ExecutionRow({
    required this.ticket,
    required this.market,
    required this.side,
    required this.notional,
    required this.status,
    required this.latencyMs,
    required this.venue,
    required this.slippageBps,
    required this.timestamp,
  });

  final String ticket;
  final String market;
  final String side;
  final double notional;
  final String status;
  final int latencyMs;
  final String venue;
  final int slippageBps;
  final String timestamp;
}
