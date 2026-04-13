import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/theme.dart';

class _SignalItem {
  const _SignalItem({
    required this.symbol,
    required this.consensusShiftPct,
    required this.eventLiquidity,
  });

  final String symbol;
  final double consensusShiftPct;
  final double eventLiquidity;
}

class LiveSignalBar extends StatefulWidget {
  const LiveSignalBar({super.key});

  @override
  State<LiveSignalBar> createState() => _LiveSignalBarState();
}

class _LiveSignalBarState extends State<LiveSignalBar> {
  List<_SignalItem> _items = const [];
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
            (json) => _SignalItem(
              symbol: json['symbol'] as String,
              consensusShiftPct: (json['change_24h'] as num).toDouble(),
              eventLiquidity: (json['volume_24h'] as num).toDouble(),
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
          const Text('LIVE SIGNALS',
              style: TextStyle(fontSize: 12, color: AetherColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: _items.isEmpty
                ? const Text(
                    'No live consensus shifts available yet.',
                    style: TextStyle(fontSize: 12, color: AetherColors.muted),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final up = item.consensusShiftPct >= 0;
                      return Row(
                        children: [
                          Text(
                            '${item.symbol} consensus',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${up ? '▲' : '▼'}${item.consensusShiftPct.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: up
                                  ? AetherColors.success
                                  : AetherColors.critical,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Liquidity:${_formatCompact(item.eventLiquidity)}',
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
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
