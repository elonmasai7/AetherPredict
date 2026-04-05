import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class TradingViewChart extends StatefulWidget {
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
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'tv-${widget.symbol}-${widget.timeframe}-${DateTime.now().microsecondsSinceEpoch}';

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final interval = _mapInterval(widget.timeframe);
      final symbol = _mapSymbol(widget.symbol);
      final src =
          'https://s.tradingview.com/widgetembed/?frameElementId=tradingview_widget&symbol=$symbol&interval=$interval&hidesidetoolbar=0&symboledit=1&saveimage=1&toolbarbg=1f2733&theme=dark&style=1&timezone=Etc%2FUTC&studies=%5B%22RSI%40tv-basicstudies%22%2C%22MACD%40tv-basicstudies%22%2C%22BB%40tv-basicstudies%22%2C%22MASimple%40tv-basicstudies%22%5D&hideideas=1';

      final frame = html.IFrameElement()
        ..src = src
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';

      return frame;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AetherColors.bgPanel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AetherColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: HtmlElementView(viewType: _viewType),
        ),
        if (widget.overlayProbability != null)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AetherColors.bg.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AetherColors.border),
              ),
              child: Text(
                'AI Probability ${(widget.overlayProbability! * 100).toStringAsFixed(1)}%',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  String _mapInterval(String tf) {
    switch (tf) {
      case '1m':
        return '1';
      case '5m':
        return '5';
      case '15m':
        return '15';
      case '1h':
        return '60';
      case '4h':
        return '240';
      case '1D':
      default:
        return 'D';
    }
  }

  String _mapSymbol(String input) {
    final upper = input.toUpperCase();
    if (upper.contains('BTC')) return 'BINANCE:BTCUSDT';
    if (upper.contains('ETH')) return 'BINANCE:ETHUSDT';
    if (upper.contains('SOL')) return 'BINANCE:SOLUSDT';
    return 'BINANCE:BTCUSDT';
  }
}
