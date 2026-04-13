import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';
import '../../widgets/market_chart.dart';

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
      title: 'Live Prediction Markets',
      subtitle:
          'Real-time event forecasting across YES/NO outcomes with AI confidence, liquidity, and resolution intelligence.',
      child: marketsValue.when(
        data: (markets) {
          final filtered = _applyLiquidityFilter(markets);
          final totalLiquidity =
              filtered.fold<double>(0, (sum, item) => sum + item.liquidity);
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
                    label: 'Live Event Markets',
                    value: filtered.length.toString(),
                  ),
                  KpiStripItem(
                    label: 'Event Liquidity',
                    value: formatUsd(totalLiquidity),
                  ),
                  KpiStripItem(
                    label: 'Average AI Confidence',
                    value: '${(avgConfidence * 100).toStringAsFixed(1)}%',
                  ),
                  KpiStripItem(
                    label: 'Resolution Ready',
                    value: filtered
                        .where((item) => item.riskScore <= 55)
                        .length
                        .toString(),
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
                      onPressed: () => context.go('/create-prediction'),
                      icon: const Icon(Icons.add_chart_rounded),
                      label: const Text('Create Prediction'),
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
                      'Adjust liquidity filters to inspect the full event forecasting universe.',
                )
              else
                ...filtered.map(
                  (market) => Padding(
                    padding: const EdgeInsets.only(bottom: AetherSpacing.lg),
                    child: _marketCard(market),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to load live prediction markets',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Widget _marketCard(Market market) {
    return EnterprisePanel(
      title: market.title,
      subtitle: '${market.category} • Expires ${_formatExpiry(market.expiry)}',
      trailing: StatusBadge(
        label: 'Risk ${market.riskScore.toStringAsFixed(0)}/100',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 140, child: MarketChart(points: market.points)),
          const SizedBox(height: AetherSpacing.md),
          Wrap(
            spacing: AetherSpacing.sm,
            runSpacing: AetherSpacing.sm,
            children: [
              StatusBadge(
                  label:
                      'YES ${(market.yesProbability * 100).toStringAsFixed(1)}%'),
              StatusBadge(
                  label:
                      'NO ${(market.noProbability * 100).toStringAsFixed(1)}%'),
              StatusBadge(
                  label:
                      'AI confidence ${(market.aiConfidence * 100).toStringAsFixed(1)}%'),
              StatusBadge(
                  label: 'Liquidity pool ${formatUsd(market.liquidity)}'),
              StatusBadge(label: '${market.participantCount} participants'),
            ],
          ),
          const SizedBox(height: AetherSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resolution source: ${market.resolutionSource}',
                  style: const TextStyle(color: AetherColors.muted),
                ),
              ),
              const SizedBox(width: AetherSpacing.sm),
              FilledButton.icon(
                onPressed: () => _openMarket(market),
                icon: const Icon(Icons.psychology_alt_rounded),
                label: const Text('AI Forecast Engine'),
              ),
              const SizedBox(width: AetherSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  _openMarket(market);
                  context.go('/create-prediction');
                },
                icon: const Icon(Icons.show_chart_rounded),
                label: const Text('Open Position'),
              ),
            ],
          ),
        ],
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
        context.go('/ai-forecast-engine');
      }
    }
  }

  List<Market> _applyLiquidityFilter(List<Market> markets) {
    switch (_liquidityBand) {
      case 'Deep Liquidity':
        return markets.where((item) => item.liquidity >= 2000000).toList();
      case 'Mid Liquidity':
        return markets
            .where(
                (item) => item.liquidity >= 600000 && item.liquidity < 2000000)
            .toList();
      case 'Thin Liquidity':
        return markets.where((item) => item.liquidity < 600000).toList();
      default:
        return markets;
    }
  }

  String _formatExpiry(DateTime? expiry) {
    if (expiry == null) return 'Resolution window pending';
    final normalized = expiry.toUtc();
    final month = _monthName(normalized.month);
    return '$month ${normalized.day}, ${normalized.year}';
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(month - 1).clamp(0, 11).toInt()];
  }
}
