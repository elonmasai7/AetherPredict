import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/theme.dart';
import 'glass_card.dart';

class DepthLevel {
  const DepthLevel(this.price, this.size);
  final double price;
  final double size;
}

class MarketDepthPanel extends StatelessWidget {
  const MarketDepthPanel({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({double price, double volatility, double volume})?>(
      future: _loadSymbol(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GlassCard(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (data == null) {
          return const GlassCard(
            child: Text(
              'No live depth input available for this market yet.',
              style: TextStyle(color: AetherColors.muted),
            ),
          );
        }

        final spread = (data.volatility <= 0 ? 0.15 : data.volatility / 10);
        final step = data.price * (spread / 1000);
        final bids = List.generate(
          8,
          (i) => DepthLevel(
              data.price - (i * step), (data.volume / 100000000) / (i + 1)),
        );
        final asks = List.generate(
          8,
          (i) => DepthLevel(
              data.price + (i * step), (data.volume / 110000000) / (i + 1)),
        );

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Indicative Event Liquidity Depth',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Reference: ${data.price.toStringAsFixed(data.price > 100 ? 2 : 4)} • Implied odds spread: ${spread.toStringAsFixed(2)}bp • 24h volatility: ${data.volatility.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 12, color: AetherColors.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                      child: Text('YES Pool',
                          style: TextStyle(color: AetherColors.success))),
                  Expanded(
                      child: Text('NO Pool',
                          style: TextStyle(color: AetherColors.critical))),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(8, (i) {
                final b = bids[i];
                final a = asks[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                          child: _row('${b.price.toStringAsFixed(2)}', b.size,
                              AetherColors.success)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: _row('${a.price.toStringAsFixed(2)}', a.size,
                              AetherColors.critical)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<({double price, double volatility, double volume})?>
      _loadSymbol() async {
    final response = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/markets/assets'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final data = jsonDecode(response.body) as List<dynamic>;
    for (final item in data) {
      final json = item as Map<String, dynamic>;
      if ((json['symbol'] as String).toUpperCase() == symbol.toUpperCase()) {
        return (
          price: (json['price_usd'] as num).toDouble(),
          volatility: (json['volatility_pct'] as num).toDouble(),
          volume: (json['volume_24h'] as num).toDouble(),
        );
      }
    }
    return null;
  }

  Widget _row(String price, double size, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AetherColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(price, style: const TextStyle(fontSize: 12))),
          Text(size.toStringAsFixed(4),
              style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
