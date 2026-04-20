class OrderLevel {
  const OrderLevel({required this.price, required this.shares});

  final double price;
  final double shares;

  factory OrderLevel.fromJson(Map<String, dynamic> json) {
    return OrderLevel(
      price: (json['price'] as num).toDouble(),
      shares: (json['shares'] as num).toDouble(),
    );
  }
}

class OrderBook {
  const OrderBook({
    required this.yesBids,
    required this.yesAsks,
    required this.noBids,
    required this.noAsks,
    required this.bestYesBid,
    required this.bestYesAsk,
  });

  final List<OrderLevel> yesBids;
  final List<OrderLevel> yesAsks;
  final List<OrderLevel> noBids;
  final List<OrderLevel> noAsks;
  final double bestYesBid;
  final double bestYesAsk;

  factory OrderBook.fromJson(Map<String, dynamic> json) {
    List<OrderLevel> parse(String key) => (json[key] as List<dynamic>? ?? [])
        .map((e) => OrderLevel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return OrderBook(
      yesBids: parse('yes_bids'),
      yesAsks: parse('yes_asks'),
      noBids: parse('no_bids'),
      noAsks: parse('no_asks'),
      bestYesBid: (json['best_yes_bid'] as num?)?.toDouble() ?? 0.5,
      bestYesAsk: (json['best_yes_ask'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class MarketModel {
  const MarketModel({
    required this.id,
    required this.title,
    required this.event,
    required this.provider,
    required this.yesPrice,
    required this.noPrice,
    required this.impliedProbability,
    required this.spreadCents,
    required this.spreadTier,
    required this.liquidityUsd,
    required this.endTs,
    required this.oddsHistory,
    required this.orderBook,
  });

  final int id;
  final String title;
  final String event;
  final String provider;
  final double yesPrice;
  final double noPrice;
  final double impliedProbability;
  final int spreadCents;
  final String spreadTier;
  final double liquidityUsd;
  final DateTime endTs;
  final List<double> oddsHistory;
  final OrderBook orderBook;

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'] as int,
      title: json['title'] as String,
      event: json['event'] as String,
      provider: json['provider'] as String? ?? 'mock',
      yesPrice: (json['yes_price'] as num).toDouble(),
      noPrice: (json['no_price'] as num).toDouble(),
      impliedProbability: (json['implied_probability'] as num).toDouble(),
      spreadCents: (json['spread_cents'] as num).toInt(),
      spreadTier: json['spread_tier'] as String,
      liquidityUsd: (json['liquidity_usd'] as num).toDouble(),
      endTs: DateTime.parse(json['end_ts'] as String),
      oddsHistory: (json['odds_history'] as List<dynamic>? ?? [])
          .map((value) => (value as num).toDouble())
          .toList(),
      orderBook: OrderBook.fromJson(
        Map<String, dynamic>.from(json['order_book'] as Map? ?? {}),
      ),
    );
  }
}
