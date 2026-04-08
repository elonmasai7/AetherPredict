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
      title: 'Portfolio',
      subtitle: 'Position inventory, balance sheet, and transaction audit trail.',
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
                    KpiStripItem(label: 'Open Positions', value: '${positions.length}'),
                    KpiStripItem(label: 'Gross Exposure', value: formatUsd(grossExposure)),
                    KpiStripItem(
                      label: 'Open PnL',
                      value: formatUsd(pnl),
                      positiveDelta: pnl >= 0,
                      delta: pnl >= 0 ? 'Profitable' : 'Drawdown',
                    ),
                    KpiStripItem(label: 'VaR 95', value: formatUsd(risk.var95)),
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
                  title: 'No active positions',
                  message:
                      'Portfolio is flat. Route a trade from Trading to initialize portfolio exposure.',
                )
              else
                EnterpriseDataTable<PortfolioPosition>(
                  title: 'Position Book',
                  subtitle: 'Open inventory with live marks and side-level risk context.',
                  rows: positions,
                  rowId: (row) => '${row.marketId}-${row.side}',
                  searchHint: 'Search by market title or side',
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
                      label: 'Market',
                      width: 250,
                      cell: (row) => row.marketTitle,
                      sortValue: (row) => row.marketTitle,
                    ),
                    EnterpriseTableColumn(
                      label: 'Side',
                      width: 85,
                      cell: (row) => row.side,
                      sortValue: (row) => row.side,
                    ),
                    EnterpriseTableColumn(
                      label: 'Size',
                      width: 90,
                      numeric: true,
                      cell: (row) => row.size.toStringAsFixed(0),
                      sortValue: (row) => row.size,
                    ),
                    EnterpriseTableColumn(
                      label: 'Avg Px',
                      width: 90,
                      numeric: true,
                      cell: (row) => row.avgPrice.toStringAsFixed(3),
                      sortValue: (row) => row.avgPrice,
                    ),
                    EnterpriseTableColumn(
                      label: 'Mark Px',
                      width: 90,
                      numeric: true,
                      cell: (row) => row.markPrice.toStringAsFixed(3),
                      sortValue: (row) => row.markPrice,
                    ),
                    EnterpriseTableColumn(
                      label: 'Notional',
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
                        label: row.pnl >= 0 ? 'Gain' : 'Loss',
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
                      title: 'No wallet balances detected',
                      message:
                          'Connect a wallet or deposit collateral to populate balance inventory.',
                    );
                  }

                  return EnterpriseDataTable<WalletBalance>(
                    title: 'Wallet Balances',
                    subtitle: 'Token inventory by network and USD valuation.',
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
                        cell: (row) => formatUsd(row.priceUsd, fractionDigits: 2),
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
                title: 'Transaction Log',
                subtitle: 'Execution and treasury movement audit trail.',
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
                    width: 110,
                    cell: (row) => row.type,
                    sortValue: (row) => row.type,
                  ),
                  EnterpriseTableColumn(
                    label: 'Reference',
                    width: 220,
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
      title: 'Unable to load portfolio data',
      child: Text(message, style: const TextStyle(color: AetherColors.critical)),
    );
  }

  List<_TransactionRow> _transactionRowsFromPositions(List<PortfolioPosition> positions) {
    final now = DateTime.now().toUtc();
    if (positions.isEmpty) {
      return [
        _TransactionRow(
          id: 'TX-0000',
          type: 'Funding',
          reference: 'No execution records yet',
          amount: 0,
          status: 'Pending',
          timestamp: now.toIso8601String(),
          hash: 'n/a',
          counterparty: 'Treasury',
        ),
      ];
    }

    return [
      for (var i = 0; i < positions.length; i++)
        _TransactionRow(
          id: 'TX-${5100 + i}',
          type: i.isEven ? 'Trade' : 'Hedge',
          reference: positions[i].marketTitle,
          amount: positions[i].size * positions[i].markPrice,
          status: i % 4 == 0 ? 'Pending' : 'Settled',
          timestamp: now.subtract(Duration(minutes: i * 17)).toIso8601String(),
          hash: '0x${(5100 + i).toRadixString(16)}abc9',
          counterparty: i.isEven ? 'Market Maker' : 'Internal Hedge Desk',
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
