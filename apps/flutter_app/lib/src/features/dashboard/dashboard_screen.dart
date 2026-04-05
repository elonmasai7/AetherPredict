import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/trading_view_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketsValue = ref.watch(marketListProvider);
    final portfolioValue = ref.watch(portfolioProvider);
    final riskValue = ref.watch(riskProvider);
    final exposureValue = ref.watch(exposureProvider);
    final agentsValue = ref.watch(agentListProvider);
    final alertsValue = ref.watch(notificationsProvider);
    final sentimentValue = ref.watch(sentimentFeedProvider);
    final liveUpdate = ref.watch(marketUpdatesProvider);

    return AppScaffold(
      title: 'Dashboard',
      child: marketsValue.when(
        data: (markets) => portfolioValue.when(
          data: (positions) {
            final totalValue = positions.fold<double>(
                0, (sum, p) => sum + p.size * p.markPrice);
            final dailyPnl = positions.fold<double>(0, (sum, p) => sum + p.pnl);
            final confidenceIndex = markets.isEmpty
                ? 0.0
                : markets.map((m) => m.aiConfidence).reduce((a, b) => a + b) /
                    markets.length;
            final featuredMarket = markets.isEmpty ? null : markets.first;

            return ListView(
              children: [
                _topCards(
                  context,
                  totalValue: totalValue,
                  activePositions: positions.length,
                  dailyPnl: dailyPnl,
                  confidenceIndex: confidenceIndex,
                  riskValue: riskValue,
                ),
                const SizedBox(height: 16),
                if (featuredMarket != null) ...[
                  _featuredMarketPanel(featuredMarket),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: 760, child: _pnlChartCard(positions)),
                    SizedBox(
                        width: 360, child: _aiSignalsCard(liveUpdate, markets)),
                    SizedBox(width: 560, child: _marketVolumeCard(markets)),
                    SizedBox(width: 560, child: _confidenceTrendCard(markets)),
                    SizedBox(
                        width: 360, child: _riskExposureCard(exposureValue)),
                    SizedBox(width: 360, child: _alertsCard(alertsValue)),
                    SizedBox(
                        width: 560, child: _agentActivityCard(agentsValue)),
                    SizedBox(
                        width: 560, child: _recentTransactionsCard(positions)),
                    SizedBox(
                        width: 360, child: _sentimentFeedCard(sentimentValue)),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Widget _topCards(
    BuildContext context, {
    required double totalValue,
    required int activePositions,
    required double dailyPnl,
    required double confidenceIndex,
    required AsyncValue<PortfolioRiskSnapshot> riskValue,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _metricCard(context, 'Total Portfolio Value',
            '\$${totalValue.toStringAsFixed(0)}', 'Marked to market'),
        _metricCard(context, 'Active Positions', '$activePositions',
            'Open YES/NO exposures'),
        _metricCard(context, 'Daily PnL', '\$${dailyPnl.toStringAsFixed(0)}',
            dailyPnl >= 0 ? 'Positive day' : 'Drawdown day'),
        _metricCard(
            context,
            'Confidence Index',
            '${(confidenceIndex * 100).toStringAsFixed(1)}%',
            'Model-weighted confidence'),
        _metricCard(
          context,
          'Risk Score',
          riskValue.maybeWhen(
              data: (v) => v.riskScore, orElse: () => 'Loading'),
          riskValue.maybeWhen(
              data: (v) => 'VaR95 \$${v.var95.toStringAsFixed(0)}',
              orElse: () => 'Awaiting risk engine'),
        ),
      ],
    );
  }

  Widget _metricCard(
      BuildContext context, String label, String value, String detail) {
    return SizedBox(
      width: 260,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AetherColors.muted)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    numericStyle(context, size: 26, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(color: AetherColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _featuredMarketPanel(Market market) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Featured Market Terminal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '${market.title} • AI confidence ${(market.aiConfidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: AetherColors.muted),
          ),
          const SizedBox(height: 12),
          TradingViewChart(
            symbol: _marketSymbol(market.title),
            timeframe: '15m',
            height: 320,
            overlayProbability: market.yesProbability,
          ),
        ],
      ),
    );
  }

  Widget _pnlChartCard(List<PortfolioPosition> positions) {
    final points = positions.isEmpty
        ? [1200.0, 1180.0, 1225.0, 1270.0, 1320.0, 1290.0]
        : positions
            .asMap()
            .entries
            .map((e) => 1000.0 + (e.value.pnl * 1.7))
            .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Portfolio Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('PnL Trend', style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: points.reduce((a, b) => a < b ? a : b) - 100,
                maxY: points.reduce((a, b) => a > b ? a : b) + 100,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AetherColors.accent,
                    barWidth: 2.2,
                    belowBarData: BarAreaData(
                        show: true,
                        color: AetherColors.accent.withValues(alpha: 0.16)),
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i])
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketVolumeCard(List<Market> markets) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Markets',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Market Volume',
              style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: [
                  for (var i = 0; i < markets.take(6).length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: markets[i].volume / 10000,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          color: AetherColors.accentSoft,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceTrendCard(List<Market> markets) {
    final data = markets.isEmpty
        ? [0.72, 0.75, 0.73, 0.78, 0.81]
        : markets.take(5).map((m) => m.aiConfidence).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Confidence Signals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Confidence Trend Graph',
              style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 1,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 2.2,
                    color: AetherColors.success,
                    spots: [
                      for (var i = 0; i < data.length; i++)
                        FlSpot(i.toDouble(), data[i])
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskExposureCard(AsyncValue<List<ExposureSlice>> exposureValue) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risk Exposure',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          exposureValue.when(
            data: (slices) => SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: [
                    for (var i = 0; i < slices.length; i++)
                      PieChartSectionData(
                        value: slices[i].allocation,
                        title: '${slices[i].allocation.toStringAsFixed(0)}%',
                        color: [
                          AetherColors.accent,
                          AetherColors.success,
                          AetherColors.warning,
                          AetherColors.accentSoft
                        ][i % 4],
                        radius: 52,
                        titleStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Text(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertsCard(AsyncValue<List<AppNotification>> alertsValue) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          alertsValue.when(
            data: (alerts) => Column(
              children: alerts.take(5).map((alert) {
                final severity = alert.level.toLowerCase();
                final color = severity == 'critical'
                    ? AetherColors.critical
                    : severity == 'warning'
                        ? AetherColors.warning
                        : AetherColors.accent;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AetherColors.bgPanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AetherColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(alert.message,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                );
              }).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _agentActivityCard(AsyncValue<List<AgentCardModel>> agentsValue) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          agentsValue.when(
            data: (agents) => DataTable(
              columns: const [
                DataColumn(label: Text('Agent')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('PnL')),
              ],
              rows: [
                for (final a in agents.take(6))
                  DataRow(cells: [
                    DataCell(Text(a.name)),
                    DataCell(Text(a.status)),
                    DataCell(Text('\$${a.pnl.toStringAsFixed(0)}')),
                  ]),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _recentTransactionsCard(List<PortfolioPosition> positions) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (positions.isEmpty)
            const Text('No active positions. Start by exploring live markets.')
          else
            DataTable(
              columns: const [
                DataColumn(label: Text('Market')),
                DataColumn(label: Text('Side')),
                DataColumn(label: Text('Size')),
                DataColumn(label: Text('PnL')),
              ],
              rows: [
                for (final p in positions.take(8))
                  DataRow(cells: [
                    DataCell(Text(p.marketTitle)),
                    DataCell(Text(p.side)),
                    DataCell(Text(p.size.toStringAsFixed(0))),
                    DataCell(Text('\$${p.pnl.toStringAsFixed(0)}')),
                  ]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _sentimentFeedCard(AsyncValue<SentimentFeed> sentimentValue) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Sentiment Feed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          sentimentValue.when(
            data: (sentiment) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Trend: ${sentiment.trend} • Score ${sentiment.sentimentScore.toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                ...sentiment.newsItems.take(4).map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• ${n.headline} (${n.source})'),
                    )),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _aiSignalsCard(
      AsyncValue<LiveMarketUpdate> liveUpdate, List<Market> markets) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Signal Tape',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          liveUpdate.when(
            data: (event) => Text(
                'Latest: ${event.market} moved to ${(event.yesProbability * 100).toStringAsFixed(1)}% YES'),
            loading: () => const Text('Connecting websocket...'),
            error: (_, __) => const Text('Signal stream unavailable'),
          ),
          const SizedBox(height: 10),
          ...markets.take(5).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(m.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('${(m.aiConfidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: AetherColors.muted)),
                  ],
                ),
              )),
        ],
      ),
    );
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
