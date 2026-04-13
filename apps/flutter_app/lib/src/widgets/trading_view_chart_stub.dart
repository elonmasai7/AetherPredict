import 'package:flutter/material.dart';

import '../core/theme.dart';

class TradingViewChart extends StatelessWidget {
  const TradingViewChart({
    super.key,
    required this.symbol,
    required this.timeframe,
    this.height = 360,
    this.overlayProbability,
  });

  final String symbol;
  final String timeframe;
  final double height;
  final double? overlayProbability;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AetherColors.border),
      ),
      child: Center(
        child: Text(
          'Probability context panel\nEvent: $symbol • Window: $timeframe\nYES Probability: ${overlayProbability != null ? (overlayProbability! * 100).toStringAsFixed(1) : '--'}%',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AetherColors.muted),
        ),
      ),
    );
  }
}
