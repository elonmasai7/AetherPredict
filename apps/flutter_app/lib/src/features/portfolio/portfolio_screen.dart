import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionsValue = ref.watch(portfolioProvider);
    final balancesValue = ref.watch(walletBalancesProvider);
    final riskValue = ref.watch(riskProvider);

    return AppScaffold(
      title: 'My Positions',
      subtitle:
          'Open forecast positions, settlement balances, and on-chain transaction intelligence.',
      child: positionsValue.when(
        data: (positions) {
          final grossExposure = positions.fold<double>(
            0,
            (sum, row) => sum + (row.size * row.markPrice),
          );
          final pnl = positions.fold<double>(0, (sum, row) => sum + row.pnl);

          return ListView(
            children: [
              riskValue.when(
                data: (risk) => KpiStrip(
                  items: [
                    KpiStripItem(
                        label: 'Open Positions', value: '${positions.length}'),
                    KpiStripItem(
                        label: 'Event Exposure',
                        value: formatUsd(grossExposure)),
                    KpiStripItem(
                      label: 'Forecast PnL',
                      value: formatUsd(pnl),
                      positiveDelta: pnl >= 0,
                      delta: pnl >= 0 ? 'Positive' : 'Drawdown',
                    ),
                    KpiStripItem(
                        label: 'Dispute Risk',
                        value: '${(risk.var95 / 1000).toStringAsFixed(1)}%'),
                    KpiStripItem(label: 'Risk Score', value: risk.riskScore),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _errorPanel(error.toString()),
              ),
              const SizedBox(height: AetherSpacing.lg),
              if (positions.isEmpty)
                const EmptyStateCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No active forecast positions',
                  message:
                      'Open a YES/NO forecast from Live Prediction Markets to initialize your position book.',
                )
              else
                EnterpriseDataTable<PortfolioPosition>(
                  title: 'Position Book',
                  subtitle:
                      'YES/NO inventory with live probability marks and forecast performance.',
                  rows: positions,
                  rowId: (row) => '${row.marketId}-${row.side}',
                  searchHint: 'Search by event title or side',
                  filters: [
                    EnterpriseTableFilter(
                      label: 'YES Side',
                      predicate: (row) => row.side.toUpperCase() == 'YES',
                    ),
                    EnterpriseTableFilter(
                      label: 'NO Side',
                      predicate: (row) => row.side.toUpperCase() == 'NO',
                    ),
                    EnterpriseTableFilter(
                      label: 'Loss-making',
                      predicate: (row) => row.pnl < 0,
                    ),
                  ],
                  columns: [
                    EnterpriseTableColumn(
                      label: 'Event Market',
                      width: 280,
                      cell: (row) => row.marketTitle,
                      sortValue: (row) => row.marketTitle,
                    ),
                    EnterpriseTableColumn(
                      label: 'Position',
                      width: 120,
                      cell: (row) => 'Predict ${row.side.toUpperCase()}',
                      sortValue: (row) => row.side,
                    ),
                    EnterpriseTableColumn(
                      label: 'Contracts',
                      width: 100,
                      numeric: true,
                      cell: (row) => row.size.toStringAsFixed(0),
                      sortValue: (row) => row.size,
                    ),
                    EnterpriseTableColumn(
                      label: 'Open Prob.',
                      width: 100,
                      numeric: true,
                      cell: (row) =>
                          '${(row.avgPrice * 100).toStringAsFixed(1)}%',
                      sortValue: (row) => row.avgPrice,
                    ),
                    EnterpriseTableColumn(
                      label: 'Current Prob.',
                      width: 110,
                      numeric: true,
                      cell: (row) =>
                          '${(row.markPrice * 100).toStringAsFixed(1)}%',
                      sortValue: (row) => row.markPrice,
                    ),
                    EnterpriseTableColumn(
                      label: 'Exposure',
                      width: 120,
                      numeric: true,
                      cell: (row) => formatUsd(row.size * row.markPrice),
                      sortValue: (row) => row.size * row.markPrice,
                    ),
                    EnterpriseTableColumn(
                      label: 'PnL',
                      width: 110,
                      numeric: true,
                      cell: (row) => formatUsd(row.pnl),
                      sortValue: (row) => row.pnl,
                    ),
                  ],
                  expandedBuilder: (row) => Row(
                    children: [
                      StatusBadge(
                        label: row.pnl >= 0
                            ? 'Forecast in favor'
                            : 'Forecast against',
                        color: row.pnl >= 0
                            ? AetherColors.success
                            : AetherColors.warning,
                      ),
                      const SizedBox(width: AetherSpacing.sm),
                      Text(
                        'Market ID ${row.marketId} • Exposure ${formatUsd(row.size * row.markPrice)}',
                        style: const TextStyle(color: AetherColors.muted),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AetherSpacing.lg),
              balancesValue.when(
                data: (balances) {
                  if (balances.isEmpty) {
                    return const EmptyStateCard(
                      icon: Icons.wallet_outlined,
                      title: 'No settlement balances detected',
                      message:
                          'Connect a wallet or deposit collateral to populate settlement inventory.',
                    );
                  }

                  return EnterpriseDataTable<WalletBalance>(
                    title: 'Settlement Balances',
                    subtitle: 'Token inventory by network with USD valuation.',
                    rows: balances,
                    rowId: (row) => '${row.symbol}-${row.network}',
                    searchHint: 'Search token or network',
                    columns: [
                      EnterpriseTableColumn(
                        label: 'Token',
                        width: 90,
                        cell: (row) => row.symbol,
                        sortValue: (row) => row.symbol,
                      ),
                      EnterpriseTableColumn(
                        label: 'Network',
                        width: 120,
                        cell: (row) => row.network,
                        sortValue: (row) => row.network,
                      ),
                      EnterpriseTableColumn(
                        label: 'Balance',
                        width: 120,
                        numeric: true,
                        cell: (row) => row.balance.toStringAsFixed(4),
                        sortValue: (row) => row.balance,
                      ),
                      EnterpriseTableColumn(
                        label: 'Price',
                        width: 100,
                        numeric: true,
                        cell: (row) =>
                            formatUsd(row.priceUsd, fractionDigits: 2),
                        sortValue: (row) => row.priceUsd,
                      ),
                      EnterpriseTableColumn(
                        label: 'Value',
                        width: 120,
                        numeric: true,
                        cell: (row) => formatUsd(row.valueUsd),
                        sortValue: (row) => row.valueUsd,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _errorPanel(error.toString()),
              ),
              const SizedBox(height: AetherSpacing.lg),
              EnterpriseDataTable<_TransactionRow>(
                title: 'On-chain Forecast Transactions',
                subtitle:
                    'Position lifecycle and settlement movement audit trail.',
                rows: _transactionRowsFromPositions(positions),
                rowId: (row) => row.id,
                searchHint: 'Search transaction id or type',
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
                    label: 'Tx ID',
                    width: 140,
                    cell: (row) => row.id,
                    sortValue: (row) => row.id,
                  ),
                  EnterpriseTableColumn(
                    label: 'Type',
                    width: 160,
                    cell: (row) => row.type,
                    sortValue: (row) => row.type,
                  ),
                  EnterpriseTableColumn(
                    label: 'Reference',
                    width: 230,
                    cell: (row) => row.reference,
                    sortValue: (row) => row.reference,
                  ),
                  EnterpriseTableColumn(
                    label: 'Amount',
                    width: 110,
                    numeric: true,
                    cell: (row) => formatUsd(row.amount),
                    sortValue: (row) => row.amount,
                  ),
                  EnterpriseTableColumn(
                    label: 'Status',
                    width: 100,
                    cell: (row) => row.status,
                    sortValue: (row) => row.status,
                  ),
                  EnterpriseTableColumn(
                    label: 'Timestamp',
                    width: 180,
                    cell: (row) => row.timestamp,
                    sortValue: (row) => row.timestamp,
                  ),
                ],
                expandedBuilder: (row) => Text(
                  'Hash: ${row.hash} • Counterparty: ${row.counterparty}',
                  style: const TextStyle(color: AetherColors.muted),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorPanel(error.toString()),
      ),
    );
  }

  Widget _errorPanel(String message) {
    return EnterprisePanel(
      title: 'Unable to load position data',
      child:
          Text(message, style: const TextStyle(color: AetherColors.critical)),
    );
  }

  List<_TransactionRow> _transactionRowsFromPositions(
      List<PortfolioPosition> positions) {
    final now = DateTime.now().toUtc();
    if (positions.isEmpty) {
      return [
        _TransactionRow(
          id: 'TX-0000',
          type: 'Collateral Funding',
          reference: 'No forecast executions yet',
          amount: 0,
          status: 'Pending',
          timestamp: now.toIso8601String(),
          hash: 'n/a',
          counterparty: 'Protocol Treasury',
        ),
      ];
    }

    return [
      for (var i = 0; i < positions.length; i++)
        _TransactionRow(
          id: 'TX-${5100 + i}',
          type: i.isEven ? 'Open Position' : 'Close Forecast',
          reference: positions[i].marketTitle,
          amount: positions[i].size * positions[i].markPrice,
          status: i % 4 == 0 ? 'Pending' : 'Settled',
          timestamp: now.subtract(Duration(minutes: i * 17)).toIso8601String(),
          hash: '0x${(5100 + i).toRadixString(16)}abc9',
          counterparty:
              i.isEven ? 'Event Liquidity Pool' : 'Settlement Contract',
        ),
    ];
  }
}

class _TransactionRow {
  const _TransactionRow({
    required this.id,
    required this.type,
    required this.reference,
    required this.amount,
    required this.status,
    required this.timestamp,
    required this.hash,
    required this.counterparty,
  });

  final String id;
  final String type;
  final String reference;
  final double amount;
  final String status;
  final String timestamp;
  final String hash;
  final String counterparty;
}
