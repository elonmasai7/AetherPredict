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
      title: 'Forecast Overview',
      subtitle:
          'Institutional prediction intelligence posture across probabilities, open forecasts, and resolution risk.',
      child: portfolioValue.when(
        data: (positions) {
          final openExposure = positions.fold<double>(
            0,
            (sum, item) => sum + (item.size * item.markPrice),
          );
          final forecastPnl =
              positions.fold<double>(0, (sum, item) => sum + item.pnl);
          final positiveForecasts =
              positions.where((item) => item.pnl > 0).length;

          return marketsValue.when(
            data: (markets) {
              final avgConfidence = markets.isEmpty
                  ? 0.0
                  : markets
                          .map((item) => item.aiConfidence)
                          .reduce((a, b) => a + b) /
                      markets.length;
              final avgRisk = markets.isEmpty
                  ? 0.0
                  : markets
                          .map((item) => item.riskScore)
                          .reduce((a, b) => a + b) /
                      markets.length;

              return riskValue.when(
                data: (risk) {
                  final kpis = [
                    KpiStripItem(
                      label: 'Open Forecast Exposure',
                      value: formatUsd(openExposure),
                    ),
                    KpiStripItem(
                      label: 'Forecast PnL',
                      value: formatUsd(forecastPnl),
                      delta: forecastPnl >= 0
                          ? 'Positive session'
                          : 'Drawdown session',
                      positiveDelta: forecastPnl >= 0,
                    ),
                    KpiStripItem(
                      label: 'Forecast Hit Ratio',
                      value: positions.isEmpty
                          ? '--'
                          : '${((positiveForecasts / positions.length) * 100).toStringAsFixed(1)}%',
                    ),
                    KpiStripItem(
                      label: 'AI Confidence (Avg)',
                      value: '${(avgConfidence * 100).toStringAsFixed(1)}%',
                    ),
                    KpiStripItem(
                      label: 'Market Risk (Avg)',
                      value: avgRisk.toStringAsFixed(1),
                    ),
                    KpiStripItem(
                      label: 'Portfolio VaR 95',
                      value: formatUsd(risk.var95),
                      delta: 'Risk score ${risk.riskScore}',
                    ),
                  ];

                  final settlementFeed = _buildSettlementFeed(positions);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 1380;
                      return ListView(
                        children: [
                          const EnterprisePanel(
                            title: 'Core Product Identity',
                            child: Text(
                              'AetherPredict is an AI-powered on-chain prediction market on HashKey Chain that uses autonomous agents, smart liquidity, and AI-based resolution to deliver secure, real-time forecasting, trading, and risk intelligence for DeFi and financial markets.',
                              style: TextStyle(color: AetherColors.muted),
                            ),
                          ),
                          const SizedBox(height: AetherSpacing.lg),
                          KpiStrip(items: kpis),
                          const SizedBox(height: AetherSpacing.lg),
                          if (positions.isEmpty)
                            EmptyStateCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'No open forecast positions',
                              message:
                                  'Your portfolio is currently flat. Visit Live Prediction Markets to open a forecast position.',
                              actionLabel: 'Open Live Markets',
                              onAction: () =>
                                  context.go('/live-prediction-markets'),
                            )
                          else
                            EnterpriseDataTable<PortfolioPosition>(
                              title: 'My Open Positions',
                              subtitle:
                                  'YES/NO forecast positions marked with probability-aware PnL and exposure metrics.',
                              rows: positions,
                              rowId: (row) => '${row.marketId}-${row.side}',
                              searchHint: 'Search event, side, or market id',
                              filters: [
                                EnterpriseTableFilter(
                                  label: 'YES Positions',
                                  predicate: (row) =>
                                      row.side.toUpperCase() == 'YES',
                                ),
                                EnterpriseTableFilter(
                                  label: 'NO Positions',
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
                                  label: 'Event Market',
                                  width: 300,
                                  cell: (row) => row.marketTitle,
                                  sortValue: (row) => row.marketTitle,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Position',
                                  width: 100,
                                  cell: (row) =>
                                      'Predict ${row.side.toUpperCase()}',
                                  sortValue: (row) => row.side,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Contracts',
                                  numeric: true,
                                  width: 110,
                                  cell: (row) => row.size.toStringAsFixed(0),
                                  sortValue: (row) => row.size,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Open Probability',
                                  numeric: true,
                                  width: 130,
                                  cell: (row) =>
                                      '${(row.avgPrice * 100).toStringAsFixed(1)}%',
                                  sortValue: (row) => row.avgPrice,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Current Probability',
                                  numeric: true,
                                  width: 140,
                                  cell: (row) =>
                                      '${(row.markPrice * 100).toStringAsFixed(1)}%',
                                  sortValue: (row) => row.markPrice,
                                ),
                                EnterpriseTableColumn(
                                  label: 'Forecast PnL',
                                  numeric: true,
                                  width: 130,
                                  cell: (row) => formatUsd(row.pnl),
                                  sortValue: (row) => row.pnl,
                                ),
                              ],
                              expandedBuilder: (row) {
                                final direction = row.side.toUpperCase() ==
                                        'YES'
                                    ? 'Position is aligned with positive event outcome.'
                                    : 'Position is aligned with negative event outcome.';
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
                                              ? 'Forecast in favor'
                                              : 'Forecast against',
                                          color: row.pnl >= 0
                                              ? AetherColors.success
                                              : AetherColors.warning,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      direction,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                );
                              },
                              actionsBuilder: (row) => [
                                IconButton(
                                  tooltip: 'Open AI forecast engine',
                                  onPressed: () {
                                    final index = markets.indexWhere(
                                      (market) =>
                                          int.tryParse(market.id) ==
                                          row.marketId,
                                    );
                                    if (index >= 0) {
                                      ref
                                          .read(selectedMarketIndexProvider
                                              .notifier)
                                          .state = index;
                                      context.go('/ai-forecast-engine');
                                    }
                                  },
                                  icon: const Icon(Icons.psychology_alt_rounded,
                                      size: 18),
                                ),
                                IconButton(
                                  tooltip: 'Open risk intelligence',
                                  onPressed: () =>
                                      context.go('/risk-intelligence'),
                                  icon: const Icon(Icons.shield_outlined,
                                      size: 18),
                                ),
                              ],
                            ),
                          const SizedBox(height: AetherSpacing.lg),
                          if (compact) ...[
                            _alertsPanel(notificationsValue),
                            const SizedBox(height: AetherSpacing.lg),
                            _settlementPanel(settlementFeed),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: _alertsPanel(notificationsValue)),
                                const SizedBox(width: AetherSpacing.lg),
                                Expanded(
                                    child: _settlementPanel(settlementFeed)),
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
            title: 'No active forecast alerts',
            message:
                'Monitoring is active across markets, resolution windows, and risk controls.',
          );
        }

        return EnterpriseDataTable<AppNotification>(
          title: 'Forecast Alert Queue',
          subtitle:
              'Prioritized by severity for forecasting, risk, and resolution desks.',
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
              width: 130,
              cell: (row) => row.level.toLowerCase().contains('critical')
                  ? 'Risk Intelligence'
                  : 'Forecasting',
              sortValue: (row) => row.level,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _errorCard(error.toString()),
    );
  }

  Widget _settlementPanel(List<_SettlementRow> rows) {
    if (rows.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.receipt_long_outlined,
        title: 'No recent settlements',
        message:
            'Settlement feed will populate after new forecast positions move through on-chain confirmation.',
      );
    }

    return EnterpriseDataTable<_SettlementRow>(
      title: 'Recent Position Settlements',
      subtitle:
          'On-chain confirmation outcomes, latency, and slippage audit trail.',
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
          width: 210,
          cell: (row) => row.market,
          sortValue: (row) => row.market,
        ),
        EnterpriseTableColumn(
          label: 'Position',
          width: 95,
          cell: (row) => row.side,
          sortValue: (row) => row.side,
        ),
        EnterpriseTableColumn(
          label: 'Amount',
          width: 115,
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
            'Consensus shift ${row.consensusShift.toStringAsFixed(1)}% • Slippage ${row.slippageBps} bps • ${row.timestamp}',
            style: const TextStyle(color: AetherColors.muted),
          ),
        ],
      ),
    );
  }

  List<_SettlementRow> _buildSettlementFeed(List<PortfolioPosition> positions) {
    final now = DateTime.now().toUtc();
    return [
      for (var i = 0; i < min(positions.length, 10); i++)
        _SettlementRow(
          ticket: 'FC-${4200 + i}',
          market: positions[i].marketTitle,
          side: 'Predict ${positions[i].side.toUpperCase()}',
          notional: positions[i].size * positions[i].markPrice,
          status: i % 4 == 0 ? 'Pending' : 'Settled',
          latencyMs: 740 + (i * 61),
          slippageBps: 4 + (i % 5),
          consensusShift:
              (positions[i].markPrice - positions[i].avgPrice) * 100,
          timestamp: now.subtract(Duration(minutes: i * 9)).toIso8601String(),
        ),
    ];
  }

  Widget _errorCard(String message) {
    return EnterprisePanel(
      title: 'Unable to load forecast overview',
      child:
          Text(message, style: const TextStyle(color: AetherColors.critical)),
    );
  }
}

class _SettlementRow {
  const _SettlementRow({
    required this.ticket,
    required this.market,
    required this.side,
    required this.notional,
    required this.status,
    required this.latencyMs,
    required this.slippageBps,
    required this.consensusShift,
    required this.timestamp,
  });

  final String ticket;
  final String market;
  final String side;
  final double notional;
  final String status;
  final int latencyMs;
  final int slippageBps;
  final double consensusShift;
  final String timestamp;
}
