import 'dart:math';

import 'package:uuid/uuid.dart';

import 'models.dart';
import 'seed.dart';

double clamp(double value, double minValue, double maxValue) {
  return max(minValue, min(maxValue, value));
}

double midPrice(double yesReserve, double noReserve, Outcome outcome) {
  final total = yesReserve + noReserve;
  if (total == 0) {
    return 0.5;
  }
  final yesPrice = noReserve / total;
  return outcome == Outcome.yes ? yesPrice : 1 - yesPrice;
}

({double spread, String tier}) spreadTierForLiquidity(double liquidityUsd) {
  if (liquidityUsd >= 100000) {
    return (spread: 0.01, tier: 'HIGH');
  }
  if (liquidityUsd >= 60000) {
    return (spread: 0.02, tier: 'MEDIUM');
  }
  return (spread: 0.11, tier: 'LOW');
}

class PreviewResult {
  PreviewResult({
    required this.sharesOut,
    required this.avgPrice,
    required this.priceImpact,
    required this.collateralOut,
  });

  final double sharesOut;
  final double avgPrice;
  final double priceImpact;
  final double collateralOut;

  Map<String, dynamic> toJson() => {
    'sharesOut': sharesOut,
    'avgPrice': avgPrice,
    'priceImpact': priceImpact,
    'collateralOut': collateralOut,
  };
}

class PlaceOrderResult {
  PlaceOrderResult({
    required this.order,
    required this.fills,
    required this.snapshot,
  });

  final Order order;
  final List<TradeFill> fills;
  final Map<String, dynamic> snapshot;

  Map<String, dynamic> toJson() => {
    'order': order.toJson(),
    'fills': fills.map((item) => item.toJson()).toList(),
    'snapshot': snapshot,
  };
}

class PredictFlowEngine {
  PredictFlowEngine({List<Market>? markets, List<Portfolio>? portfolios})
    : _markets = {
        for (final market in markets ?? seedMarkets()) market.id: market,
      },
      _portfolios = {
        for (final portfolio in portfolios ?? seedPortfolios())
          portfolio.wallet: portfolio,
      };

  final _uuid = const Uuid();
  final Map<String, Market> _markets;
  final Map<String, Portfolio> _portfolios;
  final Map<String, List<TradeFill>> _recentTrades = {};

  List<Market> listMarkets() => _markets.values.toList(growable: false);

  Portfolio getPortfolio(String wallet) => _portfolios.putIfAbsent(
    wallet,
    () => Portfolio(
      wallet: wallet,
      collateralBalance: 2000,
      positions: [],
      realizedPnl: 0,
    ),
  );

  Map<String, dynamic> getMarketSnapshot(String marketId) {
    final market = _requireMarket(marketId);
    final orderBook = _buildOrderBook(market);
    return {
      ...market.toJson(),
      'orderBook': orderBook,
      'recentTrades': getRecentTrades(
        marketId,
      ).map((item) => item.toJson()).toList(),
    };
  }

  List<TradeFill> getRecentTrades(String marketId) {
    return List<TradeFill>.from(_recentTrades[marketId] ?? const []);
  }

  PreviewResult previewOrder({
    required String marketId,
    required Outcome outcome,
    required Side side,
    required OrderType type,
    required double shares,
    double? limitPrice,
  }) {
    final market = _requireMarket(marketId);
    final reserveIn = outcome == Outcome.yes
        ? market.ammNoReserve
        : market.ammYesReserve;
    final reserveOut = outcome == Outcome.yes
        ? market.ammYesReserve
        : market.ammNoReserve;
    final k = market.ammYesReserve * market.ammNoReserve;
    if (side == Side.buy) {
      final dollarsIn = shares * (limitPrice ?? market.yesPrice);
      final fee = dollarsIn * (market.feeBps / 10000);
      final netIn = dollarsIn - fee;
      final newReserveIn = reserveIn + netIn;
      final newReserveOut = k / newReserveIn;
      final sharesOut = max(0, reserveOut - newReserveOut);
      final avgPrice = sharesOut > 0 ? dollarsIn / sharesOut : 0;
      final pre = midPrice(market.ammYesReserve, market.ammNoReserve, outcome);
      final post = outcome == Outcome.yes
          ? newReserveIn / (newReserveIn + newReserveOut)
          : newReserveOut / (newReserveIn + newReserveOut);
      final impact = pre > 0 ? (post - pre).abs() / pre : 0;
      return PreviewResult(
        sharesOut: sharesOut,
        avgPrice: avgPrice,
        priceImpact: impact,
        collateralOut: 0,
      );
    }
    final newReserveIn = reserveOut + shares;
    final newReserveOut = k / newReserveIn;
    final grossOut = max(0, reserveIn - newReserveOut);
    final fee = grossOut * (market.feeBps / 10000);
    final collateralOut = grossOut - fee;
    final avgPrice = shares > 0 ? collateralOut / shares : 0;
    final pre = midPrice(market.ammYesReserve, market.ammNoReserve, outcome);
    final post = outcome == Outcome.yes
        ? newReserveOut / (newReserveIn + newReserveOut)
        : newReserveIn / (newReserveIn + newReserveOut);
    final impact = pre > 0 ? (post - pre).abs() / pre : 0;
    return PreviewResult(
      sharesOut: 0,
      avgPrice: avgPrice,
      priceImpact: impact,
      collateralOut: collateralOut,
    );
  }

  PlaceOrderResult placeOrder({
    required String marketId,
    required String wallet,
    required Outcome outcome,
    required Side side,
    required OrderType type,
    required double shares,
    double? limitPrice,
  }) {
    final preview = previewOrder(
      marketId: marketId,
      outcome: outcome,
      side: side,
      type: type,
      shares: shares,
      limitPrice: limitPrice,
    );
    final market = _requireMarket(marketId);
    final portfolio = getPortfolio(wallet);
    final order = Order(
      id: _uuid.v4(),
      marketId: marketId,
      wallet: wallet,
      outcome: outcome,
      side: side,
      type: type,
      shares: shares,
      limitPrice: limitPrice,
      createdAt: DateTime.now().toUtc(),
    );
    final fill = TradeFill(
      orderId: order.id,
      marketId: marketId,
      outcome: outcome,
      side: side,
      shares: side == Side.buy ? preview.sharesOut : shares,
      price: preview.avgPrice,
      source: 'AMM',
      createdAt: DateTime.now().toUtc(),
    );
    _recentTrades.putIfAbsent(marketId, () => []).insert(0, fill);
    _recentTrades[marketId] = _recentTrades[marketId]!.take(20).toList();

    if (side == Side.buy) {
      final spend = fill.shares * fill.price;
      if (portfolio.collateralBalance < spend) {
        throw StateError('Insufficient collateral balance.');
      }
      portfolio.collateralBalance -= spend;
      _applyBuy(market, outcome, spend, fill.shares);
      _upsertPosition(portfolio, market, outcome, fill.shares, fill.price);
    } else {
      _applySell(market, outcome, shares, preview.collateralOut);
      portfolio.collateralBalance += preview.collateralOut;
      _reducePosition(portfolio, market, outcome, shares, preview.avgPrice);
    }

    _markMarket(market);
    final snapshot = getMarketSnapshot(marketId);
    return PlaceOrderResult(order: order, fills: [fill], snapshot: snapshot);
  }

  Market addLiquidity(String marketId, String wallet, double collateral) {
    final market = _requireMarket(marketId);
    market.liquidityUsd += collateral;
    market.ammYesReserve += collateral / 2;
    market.ammNoReserve += collateral / 2;
    final existing = market.topProviders
        .where((item) => item.wallet == wallet)
        .cast<LiquidityProviderPosition?>()
        .firstWhere((item) => item != null, orElse: () => null);
    if (existing == null) {
      market.topProviders.add(
        LiquidityProviderPosition(
          wallet: wallet,
          collateral: collateral,
          sharePct: 0,
        ),
      );
    } else {
      existing.collateral += collateral;
    }
    _reweightProviders(market);
    _markMarket(market);
    return market;
  }

  Market resolveMarket(String marketId, Outcome outcome) {
    final market = _requireMarket(marketId);
    market.resolved = true;
    market.resolvedOutcome = outcome;
    return market;
  }

  Market _requireMarket(String marketId) {
    final market = _markets[marketId];
    if (market == null) {
      throw StateError('Market $marketId not found.');
    }
    return market;
  }

  void _applyBuy(
    Market market,
    Outcome outcome,
    double spend,
    double sharesOut,
  ) {
    if (outcome == Outcome.yes) {
      market.ammNoReserve += spend;
      market.ammYesReserve = max(1, market.ammYesReserve - sharesOut);
    } else {
      market.ammYesReserve += spend;
      market.ammNoReserve = max(1, market.ammNoReserve - sharesOut);
    }
    market.volume24h += spend;
  }

  void _applySell(
    Market market,
    Outcome outcome,
    double shares,
    double collateralOut,
  ) {
    if (outcome == Outcome.yes) {
      market.ammYesReserve += shares;
      market.ammNoReserve = max(1, market.ammNoReserve - collateralOut);
    } else {
      market.ammNoReserve += shares;
      market.ammYesReserve = max(1, market.ammYesReserve - collateralOut);
    }
    market.volume24h += collateralOut;
  }

  void _upsertPosition(
    Portfolio portfolio,
    Market market,
    Outcome outcome,
    double shares,
    double avgPrice,
  ) {
    final existing = portfolio.positions
        .where((item) => item.marketId == market.id && item.outcome == outcome)
        .cast<PortfolioPosition?>()
        .firstWhere((item) => item != null, orElse: () => null);
    if (existing == null) {
      portfolio.positions.add(
        PortfolioPosition(
          marketId: market.id,
          title: market.title,
          outcome: outcome,
          shares: shares,
          avgEntry: avgPrice,
          markPrice: outcome == Outcome.yes ? market.yesPrice : market.noPrice,
          unrealizedPnl: 0,
        ),
      );
      return;
    }
    final totalShares = existing.shares + shares;
    existing.avgEntry =
        ((existing.avgEntry * existing.shares) + (avgPrice * shares)) /
        totalShares;
    existing.shares = totalShares;
    existing.markPrice = outcome == Outcome.yes
        ? market.yesPrice
        : market.noPrice;
    existing.unrealizedPnl =
        (existing.markPrice - existing.avgEntry) * existing.shares;
  }

  void _reducePosition(
    Portfolio portfolio,
    Market market,
    Outcome outcome,
    double shares,
    double avgPrice,
  ) {
    final existing = portfolio.positions
        .where((item) => item.marketId == market.id && item.outcome == outcome)
        .cast<PortfolioPosition?>()
        .firstWhere((item) => item != null, orElse: () => null);
    if (existing == null) {
      throw StateError('No position available to sell.');
    }
    if (existing.shares < shares) {
      throw StateError('Cannot sell more shares than owned.');
    }
    existing.shares -= shares;
    portfolio.realizedPnl += (avgPrice - existing.avgEntry) * shares;
    existing.markPrice = outcome == Outcome.yes
        ? market.yesPrice
        : market.noPrice;
    existing.unrealizedPnl =
        (existing.markPrice - existing.avgEntry) * existing.shares;
    if (existing.shares <= 0.0001) {
      portfolio.positions.remove(existing);
    }
  }

  void _markMarket(Market market) {
    market.yesPrice = clamp(
      midPrice(market.ammYesReserve, market.ammNoReserve, Outcome.yes),
      0.01,
      0.99,
    );
    market.noPrice = 1 - market.yesPrice;
    final spread = spreadTierForLiquidity(market.liquidityUsd);
    market.spread = spread.spread;
    market.spreadTier = spread.tier;
  }

  void _reweightProviders(Market market) {
    final total = market.topProviders.fold<double>(
      0,
      (sum, item) => sum + item.collateral,
    );
    for (final provider in market.topProviders) {
      provider.sharePct = total == 0 ? 0 : provider.collateral / total;
    }
    market.topProviders.sort((a, b) => b.collateral.compareTo(a.collateral));
  }

  Map<String, dynamic> _buildOrderBook(Market market) {
    final levels = <Map<String, dynamic>>[];
    for (var i = 0; i < 5; i++) {
      final step = market.spread * (i + 1);
      final bid = clamp(market.yesPrice - step, 0.01, 0.99);
      final ask = clamp(market.yesPrice + step, 0.01, 0.99);
      levels.add({
        'yesBid': OrderLevel(
          price: bid,
          shares: 140 - (i * 18),
          orders: max(1, 6 - i),
        ).toJson(),
        'yesAsk': OrderLevel(
          price: ask,
          shares: 120 - (i * 14),
          orders: max(1, 5 - i),
        ).toJson(),
        'noBid': OrderLevel(
          price: clamp(1 - ask, 0.01, 0.99),
          shares: 130 - (i * 16),
          orders: max(1, 5 - i),
        ).toJson(),
        'noAsk': OrderLevel(
          price: clamp(1 - bid, 0.01, 0.99),
          shares: 125 - (i * 12),
          orders: max(1, 4 - i),
        ).toJson(),
      });
    }
    return {'levels': levels};
  }
}
