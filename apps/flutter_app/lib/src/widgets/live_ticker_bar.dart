import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/theme.dart';

class TickerItem {
  const TickerItem({
    required this.symbol,
    required this.price,
    required this.changePct,
    required this.volume24h,
  });

  final String symbol;
  final double price;
  final double changePct;
  final double volume24h;
}

class LiveTickerBar extends StatefulWidget {
  const LiveTickerBar({super.key});

  @override
  State<LiveTickerBar> createState() => _LiveTickerBarState();
}

class _LiveTickerBarState extends State<LiveTickerBar> {
  List<TickerItem> _items = const [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/markets/assets'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final data = jsonDecode(response.body) as List<dynamic>;
      final items = data
          .map((item) => item as Map<String, dynamic>)
          .map(
            (json) => TickerItem(
              symbol: json['symbol'] as String,
              price: (json['price_usd'] as num).toDouble(),
              changePct: (json['change_24h'] as num).toDouble(),
              volume24h: (json['volume_24h'] as num).toDouble(),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = const []);
    }
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
            child: _items.isEmpty
                ? const Text(
                    'No live market snapshots available yet.',
                    style: TextStyle(fontSize: 12, color: AetherColors.muted),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final up = item.changePct >= 0;
                      return Row(
                        children: [
                          Text(
                            '${item.symbol}/USD ${item.price.toStringAsFixed(item.price > 100 ? 0 : 2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${up ? '▲' : '▼'}${item.changePct.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: up
                                  ? AetherColors.success
                                  : AetherColors.critical,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'V:${_formatCompact(item.volume24h)}',
                            style: const TextStyle(
                                fontSize: 11, color: AetherColors.muted),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
