import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1220;
                  if (compact) {
                    return Column(
                      children: [
                        _aiConsensusPanel(copilotValue),
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
              _metricTile('Participants', market.participantCount.toString()),
              _metricTile(
                  'Risk Score', '${market.riskScore.toStringAsFixed(0)}/100'),
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
        ],
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
