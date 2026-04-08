import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';
import '../../widgets/trading_view_chart.dart';

class MarketDetailScreen extends ConsumerStatefulWidget {
  const MarketDetailScreen({super.key});

  @override
  ConsumerState<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen> {
  String _timeframe = '15m';

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedMarketProvider);
    final sentimentValue = ref.watch(sentimentFeedProvider);
    final copilotValue = ref.watch(copilotProvider);
    final wallet = ref.watch(walletSessionProvider);

    return AppScaffold(
      title: 'Market Workspace',
      subtitle: 'Market intelligence, evidence, and execution controls in a single desk view.',
      child: selected.when(
        data: (market) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1320;
              if (compact) {
                return ListView(
                  children: [
                    _leftZone(market),
                    const SizedBox(height: AetherSpacing.lg),
                    _centerZone(
                      market,
                      sentimentValue,
                      copilotValue,
                      compact: true,
                    ),
                    const SizedBox(height: AetherSpacing.lg),
                    _rightZone(market, wallet.connected),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 430,
                    child: ListView(
                      children: [_leftZone(market)],
                    ),
                  ),
                  const SizedBox(width: AetherSpacing.lg),
                  Expanded(
                    child: ListView(
                      children: [
                        _centerZone(
                          market,
                          sentimentValue,
                          copilotValue,
                          compact: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AetherSpacing.lg),
                  SizedBox(
                    width: 350,
                    child: ListView(
                      children: [_rightZone(market, wallet.connected)],
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to load market workspace',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Widget _leftZone(Market market) {
    final symbol = _marketSymbol(market.title);

    return Column(
      children: [
        EnterprisePanel(
          title: 'TradingView Price',
          subtitle: '$symbol • ${market.category}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AetherSpacing.sm,
                runSpacing: AetherSpacing.sm,
                children: [
                  for (final tf in const ['1m', '5m', '15m', '1h', '4h', '1D'])
                    ChoiceChip(
                      label: Text(tf),
                      selected: _timeframe == tf,
                      onSelected: (_) => setState(() => _timeframe = tf),
                    ),
                ],
              ),
              const SizedBox(height: AetherSpacing.md),
              TradingViewChart(
                symbol: symbol,
                timeframe: _timeframe,
                height: 260,
                overlayProbability: market.yesProbability,
              ),
            ],
          ),
        ),
        const SizedBox(height: AetherSpacing.lg),
        EnterprisePanel(
          title: 'Probability Drift',
          subtitle: 'Model probability changes over recent snapshots.',
          child: SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _ProbabilityPainter(points: market.points),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: AetherSpacing.lg),
        EnterpriseDataTable<_OrderFlowRow>(
          title: 'Order Flow',
          subtitle: 'Top-of-book pressure and directional skew.',
          rows: _orderFlowRows(market),
          rowId: (row) => row.level,
          searchHint: 'Search order flow',
          columns: [
            EnterpriseTableColumn(
              label: 'Level',
              width: 70,
              cell: (row) => row.level,
              sortValue: (row) => row.level,
            ),
            EnterpriseTableColumn(
              label: 'Bid Notional',
              width: 130,
              numeric: true,
              cell: (row) => formatUsd(row.bid),
              sortValue: (row) => row.bid,
            ),
            EnterpriseTableColumn(
              label: 'Ask Notional',
              width: 130,
              numeric: true,
              cell: (row) => formatUsd(row.ask),
              sortValue: (row) => row.ask,
            ),
            EnterpriseTableColumn(
              label: 'Imbalance',
              width: 90,
              numeric: true,
              cell: (row) => '${row.imbalance.toStringAsFixed(1)}%',
              sortValue: (row) => row.imbalance,
            ),
          ],
        ),
      ],
    );
  }

  Widget _centerZone(
    Market market,
    AsyncValue<SentimentFeed> sentimentValue,
    AsyncValue<CopilotRecommendation> copilotValue,
    {required bool compact},
  ) {
    return Column(
      children: [
        EnterprisePanel(
          title: market.title,
          subtitle: 'Market Thesis',
          trailing: Wrap(
            spacing: AetherSpacing.sm,
            children: [
              StatusBadge(
                label: '${(market.yesProbability * 100).toStringAsFixed(1)}% YES',
              ),
              StatusBadge(
                label:
                    '${(market.aiConfidence * 100).toStringAsFixed(1)}% AI confidence',
              ),
            ],
          ),
          child: Text(
            'This market remains sensitive to macro liquidity and short-term volatility bursts. The desk thesis favors disciplined sizing with risk-off hedges during event-heavy windows.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AetherSpacing.lg),
        if (compact)
          Column(
            children: [
              sentimentValue.when(
                data: (sentiment) => EnterprisePanel(
                  title: 'Signal Context',
                  subtitle: 'Sentiment and source-level signal composition.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(label: 'Trend ${sentiment.trend}'),
                          const SizedBox(width: AetherSpacing.sm),
                          StatusBadge(
                            label: 'Shift ${sentiment.confidenceShift} bps',
                            color: sentiment.confidenceShift >= 0
                                ? AetherColors.success
                                : AetherColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AetherSpacing.md),
                      Text(
                        'Sentiment score ${sentiment.sentimentScore.toStringAsFixed(2)} with ${sentiment.newsItems.length} active source inputs.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AetherSpacing.md),
                      for (final item in sentiment.newsItems.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• ${item.headline} (${item.source})'),
                        ),
                    ],
                  ),
                ),
                loading: () => const EnterprisePanel(
                  title: 'Signal Context',
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => EnterprisePanel(
                  title: 'Signal Context',
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: AetherColors.critical),
                  ),
                ),
              ),
              const SizedBox(height: AetherSpacing.lg),
              copilotValue.when(
                data: (advice) => EnterprisePanel(
                  title: 'AI Insights',
                  subtitle: 'Action recommendation with confidence and risk context.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(label: advice.action),
                          const SizedBox(width: AetherSpacing.sm),
                          StatusBadge(label: '${advice.confidence}% confidence'),
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
                        'Risk posture: ${advice.risk} • Suggested size: ${advice.positionSize}',
                        style: const TextStyle(color: AetherColors.muted),
                      ),
                    ],
                  ),
                ),
                loading: () => const EnterprisePanel(
                  title: 'AI Insights',
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => EnterprisePanel(
                  title: 'AI Insights',
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: AetherColors.critical),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: sentimentValue.when(
                  data: (sentiment) => EnterprisePanel(
                    title: 'Signal Context',
                    subtitle: 'Sentiment and source-level signal composition.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusBadge(label: 'Trend ${sentiment.trend}'),
                            const SizedBox(width: AetherSpacing.sm),
                            StatusBadge(
                              label: 'Shift ${sentiment.confidenceShift} bps',
                              color: sentiment.confidenceShift >= 0
                                  ? AetherColors.success
                                  : AetherColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: AetherSpacing.md),
                        Text(
                          'Sentiment score ${sentiment.sentimentScore.toStringAsFixed(2)} with ${sentiment.newsItems.length} active source inputs.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AetherSpacing.md),
                        for (final item in sentiment.newsItems.take(4))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• ${item.headline} (${item.source})'),
                          ),
                      ],
                    ),
                  ),
                  loading: () => const EnterprisePanel(
                    title: 'Signal Context',
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => EnterprisePanel(
                    title: 'Signal Context',
                    child: Text(
                      error.toString(),
                      style: const TextStyle(color: AetherColors.critical),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AetherSpacing.lg),
              Expanded(
                child: copilotValue.when(
                  data: (advice) => EnterprisePanel(
                    title: 'AI Insights',
                    subtitle: 'Action recommendation with confidence and risk context.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusBadge(label: advice.action),
                            const SizedBox(width: AetherSpacing.sm),
                            StatusBadge(label: '${advice.confidence}% confidence'),
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
                          'Risk posture: ${advice.risk} • Suggested size: ${advice.positionSize}',
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const EnterprisePanel(
                    title: 'AI Insights',
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => EnterprisePanel(
                    title: 'AI Insights',
                    child: Text(
                      error.toString(),
                      style: const TextStyle(color: AetherColors.critical),
                    ),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: AetherSpacing.lg),
        EnterpriseDataTable<_EvidenceRow>(
          title: 'Evidence Ledger',
          subtitle: 'Source credibility and thesis weighting used by the model.',
          rows: _evidenceRows(market),
          rowId: (row) => row.id,
          searchHint: 'Search evidence',
          filters: [
            EnterpriseTableFilter(
              label: 'High Weight',
              predicate: (row) => row.weight >= 0.25,
            ),
            EnterpriseTableFilter(
              label: 'Low Confidence',
              predicate: (row) => row.confidence < 0.75,
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
              label: 'Signal',
              width: 260,
              cell: (row) => row.signal,
              sortValue: (row) => row.signal,
            ),
            EnterpriseTableColumn(
              label: 'Weight',
              width: 80,
              numeric: true,
              cell: (row) => '${(row.weight * 100).toStringAsFixed(0)}%',
              sortValue: (row) => row.weight,
            ),
            EnterpriseTableColumn(
              label: 'Confidence',
              width: 100,
              numeric: true,
              cell: (row) => '${(row.confidence * 100).toStringAsFixed(0)}%',
              sortValue: (row) => row.confidence,
            ),
          ],
          expandedBuilder: (row) => Text(
            'Validation note: ${row.note}',
            style: const TextStyle(color: AetherColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _rightZone(Market market, bool walletConnected) {
    final yesCost = market.yesProbability;
    final noCost = 1 - market.yesProbability;

    return Column(
      children: [
        EnterprisePanel(
          title: 'Execution',
          subtitle: 'Route through the controlled multi-step trade flow.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _priceTile(
                      label: 'YES Price',
                      value: '${(yesCost * 100).toStringAsFixed(1)}c',
                    ),
                  ),
                  const SizedBox(width: AetherSpacing.sm),
                  Expanded(
                    child: _priceTile(
                      label: 'NO Price',
                      value: '${(noCost * 100).toStringAsFixed(1)}c',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.md),
              StatusBadge(
                label: walletConnected
                    ? 'Wallet connected'
                    : 'Wallet required for execution',
                color:
                    walletConnected ? AetherColors.success : AetherColors.warning,
              ),
              const SizedBox(height: AetherSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/trading'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Trade Workflow'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AetherSpacing.lg),
        EnterprisePanel(
          title: 'Risk Panel',
          subtitle: 'Pre-trade controls and desk limits.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _riskLine('Max position notional', '$150,000'),
              _riskLine('Current desk utilization', '64%'),
              _riskLine('Slippage guardrail', '80 bps'),
              _riskLine('Auto-hedge policy', 'Enabled'),
            ],
          ),
        ),
        const SizedBox(height: AetherSpacing.lg),
        EnterprisePanel(
          title: 'Wallet Summary',
          subtitle: 'Settlement context and gas readiness.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Collateral token: USDC'),
              SizedBox(height: 6),
              Text('Estimated gas: 0.0012 ETH'),
              SizedBox(height: 6),
              Text('Settlement chain: HashKey L2'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AetherRadii.md),
        border: Border.all(color: AetherColors.border),
        color: AetherColors.bgPanel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _riskLine(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(key, style: const TextStyle(color: AetherColors.muted))),
          Text(value),
        ],
      ),
    );
  }

  List<_OrderFlowRow> _orderFlowRows(Market market) {
    final base = max(market.liquidity / 20, 10000);
    return [
      for (var i = 1; i <= 6; i++)
        _OrderFlowRow(
          level: 'L$i',
          bid: base - (i * 1400),
          ask: base - (i * 1100),
          imbalance: ((base - (i * 1400)) / (base - (i * 1100))) * 100,
        ),
    ];
  }

  List<_EvidenceRow> _evidenceRows(Market market) {
    return [
      _EvidenceRow(
        id: '${market.id}-a',
        source: 'ETF Flow Desk',
        signal: 'Net inflows remain positive for 5 sessions',
        weight: 0.31,
        confidence: 0.86,
        note: 'Cross-validated with custody settlement records.',
      ),
      _EvidenceRow(
        id: '${market.id}-b',
        source: 'On-chain Monitor',
        signal: 'Active address count rebounded 12% WoW',
        weight: 0.24,
        confidence: 0.79,
        note: 'Signal is seasonally adjusted for holiday periods.',
      ),
      _EvidenceRow(
        id: '${market.id}-c',
        source: 'Volatility Surface',
        signal: 'Front-end skew elevated vs 30-day average',
        weight: 0.19,
        confidence: 0.72,
        note: 'Elevated skew implies wider confidence intervals.',
      ),
      _EvidenceRow(
        id: '${market.id}-d',
        source: 'Macro Feed',
        signal: 'USD liquidity impulse turning neutral',
        weight: 0.14,
        confidence: 0.68,
        note: 'Macro data has a known lag and lower intra-day signal quality.',
      ),
    ];
  }

  String _marketSymbol(String title) {
    final upper = title.toUpperCase();
    if (upper.contains('BTC')) return 'BTC/USD';
    if (upper.contains('ETH')) return 'ETH/USD';
    if (upper.contains('SOL')) return 'SOL/USD';
    if (upper.contains('HASHKEY')) return 'HSK/USD';
    return 'BTC/USD';
  }
}

class _ProbabilityPainter extends CustomPainter {
  const _ProbabilityPainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = AetherColors.bgPanel
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(AetherRadii.md),
      ),
      backgroundPaint,
    );

    if (points.isEmpty) return;
    if (points.length == 1) {
      final y = size.height - (size.height * points.first.clamp(0, 1));
      final dot = Paint()..color = AetherColors.accent;
      canvas.drawCircle(Offset(size.width / 2, y), 3, dot);
      return;
    }

    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (size.width / (points.length - 1)) * i;
      final y = size.height - (size.height * points[i].clamp(0, 1));
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }

    final stroke = Paint()
      ..color = AetherColors.accent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final fillPath = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AetherColors.accent.withValues(alpha: 0.28),
          AetherColors.accent.withValues(alpha: 0.04),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(line, stroke);
  }

  @override
  bool shouldRepaint(covariant _ProbabilityPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _OrderFlowRow {
  const _OrderFlowRow({
    required this.level,
    required this.bid,
    required this.ask,
    required this.imbalance,
  });

  final String level;
  final double bid;
  final double ask;
  final double imbalance;
}

class _EvidenceRow {
  const _EvidenceRow({
    required this.id,
    required this.source,
    required this.signal,
    required this.weight,
    required this.confidence,
    required this.note,
  });

  final String id;
  final String source;
  final String signal;
  final double weight;
  final double confidence;
  final String note;
}
