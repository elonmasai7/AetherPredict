import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class MarketListScreen extends ConsumerStatefulWidget {
  const MarketListScreen({super.key});

  @override
  ConsumerState<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends ConsumerState<MarketListScreen> {
  String _liquidityBand = 'All';

  @override
  Widget build(BuildContext context) {
    final marketsValue = ref.watch(marketListProvider);

    return AppScaffold(
      title: 'Markets',
      subtitle: 'Market discovery, liquidity inspection, and probability surfacing.',
      child: marketsValue.when(
        data: (markets) {
          final filtered = _applyLiquidityFilter(markets);
          final totalVolume =
              filtered.fold<double>(0, (sum, item) => sum + item.volume);
          final avgConfidence = filtered.isEmpty
              ? 0
              : filtered
                      .map((item) => item.aiConfidence)
                      .reduce((a, b) => a + b) /
                  filtered.length;

          return ListView(
            children: [
              KpiStrip(
                items: [
                  KpiStripItem(
                    label: 'Live Markets',
                    value: filtered.length.toString(),
                  ),
                  KpiStripItem(
                    label: 'Aggregate Volume',
                    value: formatUsd(totalVolume),
                  ),
                  KpiStripItem(
                    label: 'Average AI Confidence',
                    value: '${(avgConfidence * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.lg),
              EnterprisePanel(
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AetherSpacing.sm,
                        runSpacing: AetherSpacing.sm,
                        children: [
                          for (final band in const [
                            'All',
                            'Deep Liquidity',
                            'Mid Liquidity',
                            'Thin Liquidity',
                          ])
                            ChoiceChip(
                              label: Text(band),
                              selected: _liquidityBand == band,
                              onSelected: (_) {
                                setState(() {
                                  _liquidityBand = band;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/trading'),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Open Trading Workflow'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AetherSpacing.lg),
              if (filtered.isEmpty)
                const EmptyStateCard(
                  icon: Icons.query_stats_outlined,
                  title: 'No markets in this liquidity band',
                  message:
                      'Adjust your liquidity filter to inspect the broader market universe.',
                )
              else
                EnterpriseDataTable<Market>(
                  title: 'Market Universe',
                  subtitle:
                      'Sorted market tape with confidence, liquidity, and oracle provenance.',
                  rows: filtered,
                  rowId: (row) => row.id,
                  searchHint: 'Search market title, category, or oracle source',
                  filters: [
                    EnterpriseTableFilter(
                      label: 'High Confidence',
                      predicate: (row) => row.aiConfidence >= 0.75,
                    ),
                    EnterpriseTableFilter(
                      label: 'Volume > $1M',
                      predicate: (row) => row.volume >= 1000000,
                    ),
                    EnterpriseTableFilter(
                      label: 'On-chain Addressed',
                      predicate: (row) =>
                          row.onChainAddress != null && row.onChainAddress!.isNotEmpty,
                    ),
                  ],
                  columns: [
                    EnterpriseTableColumn(
                      label: 'Market',
                      width: 330,
                      cell: (row) => row.title,
                      sortValue: (row) => row.title,
                    ),
                    EnterpriseTableColumn(
                      label: 'Category',
                      width: 120,
                      cell: (row) => row.category,
                      sortValue: (row) => row.category,
                    ),
                    EnterpriseTableColumn(
                      label: 'YES Probability',
                      width: 130,
                      numeric: true,
                      cell: (row) => '${(row.yesProbability * 100).toStringAsFixed(1)}%',
                      sortValue: (row) => row.yesProbability,
                    ),
                    EnterpriseTableColumn(
                      label: 'AI Confidence',
                      width: 120,
                      numeric: true,
                      cell: (row) => '${(row.aiConfidence * 100).toStringAsFixed(1)}%',
                      sortValue: (row) => row.aiConfidence,
                    ),
                    EnterpriseTableColumn(
                      label: 'Volume',
                      width: 120,
                      numeric: true,
                      cell: (row) => formatUsd(row.volume),
                      sortValue: (row) => row.volume,
                    ),
                    EnterpriseTableColumn(
                      label: 'Liquidity',
                      width: 120,
                      numeric: true,
                      cell: (row) => formatUsd(row.liquidity),
                      sortValue: (row) => row.liquidity,
                    ),
                  ],
                  expandedBuilder: (row) {
                    final hasAddress =
                        row.onChainAddress != null && row.onChainAddress!.isNotEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AetherSpacing.sm,
                          runSpacing: AetherSpacing.sm,
                          children: [
                            StatusBadge(
                              label: hasAddress ? 'Tradable' : 'Listing Pending',
                              color: hasAddress
                                  ? AetherColors.success
                                  : AetherColors.warning,
                            ),
                            StatusBadge(label: 'Oracle ${row.oracleSource}'),
                          ],
                        ),
                        const SizedBox(height: AetherSpacing.sm),
                        Text(
                          'On-chain: ${row.onChainAddress ?? 'Address pending deployment'}',
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                      ],
                    );
                  },
                  actionsBuilder: (row) => [
                    IconButton(
                      tooltip: 'Open Market Workspace',
                      onPressed: () => _openMarket(row),
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Trade this Market',
                      onPressed: () {
                        _openMarket(row);
                        context.go('/trading');
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    ),
                  ],
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to load markets',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  void _openMarket(Market market) {
    final markets = ref.read(marketListProvider).valueOrNull;
    if (markets == null || markets.isEmpty) {
      return;
    }
    final index = markets.indexWhere((item) => item.id == market.id);
    if (index >= 0) {
      ref.read(selectedMarketIndexProvider.notifier).state = index;
      if (mounted) {
        context.go('/markets/detail');
      }
    }
  }

  List<Market> _applyLiquidityFilter(List<Market> markets) {
    switch (_liquidityBand) {
      case 'Deep Liquidity':
        return markets.where((item) => item.liquidity >= 2000000).toList();
      case 'Mid Liquidity':
        return markets
            .where((item) => item.liquidity >= 600000 && item.liquidity < 2000000)
            .toList();
      case 'Thin Liquidity':
        return markets.where((item) => item.liquidity < 600000).toList();
      default:
        return markets;
    }
  }
}
