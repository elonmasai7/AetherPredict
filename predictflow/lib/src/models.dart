enum Outcome { yes, no }

enum Side { buy, sell }

enum OrderType { market, limit }

class Order {
  Order({
    required this.id,
    required this.marketId,
    required this.wallet,
    required this.outcome,
    required this.side,
    required this.type,
    required this.shares,
    required this.createdAt,
    this.limitPrice,
  });

  final String id;
  final String marketId;
  final String wallet;
  final Outcome outcome;
  final Side side;
  final OrderType type;
  final double shares;
  final double? limitPrice;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'marketId': marketId,
    'wallet': wallet,
    'outcome': outcome.name.toUpperCase(),
    'side': side.name.toUpperCase(),
    'type': type.name.toUpperCase(),
    'shares': shares,
    'limitPrice': limitPrice,
    'createdAt': createdAt.toIso8601String(),
  };
}

class OrderLevel {
  OrderLevel({required this.price, required this.shares, required this.orders});

  final double price;
  double shares;
  int orders;

  Map<String, dynamic> toJson() => {
    'price': price,
    'shares': shares,
    'orders': orders,
  };
}

class TradeFill {
  TradeFill({
    required this.orderId,
    required this.marketId,
    required this.outcome,
    required this.side,
    required this.shares,
    required this.price,
    required this.source,
    required this.createdAt,
  });

  final String orderId;
  final String marketId;
  final Outcome outcome;
  final Side side;
  final double shares;
  final double price;
  final String source;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'marketId': marketId,
    'outcome': outcome.name.toUpperCase(),
    'side': side.name.toUpperCase(),
    'shares': shares,
    'price': price,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
  };
}

class LiquidityProviderPosition {
  LiquidityProviderPosition({
    required this.wallet,
    required this.collateral,
    required this.sharePct,
  });

  final String wallet;
  double collateral;
  double sharePct;

  Map<String, dynamic> toJson() => {
    'wallet': wallet,
    'collateral': collateral,
    'sharePct': sharePct,
  };
}

class Market {
  Market({
    required this.id,
    required this.address,
    required this.title,
    required this.description,
    required this.category,
    required this.resolutionSource,
    required this.closesAt,
    required this.liquidityUsd,
    required this.volume24h,
    required this.yesPrice,
    required this.noPrice,
    required this.spread,
    required this.spreadTier,
    required this.ammYesReserve,
    required this.ammNoReserve,
    required this.rebateBps,
    required this.feeBps,
    required this.topProviders,
    this.resolved = false,
    this.resolvedOutcome,
  });

  final String id;
  final String address;
  final String title;
  final String description;
  final String category;
  final String resolutionSource;
  final DateTime closesAt;
  double liquidityUsd;
  double volume24h;
  double yesPrice;
  double noPrice;
  double spread;
  String spreadTier;
  double ammYesReserve;
  double ammNoReserve;
  int rebateBps;
  int feeBps;
  bool resolved;
  Outcome? resolvedOutcome;
  final List<LiquidityProviderPosition> topProviders;

  Map<String, dynamic> toJson() => {
    'id': id,
    'address': address,
    'title': title,
    'description': description,
    'category': category,
    'resolutionSource': resolutionSource,
    'closesAt': closesAt.toIso8601String(),
    'liquidityUsd': liquidityUsd,
    'volume24h': volume24h,
    'yesPrice': yesPrice,
    'noPrice': noPrice,
    'spread': spread,
    'spreadTier': spreadTier,
    'ammYesReserve': ammYesReserve,
    'ammNoReserve': ammNoReserve,
    'rebateBps': rebateBps,
    'feeBps': feeBps,
    'resolved': resolved,
    'resolvedOutcome': resolvedOutcome?.name.toUpperCase(),
    'topProviders': topProviders.map((item) => item.toJson()).toList(),
  };
}

class PortfolioPosition {
  PortfolioPosition({
    required this.marketId,
    required this.title,
    required this.outcome,
    required this.shares,
    required this.avgEntry,
    required this.markPrice,
    required this.unrealizedPnl,
  });

  final String marketId;
  final String title;
  final Outcome outcome;
  double shares;
  double avgEntry;
  double markPrice;
  double unrealizedPnl;

  Map<String, dynamic> toJson() => {
    'marketId': marketId,
    'title': title,
    'outcome': outcome.name.toUpperCase(),
    'shares': shares,
    'avgEntry': avgEntry,
    'markPrice': markPrice,
    'unrealizedPnl': unrealizedPnl,
  };
}

class Portfolio {
  Portfolio({
    required this.wallet,
    required this.collateralBalance,
    required this.positions,
    required this.realizedPnl,
  });

  final String wallet;
  double collateralBalance;
  final List<PortfolioPosition> positions;
  double realizedPnl;

  Map<String, dynamic> toJson() => {
    'wallet': wallet,
    'collateralBalance': collateralBalance,
    'positions': positions.map((item) => item.toJson()).toList(),
    'realizedPnl': realizedPnl,
  };
}
