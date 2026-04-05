import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'glass_card.dart';

class DepthLevel {
  const DepthLevel(this.price, this.size);
  final double price;
  final double size;
}

class MarketDepthPanel extends StatelessWidget {
  const MarketDepthPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final bids =
        List.generate(8, (i) => DepthLevel(118420 - (i * 12), 1.2 + (i * 0.4)));
    final asks = List.generate(
        8, (i) => DepthLevel(118430 + (i * 12), 1.1 + (i * 0.35)));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Depth',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
              'Last: 118,426 • Spread: 0.04% • 24h Vol: 2.8B • OI: 1.2B • Volatility: 61%',
              style: TextStyle(fontSize: 12, color: AetherColors.muted)),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                  child: Text('Bids',
                      style: TextStyle(color: AetherColors.success))),
              Expanded(
                  child: Text('Asks',
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
                      child: _row('${b.price.toStringAsFixed(0)}', b.size,
                          AetherColors.success)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: _row('${a.price.toStringAsFixed(0)}', a.size,
                          AetherColors.critical)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text('Depth Heatmap',
              style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 6),
          Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [
                  Color(0x332FB67C),
                  Color(0x332C3747),
                  Color(0x33E25B5B)
                ],
              ),
              border: Border.all(color: AetherColors.border),
            ),
          ),
        ],
      ),
    );
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
          Text(size.toStringAsFixed(2),
              style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
