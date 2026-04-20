import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
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
    final predictFlowMarketsValue = ref.watch(predictFlowMarketsProvider);
    final wallet = ref.watch(walletSessionProvider);

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
                      onPressed: () => context.go('/liquidity-intelligence'),
                      icon: const Icon(Icons.waterfall_chart_rounded),
                      label: const Text('Liquidity Dashboard'),
                    ),
                    const SizedBox(width: AetherSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => context.go('/create-prediction'),
                      icon: const Icon(Icons.add_chart_rounded),
                      label: const Text('Create Prediction'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AetherSpacing.lg),
              _predictFlowCompanionPanel(predictFlowMarketsValue),
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
                    child: _marketCard(
                      market,
                      predictFlowMarketsValue,
                      wallet.address ?? 'demo-wallet',
                    ),
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

  Widget _predictFlowCompanionPanel(
      AsyncValue<List<PredictFlowMarketSnapshot>> predictFlowMarketsValue) {
    return predictFlowMarketsValue.when(
      data: (markets) {
        if (markets.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.hub_outlined,
            title: 'PredictFlow companion is online but empty',
            message:
                'Start placing local engine orders to populate companion market snapshots.',
          );
        }

        return EnterprisePanel(
          title: 'PredictFlow Companion Markets',
          subtitle:
              'Local Dart engine snapshots running alongside the primary forecasting stack for rapid simulation and market-making drills.',
          child: Column(
            children: [
              for (final market in markets.take(3))
                Container(
                  margin: const EdgeInsets.only(bottom: AetherSpacing.sm),
                  padding: const EdgeInsets.all(AetherSpacing.md),
                  decoration: BoxDecoration(
                    color: AetherColors.bgPanel,
                    borderRadius: BorderRadius.circular(AetherRadii.md),
                    border: Border.all(color: AetherColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              market.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${market.category} • YES ${(market.yesPrice * 100).toStringAsFixed(1)}¢ • NO ${(market.noPrice * 100).toStringAsFixed(1)}¢',
                              style:
                                  const TextStyle(color: AetherColors.muted),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: AetherSpacing.sm,
                              runSpacing: AetherSpacing.sm,
                              children: [
                                StatusBadge(
                                    label:
                                        'Local liquidity ${formatUsd(market.liquidityUsd)}'),
                                StatusBadge(
                                    label:
                                        '24h volume ${formatUsd(market.volume24h)}'),
                                StatusBadge(
                                  label: 'PredictFlow ${market.spreadTier}',
                                  color: market.spreadTier == 'HIGH'
                                      ? AetherColors.success
                                      : market.spreadTier == 'MEDIUM'
                                          ? AetherColors.warning
                                          : AetherColors.critical,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AetherSpacing.sm),
                      StatusBadge(
                        label: market.resolved ? 'Resolved' : 'Live',
                        color: market.resolved
                            ? AetherColors.warning
                            : AetherColors.success,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const EnterprisePanel(
        title: 'PredictFlow Companion Markets',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EnterprisePanel(
        title: 'PredictFlow Companion Markets',
        child: Text(
          'Unable to load companion engine snapshots: $error',
          style: const TextStyle(color: AetherColors.critical),
        ),
      ),
    );
  }

  Widget _marketCard(
    Market market,
    AsyncValue<List<PredictFlowMarketSnapshot>> predictFlowMarketsValue,
    String walletAddress,
  ) {
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
              StatusBadge(
                label:
                    'Spread: ${market.liquidityIntelligence.spreadWidthCents}c (${market.liquidityIntelligence.liquidityLabel})',
                color: market.liquidityIntelligence.spreadWidthCents <= 2
                    ? AetherColors.success
                    : market.liquidityIntelligence.spreadWidthCents <= 5
                        ? AetherColors.accent
                        : AetherColors.warning,
              ),
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
          const SizedBox(height: AetherSpacing.sm),
          predictFlowMarketsValue.when(
            data: (companionMarkets) {
              final companion = _selectPredictFlowMarket(market, companionMarkets);
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: companion == null
                      ? null
                      : () async {
                          final apiClient = ref.read(apiClientProvider);
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (_) => _PredictFlowOrderDialog(
                              market: companion,
                              walletAddress: walletAddress,
                              apiClient: apiClient,
                            ),
                          );
                          if (result == true) {
                            ref.invalidate(predictFlowMarketsProvider);
                            ref.invalidate(predictFlowDashboardProvider);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'PredictFlow simulation updated ${companion.title}.',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.hub_outlined),
                  label: Text(
                    companion == null
                        ? 'PredictFlow companion unavailable'
                        : 'Simulate in PredictFlow',
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  PredictFlowMarketSnapshot? _selectPredictFlowMarket(
    Market market,
    List<PredictFlowMarketSnapshot> markets,
  ) {
    if (markets.isEmpty) return null;
    for (final item in markets) {
      if (item.category.toLowerCase() == market.category.toLowerCase()) {
        return item;
      }
    }
    return markets.first;
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

class _PredictFlowOrderDialog extends StatefulWidget {
  const _PredictFlowOrderDialog({
    required this.market,
    required this.walletAddress,
    required this.apiClient,
  });

  final PredictFlowMarketSnapshot market;
  final String walletAddress;
  final ApiClient apiClient;

  @override
  State<_PredictFlowOrderDialog> createState() => _PredictFlowOrderDialogState();
}

class _PredictFlowOrderDialogState extends State<_PredictFlowOrderDialog> {
  String _outcome = 'YES';
  String _side = 'BUY';
  double _shares = 10;
  bool _submitting = false;
  late Future<PredictFlowPreview> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = _loadPreview();
  }

  Future<PredictFlowPreview> _loadPreview() {
    return widget.apiClient.previewPredictFlowOrder(
      marketId: widget.market.id,
      outcome: _outcome,
      side: _side,
      shares: _shares,
    );
  }

  void _refreshPreview() {
    setState(() {
      _previewFuture = _loadPreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AetherColors.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AetherRadii.lg),
        side: const BorderSide(color: AetherColors.border),
      ),
      title: Text('PredictFlow Simulation • ${widget.market.title}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AetherSpacing.sm,
                runSpacing: AetherSpacing.sm,
                children: [
                  StatusBadge(
                      label:
                          'YES ${(widget.market.yesPrice * 100).toStringAsFixed(1)}¢'),
                  StatusBadge(
                      label:
                          'NO ${(widget.market.noPrice * 100).toStringAsFixed(1)}¢'),
                  StatusBadge(
                    label: 'Spread ${widget.market.spreadTier}',
                    color: widget.market.spreadTier == 'HIGH'
                        ? AetherColors.success
                        : widget.market.spreadTier == 'MEDIUM'
                            ? AetherColors.warning
                            : AetherColors.critical,
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.md),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'BUY', label: Text('Buy')),
                  ButtonSegment(value: 'SELL', label: Text('Sell')),
                ],
                selected: {_side},
                onSelectionChanged: (selection) {
                  _side = selection.first;
                  _refreshPreview();
                },
              ),
              const SizedBox(height: AetherSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'YES', label: Text('YES')),
                  ButtonSegment(value: 'NO', label: Text('NO')),
                ],
                selected: {_outcome},
                onSelectionChanged: (selection) {
                  _outcome = selection.first;
                  _refreshPreview();
                },
              ),
              const SizedBox(height: AetherSpacing.md),
              Text('Shares: ${_shares.toStringAsFixed(0)}'),
              Slider(
                min: 1,
                max: 100,
                divisions: 99,
                value: _shares,
                label: _shares.toStringAsFixed(0),
                onChanged: (value) {
                  _shares = value;
                  _refreshPreview();
                },
              ),
              const SizedBox(height: AetherSpacing.md),
              FutureBuilder<PredictFlowPreview>(
                future: _previewFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: AetherColors.critical),
                    );
                  }
                  final preview = snapshot.data;
                  if (preview == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.all(AetherSpacing.md),
                    decoration: BoxDecoration(
                      color: AetherColors.bgPanel,
                      borderRadius: BorderRadius.circular(AetherRadii.md),
                      border: Border.all(color: AetherColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AetherSpacing.sm),
                        Text(
                          _side == 'BUY'
                              ? 'Estimated fill ${preview.sharesOut.toStringAsFixed(2)} shares at ${preview.avgPrice.toStringAsFixed(4)}'
                              : 'Estimated collateral out ${preview.collateralOut.toStringAsFixed(4)} at ${preview.avgPrice.toStringAsFixed(4)}',
                        ),
                        const SizedBox(height: AetherSpacing.xs),
                        Text(
                          'Price impact ${(preview.priceImpact * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _submitting = true);
                  try {
                    await widget.apiClient.placePredictFlowOrder(
                      marketId: widget.market.id,
                      wallet: widget.walletAddress,
                      outcome: _outcome,
                      side: _side,
                      shares: _shares,
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('PredictFlow order failed: $error')),
                    );
                    setState(() => _submitting = false);
                  }
                },
          child: Text(_submitting ? 'Submitting...' : 'Place Simulation Order'),
        ),
      ],
    );
  }
}
