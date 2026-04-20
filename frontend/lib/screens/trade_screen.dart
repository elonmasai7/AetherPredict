import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/market.dart';
import '../providers/auth_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/spread_badge.dart';

class TradeScreen extends ConsumerStatefulWidget {
  const TradeScreen({super.key});

  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> {
  double _ticket = 25;
  String _side = 'BUY_YES';
  String? _result;

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(selectedMarketProvider);
    if (market == null) {
      return const Scaffold(body: Center(child: Text('Select a market from Home.')));
    }
    final liveOdds = ref.watch(liveOddsProvider(market.id));
    final liquidity = ref.watch(liquidityProvider(market.id));
    final displayMarket = liveOdds.maybeWhen(
      data: (snapshot) => MarketModel.fromJson({
        'id': market.id,
        'title': market.title,
        'event': market.event,
        'provider': market.provider,
        'yes_price': snapshot['yes_price'],
        'no_price': snapshot['no_price'],
        'implied_probability': snapshot['implied_probability'],
        'spread_cents': snapshot['bid_ask_spread_cents'],
        'spread_tier': snapshot['spread_tier'],
        'liquidity_usd': snapshot['liquidity_usd'],
        'end_ts': market.endTs.toIso8601String(),
        'odds_history': market.oddsHistory,
        'order_book': snapshot['order_book'],
      }),
      orElse: () => market,
    );

    final referencePrice = _side.contains('YES') ? displayMarket.yesPrice : displayMarket.noPrice;
    final estShares = _ticket / referencePrice;
    final estSlippage = ((_ticket / (displayMarket.liquidityUsd + 1)) * 100).clamp(0.2, 8.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Trade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(displayMarket.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Bid ${displayMarket.orderBook.bestYesBid.toStringAsFixed(2)} / Ask ${displayMarket.orderBook.bestYesAsk.toStringAsFixed(2)}')),
              SpreadBadge(spreadCents: displayMarket.spreadCents, tier: displayMarket.spreadTier),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: _orderBookChart(displayMarket.orderBook)),
          const SizedBox(height: 16),
          liquidity.when(
            data: (value) => Text(
              'Maker concentration ${value.makerConcentration.toStringAsFixed(1)}% · YES depth \$${value.depthYes.toStringAsFixed(0)} · NO depth \$${value.depthNo.toStringAsFixed(0)}',
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'BUY_YES', label: Text('Buy YES')),
              ButtonSegment(value: 'BUY_NO', label: Text('Buy NO')),
              ButtonSegment(value: 'SELL_YES', label: Text('Sell YES')),
              ButtonSegment(value: 'SELL_NO', label: Text('Sell NO')),
            ],
            selected: {_side},
            onSelectionChanged: (value) => setState(() => _side = value.first),
          ),
          const SizedBox(height: 16),
          Text('Retail ticket: \$${_ticket.toStringAsFixed(0)}'),
          Slider(
            min: 5,
            max: 100,
            divisions: 19,
            value: _ticket,
            label: '\$${_ticket.toStringAsFixed(0)}',
            onChanged: (value) => setState(() => _ticket = value),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expected price ${referencePrice.toStringAsFixed(3)}'),
                  Text('Estimated shares ${estShares.toStringAsFixed(2)}'),
                  Text('Estimated slippage ${estSlippage.toStringAsFixed(2)}%'),
                  if (estSlippage > 2) const Text('Warning: higher price impact for this size.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final result = await ref.read(apiServiceProvider).trade(displayMarket.id, _side, _ticket);
              setState(() {
                _result =
                    'Executed ${result['side']} at ${(result['execution_price'] as num).toDouble().toStringAsFixed(3)} · slippage ${(result['slippage_pct'] as num).toDouble().toStringAsFixed(2)}%';
              });
              ref.invalidate(marketListProvider);
              ref.invalidate(liquidityProvider(displayMarket.id));
            },
            child: Text(_side.replaceAll('_', ' ')),
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            Text(_result!, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _orderBookChart(OrderBook book) {
    final asks = book.yesAsks.take(4).toList();
    final bids = book.yesBids.take(4).toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < bids.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bids[i].shares,
                  color: const Color(0xFF18A36B),
                  width: 12,
                ),
                BarChartRodData(
                  toY: asks[i].shares,
                  color: const Color(0xFFE45B5B),
                  width: 12,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
