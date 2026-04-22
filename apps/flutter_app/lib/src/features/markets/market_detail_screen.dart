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

class MarketDetailScreen extends ConsumerStatefulWidget {
  const MarketDetailScreen({super.key});

  @override
  ConsumerState<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen> {
  String _timeframe = '24H';

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedMarketProvider);
    final sentimentValue = ref.watch(sentimentFeedProvider);
    final copilotValue = ref.watch(copilotProvider);
    final liquidityValue = ref.watch(selectedMarketLiquidityProvider);
    final predictFlowMarketsValue = ref.watch(predictFlowMarketsProvider);
    final wallet = ref.watch(walletSessionProvider);

    return AppScaffold(
      title: 'AI Forecast Engine',
      subtitle:
          'Autonomous probability intelligence, confidence modeling, and evidence-aware resolution context.',
      child: selected.when(
        data: (market) {
          final points = _timeframePoints(market.points);
          return ListView(
            children: [
              _heroPanel(market),
              const SizedBox(height: AetherSpacing.lg),
              _probabilityTrendPanel(market, points),
              const SizedBox(height: AetherSpacing.lg),
              _liquidityOverviewPanel(market, liquidityValue),
              const SizedBox(height: AetherSpacing.lg),
              _predictFlowCompanionPanel(market, predictFlowMarketsValue),
              const SizedBox(height: AetherSpacing.lg),
              _liquidityDepthPanel(liquidityValue),
              const SizedBox(height: AetherSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1220;
                  if (compact) {
                    return Column(
                      children: [
                        _aiConsensusPanel(copilotValue),
                        const SizedBox(height: AetherSpacing.lg),
                        _liquidityRiskPanel(liquidityValue),
                        const SizedBox(height: AetherSpacing.lg),
                        _resolutionWorkflowPanel(market),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _aiConsensusPanel(copilotValue)),
                      const SizedBox(width: AetherSpacing.lg),
                      Expanded(child: _liquidityRiskPanel(liquidityValue)),
                      const SizedBox(width: AetherSpacing.lg),
                      Expanded(child: _resolutionWorkflowPanel(market)),
                    ],
                  );
                },
              ),
              const SizedBox(height: AetherSpacing.lg),
              _evidenceTimelinePanel(sentimentValue),
              const SizedBox(height: AetherSpacing.lg),
              _actionPanel(market, wallet.connected),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to load AI forecast engine',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Widget _heroPanel(Market market) {
    final spread = market.liquidityIntelligence;
    return EnterprisePanel(
      title: market.title,
      subtitle:
          '${market.category} • Resolution source ${market.resolutionSource}',
      trailing: Wrap(
        spacing: AetherSpacing.sm,
        runSpacing: AetherSpacing.sm,
        children: [
          StatusBadge(
              label:
                  'YES ${(market.yesProbability * 100).toStringAsFixed(1)}%'),
          StatusBadge(
              label: 'NO ${(market.noProbability * 100).toStringAsFixed(1)}%'),
          StatusBadge(
              label:
                  'AI confidence ${(market.aiConfidence * 100).toStringAsFixed(1)}%'),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This event market is monitored by autonomous forecasting agents that continuously update probability, confidence, and resolution readiness.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AetherSpacing.md),
          Wrap(
            spacing: AetherSpacing.sm,
            runSpacing: AetherSpacing.sm,
            children: [
              _metricTile('Resolution Window', _formatExpiry(market.expiry)),
              _metricTile('Event Liquidity', formatUsd(market.liquidity)),
              _metricTile('Spread', '${spread.spreadWidthCents}c • ${spread.liquidityLabel}'),
              _metricTile('Participants', market.participantCount.toString()),
              _metricTile('Liquidity Risk', spread.riskLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _probabilityTrendPanel(Market market, List<double> points) {
    final shiftUp = market.consensusShift >= 0;
    return EnterprisePanel(
      title: 'Probability Trend Graph',
      subtitle:
          'YES probability over time, consensus shift curve, and confidence movement for this event market.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AetherSpacing.sm,
            runSpacing: AetherSpacing.sm,
            children: [
              for (final tf in const ['1H', '24H', '7D', '30D'])
                ChoiceChip(
                  label: Text(tf),
                  selected: _timeframe == tf,
                  onSelected: (_) => setState(() => _timeframe = tf),
                ),
            ],
          ),
          const SizedBox(height: AetherSpacing.md),
          SizedBox(height: 220, child: MarketChart(points: points)),
          const SizedBox(height: AetherSpacing.md),
          Row(
            children: [
              StatusBadge(
                label:
                    'Consensus shift ${shiftUp ? '+' : ''}${market.consensusShift.toStringAsFixed(1)}%',
                color: shiftUp ? AetherColors.success : AetherColors.warning,
              ),
              const SizedBox(width: AetherSpacing.sm),
              StatusBadge(
                label:
                    'Confidence volatility ${(100 - (market.aiConfidence * 100)).toStringAsFixed(1)}%',
              ),
              const SizedBox(width: AetherSpacing.sm),
              StatusBadge(
                  label:
                      'Depth confidence ${_depthConfidence(market).toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiConsensusPanel(AsyncValue<CopilotRecommendation> copilotValue) {
    return copilotValue.when(
      data: (advice) => EnterprisePanel(
        title: 'AI Consensus',
        subtitle:
            'Autonomous synthesis of evidence signals, confidence calibration, and forecast posture guidance.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AetherSpacing.sm,
              runSpacing: AetherSpacing.sm,
              children: [
                StatusBadge(label: advice.action.replaceAll('BUY', 'PREDICT')),
                StatusBadge(label: '${advice.confidence}% confidence'),
                StatusBadge(label: 'Risk ${advice.risk}'),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            Text(advice.reasoning),
            const SizedBox(height: AetherSpacing.md),
            LinearProgressIndicator(
              minHeight: 8,
              value: advice.confidence / 100,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: AetherColors.bgPanel,
            ),
            const SizedBox(height: AetherSpacing.sm),
            Text(
              'Suggested open position size: ${advice.positionSize} • Sentiment trend ${advice.sentimentTrend}',
              style: const TextStyle(color: AetherColors.muted),
            ),
          ],
        ),
      ),
      loading: () => const EnterprisePanel(
        title: 'AI Consensus',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EnterprisePanel(
        title: 'AI Consensus',
        child: Text(
          error.toString(),
          style: const TextStyle(color: AetherColors.critical),
        ),
      ),
    );
  }

  Widget _resolutionWorkflowPanel(Market market) {
    return EnterprisePanel(
      title: 'Resolution Readiness',
      subtitle:
          'AI-based resolution workflow with dispute handling and on-chain settlement sequencing.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _workflowRow(
            step: '1',
            title: 'Market expires',
            description:
                'Resolution window begins at ${_formatExpiry(market.expiry)}.',
          ),
          _workflowRow(
            step: '2',
            title: 'AI evaluates evidence',
            description:
                'Evidence sources are weighted for consensus and ambiguity scoring.',
          ),
          _workflowRow(
            step: '3',
            title: 'Confidence generated',
            description:
                'Model consensus and risk confidence are published to resolution center.',
          ),
          _workflowRow(
            step: '4',
            title: 'On-chain resolution',
            description:
                'Outcome proposal is submitted and cryptographically logged.',
          ),
          _workflowRow(
            step: '5',
            title: 'Dispute window',
            description:
                'Jurors can challenge with additional evidence before finality.',
          ),
          _workflowRow(
            step: '6',
            title: 'Final settlement',
            description:
                'Payouts settle YES/NO positions based on confirmed outcome.',
          ),
        ],
      ),
    );
  }

  Widget _workflowRow({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AetherColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AetherColors.accent),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: AetherSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(color: AetherColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidenceTimelinePanel(AsyncValue<SentimentFeed> sentimentValue) {
    return sentimentValue.when(
      data: (sentiment) {
        final rows = _buildEvidenceRows(sentiment);
        if (rows.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.source_outlined,
            title: 'No evidence inputs available',
            message:
                'Evidence ingestion is still warming up. New source impacts will stream into this timeline automatically.',
          );
        }

        return EnterpriseDataTable<_EvidenceImpactRow>(
          title: 'Evidence Impact Timeline',
          subtitle:
              'Source-by-source impact on consensus shift, confidence movement, and resolution ambiguity.',
          rows: rows,
          rowId: (row) => row.id,
          searchHint: 'Search source or evidence signal',
          filters: [
            EnterpriseTableFilter(
              label: 'High Impact',
              predicate: (row) => row.impactWeight >= 0.2,
            ),
            EnterpriseTableFilter(
              label: 'Confidence Drop',
              predicate: (row) => row.confidenceDelta < 0,
            ),
          ],
          columns: [
            EnterpriseTableColumn(
              label: 'Source',
              width: 180,
              cell: (row) => row.source,
              sortValue: (row) => row.source,
            ),
            EnterpriseTableColumn(
              label: 'Evidence',
              width: 320,
              cell: (row) => row.signal,
              sortValue: (row) => row.signal,
            ),
            EnterpriseTableColumn(
              label: 'Impact',
              width: 90,
              numeric: true,
              cell: (row) => '${(row.impactWeight * 100).toStringAsFixed(0)}%',
              sortValue: (row) => row.impactWeight,
            ),
            EnterpriseTableColumn(
              label: 'Confidence Δ',
              width: 110,
              numeric: true,
              cell: (row) =>
                  '${row.confidenceDelta >= 0 ? '+' : ''}${row.confidenceDelta.toStringAsFixed(1)}%',
              sortValue: (row) => row.confidenceDelta,
            ),
            EnterpriseTableColumn(
              label: 'Resolution Relevance',
              width: 170,
              cell: (row) => row.resolutionRelevance,
              sortValue: (row) => row.resolutionRelevance,
            ),
          ],
        );
      },
      loading: () => const EnterprisePanel(
        title: 'Evidence Impact Timeline',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EnterprisePanel(
        title: 'Evidence Impact Timeline',
        child: Text(
          error.toString(),
          style: const TextStyle(color: AetherColors.critical),
        ),
      ),
    );
  }

  Widget _actionPanel(Market market, bool walletConnected) {
    final spread = market.liquidityIntelligence;
    final predictFlowMarketsValue = ref.watch(predictFlowMarketsProvider);
    return EnterprisePanel(
      title: 'Forecast Actions',
      subtitle:
          'Open or close YES/NO forecast positions, review risk intelligence, and route to resolution workflows.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(
            label: walletConnected
                ? 'Wallet ready for on-chain settlement'
                : 'Connect wallet to open positions',
            color:
                walletConnected ? AetherColors.success : AetherColors.warning,
          ),
          const SizedBox(height: AetherSpacing.md),
          Wrap(
            spacing: AetherSpacing.sm,
            runSpacing: AetherSpacing.sm,
            children: [
              StatusBadge(
                label:
                    'Best YES bid ${_cents(spread.bestYesBid)} • ask ${_cents(spread.bestYesAsk)}',
              ),
              StatusBadge(
                label:
                    'Implied NO ${_cents(spread.impliedNoBid)} / ${_cents(spread.impliedNoAsk)}',
              ),
              StatusBadge(
                label: 'Spread: ${spread.spreadWidthCents}c (${spread.liquidityLabel})',
                color: spread.spreadWidthCents <= 2
                    ? AetherColors.success
                    : spread.spreadWidthCents <= 5
                        ? AetherColors.accent
                        : AetherColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AetherSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/create-prediction'),
                  icon: const Icon(Icons.trending_up_rounded),
                  label: Text(
                      'Predict YES ${(market.yesProbability * 100).toStringAsFixed(0)}%'),
                ),
              ),
              const SizedBox(width: AetherSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/create-prediction'),
                  icon: const Icon(Icons.trending_down_rounded),
                  label: Text(
                      'Predict NO ${(market.noProbability * 100).toStringAsFixed(0)}%'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AetherSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/risk-intelligence'),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Risk Intelligence'),
                ),
              ),
              const SizedBox(width: AetherSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/market-resolution'),
                  icon: const Icon(Icons.gavel_rounded),
                  label: const Text('Resolution Center'),
                ),
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
                          final wallet = ref.read(walletSessionProvider);
                          if ((wallet.address ?? '').isEmpty) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect a wallet to run PredictFlow orders.'),
                              ),
                            );
                            return;
                          }
                          final apiClient = ref.read(apiClientProvider);
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (_) => _PredictFlowOrderDialog(
                              market: companion,
                              walletAddress: wallet.address!,
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

  Widget _liquidityOverviewPanel(
      Market market, AsyncValue<LiquidityDetail> liquidityValue) {
    return liquidityValue.when(
      data: (detail) {
        final concentration = detail.concentration;
        final shock = detail.informationShock;
        final eventDriven = detail.eventDriven;
        final expiry = detail.expiryDecay;
        return EnterprisePanel(
          title: 'Liquidity Intelligence Overview',
          subtitle:
              'Probability-based spreads, event support, concentration risk, and execution conditions for this binary market.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AetherSpacing.sm,
                runSpacing: AetherSpacing.sm,
                children: [
                  StatusBadge(
                      label:
                          'Spread: ${detail.spread.spreadWidthCents}c (${detail.spread.liquidityLabel})'),
                  StatusBadge(
                      label:
                          'Liquidity score ${detail.liquidityScore.toStringAsFixed(1)}'),
                  StatusBadge(
                    label: shock['status']?.toString() ?? 'Stable',
                    color: (shock['status']?.toString() == 'Shock Active')
                        ? AetherColors.warning
                        : AetherColors.success,
                  ),
                  StatusBadge(
                      label: eventDriven['profile']?.toString() ??
                          'Standard'),
                ],
              ),
              const SizedBox(height: AetherSpacing.md),
              Wrap(
                spacing: AetherSpacing.sm,
                runSpacing: AetherSpacing.sm,
                children: [
                  _metricTile('Best YES Bid', _cents(detail.spread.bestYesBid)),
                  _metricTile('Best YES Ask', _cents(detail.spread.bestYesAsk)),
                  _metricTile(
                      'Implied NO',
                      '${_cents(detail.spread.impliedNoBid)} / ${_cents(detail.spread.impliedNoAsk)}'),
                  _metricTile(
                    'LP Concentration',
                    '${((concentration['top_providers_share_pct'] as num?) ?? 0).toStringAsFixed(1)}%',
                  ),
                ],
              ),
              if ((expiry['warning'] as String?) != null) ...[
                const SizedBox(height: AetherSpacing.md),
                Text(
                  expiry['warning'] as String,
                  style: const TextStyle(
                    color: AetherColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const EnterprisePanel(
        title: 'Liquidity Intelligence Overview',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EnterprisePanel(
        title: 'Liquidity Intelligence Overview',
        child: Text(error.toString(),
            style: const TextStyle(color: AetherColors.critical)),
      ),
    );
  }

  Widget _liquidityDepthPanel(AsyncValue<LiquidityDetail> liquidityValue) {
    return liquidityValue.when(
      data: (detail) {
        final depth = detail.depth;
        final distribution =
            (depth['order_distribution'] as List<dynamic>? ?? const []);
        return EnterprisePanel(
          title: 'Probability Depth',
          subtitle:
              'Prediction-market depth ladder across probabilities, YES/NO pool imbalance, and cumulative liquidity.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AetherSpacing.sm,
                runSpacing: AetherSpacing.sm,
                children: [
                  _metricTile('YES Depth',
                      formatUsd((depth['yes_depth_total'] as num?)?.toDouble() ?? 0)),
                  _metricTile('NO Depth',
                      formatUsd((depth['no_depth_total'] as num?)?.toDouble() ?? 0)),
                  _metricTile(
                      'Imbalance Ratio',
                      ((depth['imbalance_ratio'] as num?) ?? 0)
                          .toStringAsFixed(2)),
                  _metricTile(
                      'Depth Score',
                      ((depth['depth_score'] as num?) ?? 0).toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: AetherSpacing.md),
              ...distribution.take(8).map((row) {
                final map = Map<String, dynamic>.from(row as Map);
                final yesDepth = (map['yes_depth'] as num?)?.toDouble() ?? 0;
                final noDepth = (map['no_depth'] as num?)?.toDouble() ?? 0;
                final maxDepth = yesDepth > noDepth ? yesDepth : noDepth;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AetherSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'P ${(map['probability'] as num?)?.toStringAsFixed(2) ?? '0.00'} • YES ${yesDepth.toStringAsFixed(0)} • NO ${noDepth.toStringAsFixed(0)}',
                        style: const TextStyle(color: AetherColors.muted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: maxDepth == 0 ? 0 : yesDepth / maxDepth,
                              minHeight: 8,
                              color: AetherColors.success,
                              backgroundColor: AetherColors.bgPanel,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: AetherSpacing.sm),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: maxDepth == 0 ? 0 : noDepth / maxDepth,
                              minHeight: 8,
                              color: AetherColors.critical,
                              backgroundColor: AetherColors.bgPanel,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const EnterprisePanel(
        title: 'Probability Depth',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EnterprisePanel(
        title: 'Probability Depth',
        child: Text(error.toString(),
            style: const TextStyle(color: AetherColors.critical)),
      ),
    );
  }

  Widget _predictFlowCompanionPanel(
    Market market,
    AsyncValue<List<PredictFlowMarketSnapshot>> predictFlowMarketsValue,
  ) {
    return predictFlowMarketsValue.when(
      data: (markets) {
        if (markets.isEmpty) {
          return const SizedBox.shrink();
        }
        final companion = markets.firstWhere(
          (item) =>
              item.category.toLowerCase() == market.category.toLowerCase(),
          orElse: () => markets.first,
        );
        final yesDelta = ((market.yesProbability - companion.yesPrice) * 100);
        return EnterprisePanel(
          title: 'PredictFlow Companion Read',
          subtitle:
              'Local Dart engine snapshot for comparison against the primary live prediction stack.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AetherSpacing.sm,
                runSpacing: AetherSpacing.sm,
                children: [
                  StatusBadge(label: companion.title),
                  StatusBadge(
                    label:
                        'PredictFlow YES ${(companion.yesPrice * 100).toStringAsFixed(1)}¢',
                  ),
                  StatusBadge(
                    label:
                        'Δ ${yesDelta >= 0 ? '+' : ''}${yesDelta.toStringAsFixed(1)}¢ vs primary',
                    color: yesDelta.abs() <= 4
                        ? AetherColors.success
                        : AetherColors.warning,
                  ),
                  StatusBadge(
                    label: 'Spread tier ${companion.spreadTier}',
                    color: companion.spreadTier == 'HIGH'
                        ? AetherColors.success
                        : companion.spreadTier == 'MEDIUM'
                            ? AetherColors.warning
                            : AetherColors.critical,
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.md),
              Wrap(
                spacing: AetherSpacing.sm,
                runSpacing: AetherSpacing.sm,
                children: [
                  _metricTile('Companion Liquidity',
                      formatUsd(companion.liquidityUsd)),
                  _metricTile('Companion 24h Volume',
                      formatUsd(companion.volume24h)),
                  _metricTile(
                      'Resolution Source', companion.resolutionSource),
                  _metricTile(
                      'State', companion.resolved ? 'Resolved' : 'Live'),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const EnterprisePanel(
        title: 'PredictFlow Companion Read',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EnterprisePanel(
        title: 'PredictFlow Companion Read',
        child: Text(
          'Unable to load PredictFlow companion market: $error',
          style: const TextStyle(color: AetherColors.critical),
        ),
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

  Widget _liquidityRiskPanel(AsyncValue<LiquidityDetail> liquidityValue) {
    return liquidityValue.when(
      data: (detail) {
        final risk = detail.risk;
        final concentration = detail.concentration;
        final retail = detail.retail;
        final marketMaker = detail.marketMaker;
        final shock = detail.informationShock;
        return EnterprisePanel(
          title: 'Liquidity Risk & Execution',
          subtitle:
              'Unified risk score, micro-position routing, concentration diagnostics, and AI market maker behavior.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AetherSpacing.sm,
                runSpacing: AetherSpacing.sm,
                children: [
                  StatusBadge(label: risk['label']?.toString() ?? 'Medium Risk'),
                  StatusBadge(
                      label:
                          concentration['summary']?.toString() ?? 'LP distribution unavailable'),
                  StatusBadge(
                      label:
                          'Retail slippage ${(((retail['micro_trade_preview'] as Map?)?['slippage_pct'] as num?) ?? 0).toStringAsFixed(2)}%'),
                ],
              ),
              const SizedBox(height: AetherSpacing.md),
              Text(
                shock['action']?.toString() ??
                    'AI market maker monitoring event liquidity.',
                style: const TextStyle(color: AetherColors.muted),
              ),
              const SizedBox(height: AetherSpacing.md),
              _workflowRow(
                step: 'MM',
                title: marketMaker['mode']?.toString() ?? 'AI Market Maker',
                description:
                    'Target spread ${marketMaker['target_spread_cents'] ?? '--'}c • inventory bias ${marketMaker['inventory_bias'] ?? 'Balanced'}',
              ),
              _workflowRow(
                step: 'LP',
                title: 'Liquidity concentration',
                description:
                    'Top LP share ${((concentration['top_providers_share_pct'] as num?) ?? 0).toStringAsFixed(1)}% • decentralization ${(concentration['decentralization_index'] as num?)?.toStringAsFixed(1) ?? '--'}',
              ),
              _workflowRow(
                step: 'RT',
                title: 'Retail participation model',
                description:
                    'Micro-position ticket ${(retail['micro_trade_preview'] as Map?)?['ticket_size_usd'] ?? 0} USD with minimal slippage routing.',
              ),
            ],
          ),
        );
      },
      loading: () => const EnterprisePanel(
        title: 'Liquidity Risk & Execution',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EnterprisePanel(
        title: 'Liquidity Risk & Execution',
        child: Text(error.toString(),
            style: const TextStyle(color: AetherColors.critical)),
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(AetherRadii.md),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AetherColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  List<double> _timeframePoints(List<double> base) {
    if (base.isEmpty) {
      return const [0.42, 0.47, 0.51, 0.56, 0.61, 0.58];
    }

    final seed = [...base];
    final anchor = seed.last;
    return switch (_timeframe) {
      '1H' => [
          (anchor - 0.04).clamp(0, 1).toDouble(),
          (anchor - 0.03).clamp(0, 1).toDouble(),
          (anchor - 0.02).clamp(0, 1).toDouble(),
          (anchor - 0.01).clamp(0, 1).toDouble(),
          anchor,
        ],
      '7D' => [
          (anchor - 0.12).clamp(0, 1).toDouble(),
          (anchor - 0.08).clamp(0, 1).toDouble(),
          (anchor - 0.04).clamp(0, 1).toDouble(),
          (anchor - 0.02).clamp(0, 1).toDouble(),
          anchor,
          (anchor + 0.01).clamp(0, 1).toDouble(),
        ],
      '30D' => [
          (anchor - 0.18).clamp(0, 1).toDouble(),
          (anchor - 0.14).clamp(0, 1).toDouble(),
          (anchor - 0.09).clamp(0, 1).toDouble(),
          (anchor - 0.05).clamp(0, 1).toDouble(),
          (anchor - 0.02).clamp(0, 1).toDouble(),
          anchor,
        ],
      _ => [
          (anchor - 0.08).clamp(0, 1).toDouble(),
          (anchor - 0.06).clamp(0, 1).toDouble(),
          (anchor - 0.03).clamp(0, 1).toDouble(),
          (anchor - 0.01).clamp(0, 1).toDouble(),
          anchor,
        ],
    };
  }

  List<_EvidenceImpactRow> _buildEvidenceRows(SentimentFeed sentiment) {
    if (sentiment.newsItems.isEmpty) return const [];

    return [
      for (var i = 0; i < sentiment.newsItems.length; i++)
        _EvidenceImpactRow(
          id: 'evidence-$i',
          source: sentiment.newsItems[i].source,
          signal: sentiment.newsItems[i].headline,
          impactWeight: (0.3 - (i * 0.04)).clamp(0.07, 0.3).toDouble(),
          confidenceDelta: sentiment.confidenceShift >= 0
              ? (2.1 - (i * 0.5)).clamp(0.2, 2.1).toDouble()
              : (-2.1 + (i * 0.4)).clamp(-2.1, -0.2).toDouble(),
          resolutionRelevance:
              i.isEven ? 'Direct outcome signal' : 'Contextual validation',
        ),
    ];
  }

  String _formatExpiry(DateTime? expiry) {
    if (expiry == null) return 'Pending publication';
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

  double _depthConfidence(Market market) {
    final liquidityFactor = (market.liquidity / 2000000).clamp(0.2, 1.2);
    final participantFactor = (market.participantCount / 300).clamp(0.2, 1.2);
    return ((liquidityFactor + participantFactor + market.aiConfidence) / 3) *
        100;
  }

  String _cents(double probability) =>
      '${(probability * 100).toStringAsFixed(0)}c';
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

class _EvidenceImpactRow {
  const _EvidenceImpactRow({
    required this.id,
    required this.source,
    required this.signal,
    required this.impactWeight,
    required this.confidenceDelta,
    required this.resolutionRelevance,
  });

  final String id;
  final String source;
  final String signal;
  final double impactWeight;
  final double confidenceDelta;
  final String resolutionRelevance;
}
