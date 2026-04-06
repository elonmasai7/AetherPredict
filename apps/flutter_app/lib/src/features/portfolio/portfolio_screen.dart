import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/trading_view_chart.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final risk = ref.watch(riskProvider);
    final hedge = ref.watch(autoHedgeProvider);
    final balances = ref.watch(walletBalancesProvider);

    return AppScaffold(
      title: 'Portfolio',
      child: portfolio.when(
        data: (items) {
          if (items.isEmpty) {
            return const GlassCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'No active positions. Start by exploring live markets.'),
                ),
              ),
            );
          }

          return ListView(
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Portfolio Summary',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(
                      'Net PnL: \$${items.fold<double>(0, (sum, item) => sum + item.pnl).toStringAsFixed(0)}',
                      style: numericStyle(context,
                          size: 30, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Market')),
                        DataColumn(label: Text('Side')),
                        DataColumn(label: Text('Size')),
                        DataColumn(label: Text('Avg')),
                        DataColumn(label: Text('Mark')),
                        DataColumn(label: Text('PnL')),
                      ],
                      rows: [
                        for (final item in items)
                          DataRow(cells: [
                            DataCell(Text(item.marketTitle)),
                            DataCell(Text(item.side)),
                            DataCell(Text(item.size.toStringAsFixed(0))),
                            DataCell(Text(item.avgPrice.toStringAsFixed(2))),
                            DataCell(Text(item.markPrice.toStringAsFixed(2))),
                            DataCell(Text('\$${item.pnl.toStringAsFixed(0)}')),
                          ]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wallet Balances',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    balances.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const Text('No balances detected.',
                              style: TextStyle(color: AetherColors.muted));
                        }
                        final total = items.fold<double>(0, (sum, item) => sum + item.valueUsd);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Wallet Value: \$${total.toStringAsFixed(2)}',
                                style: numericStyle(context,
                                    size: 22, weight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            DataTable(
                              columns: const [
                                DataColumn(label: Text('Token')),
                                DataColumn(label: Text('Balance')),
                                DataColumn(label: Text('Price')),
                                DataColumn(label: Text('Value')),
                              ],
                              rows: [
                                for (final item in items)
                                  DataRow(cells: [
                                    DataCell(Text(item.symbol)),
                                    DataCell(Text(item.balance.toStringAsFixed(4))),
                                    DataCell(Text('\$${item.priceUsd.toStringAsFixed(2)}')),
                                    DataCell(Text('\$${item.valueUsd.toStringAsFixed(2)}')),
                                  ]),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Text(error.toString()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Portfolio Analysis Terminal',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                        'PnL trajectory, allocation behavior, and confidence overlay',
                        style: TextStyle(color: AetherColors.muted)),
                    const SizedBox(height: 12),
                    const TradingViewChart(
                      symbol: 'BTC/USD',
                      timeframe: '1h',
                      height: 280,
                      overlayProbability: 0.78,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 560,
                    child: risk.when(
                      data: (item) => GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Risk Exposure',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                                'Exposure \$${item.totalExposure.toStringAsFixed(0)} • Score ${item.riskScore}'),
                            Text(
                                'VaR95 \$${item.var95.toStringAsFixed(0)} • Max Loss \$${item.maxLoss.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text(error.toString()),
                    ),
                  ),
                  SizedBox(
                    width: 560,
                    child: hedge.when(
                      data: (item) => GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hedge Automation',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                                'Hedge Ratio ${(item.hedgeRatio * 100).toStringAsFixed(0)}% • Protection ${item.protectionScore}'),
                            Text(
                                'Estimated Loss Reduction \$${item.estimatedLossReduction.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text(error.toString()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Historical trade log and statements',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Export CSV')),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Export PDF')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Activity Timeline / Audit Trail',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 10),
                    Text('10:42 — Bought YES on BTC > 120k market'),
                    SizedBox(height: 6),
                    Text('11:10 — AI confidence increased to 81%'),
                    SizedBox(height: 6),
                    Text('12:30 — Whale alert triggered'),
                    SizedBox(height: 6),
                    Text('13:05 — Auto-hedge ratio adjusted to 34%'),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
