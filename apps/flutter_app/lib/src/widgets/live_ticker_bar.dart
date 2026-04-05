import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';

class TickerItem {
  const TickerItem(
      {required this.symbol,
      required this.price,
      required this.changePct,
      required this.sentiment});
  final String symbol;
  final double price;
  final double changePct;
  final double sentiment;
}

class LiveTickerBar extends StatefulWidget {
  const LiveTickerBar({super.key});

  @override
  State<LiveTickerBar> createState() => _LiveTickerBarState();
}

class _LiveTickerBarState extends State<LiveTickerBar> {
  late List<TickerItem> _items;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _items = const [
      TickerItem(
          symbol: 'BTC/USD', price: 118420, changePct: 2.1, sentiment: 0.78),
      TickerItem(
          symbol: 'ETH/USD', price: 5320, changePct: -0.8, sentiment: 0.64),
      TickerItem(
          symbol: 'SOL/USD', price: 298, changePct: 4.5, sentiment: 0.82),
      TickerItem(
          symbol: 'HSK/USD', price: 1.42, changePct: 1.3, sentiment: 0.59),
    ];

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        _items = _items
            .map((e) => TickerItem(
                  symbol: e.symbol,
                  price: (e.price * (1 + ((e.changePct / 100) * 0.002))),
                  changePct:
                      (e.changePct + ((e.symbol.hashCode % 7) - 3) * 0.03)
                          .clamp(-8, 8),
                  sentiment:
                      (e.sentiment + (((e.symbol.hashCode % 5) - 2) * 0.002))
                          .clamp(0, 1),
                ))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border(bottom: BorderSide(color: AetherColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record,
              size: 10, color: AetherColors.success),
          const SizedBox(width: 8),
          const Text('LIVE',
              style: TextStyle(fontSize: 12, color: AetherColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) {
                final item = _items[i];
                final up = item.changePct >= 0;
                return Row(
                  children: [
                    Text(
                        '${item.symbol} ${item.price.toStringAsFixed(item.price > 100 ? 0 : 2)}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                        '${up ? '▲' : '▼'}${item.changePct.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: up
                                ? AetherColors.success
                                : AetherColors.critical,
                            fontSize: 12)),
                    const SizedBox(width: 6),
                    Text('S:${(item.sentiment * 100).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 11, color: AetherColors.muted)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          const Text(
              'Breaking: ETF inflows elevated; whale alert on BTC venue cluster.',
              style: TextStyle(fontSize: 11, color: AetherColors.muted)),
        ],
      ),
    );
  }
}
