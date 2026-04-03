class Market {
  const Market({
    required this.id,
    required this.title,
    required this.category,
    required this.yesProbability,
    required this.aiConfidence,
    required this.volume,
    required this.liquidity,
    required this.points,
  });

  final String id;
  final String title;
  final String category;
  final double yesProbability;
  final double aiConfidence;
  final double volume;
  final double liquidity;
  final List<double> points;

  factory Market.fromJson(Map<String, dynamic> json) {
    final yesProbability = (json['yes_probability'] as num).toDouble();
    return Market(
      id: json['id'].toString(),
      title: json['title'] as String,
      category: json['category'] as String,
      yesProbability: yesProbability,
      aiConfidence: (json['ai_confidence'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      liquidity: (json['liquidity'] as num).toDouble(),
      points: [
        (yesProbability - 0.08).clamp(0, 1),
        (yesProbability - 0.04).clamp(0, 1),
        (yesProbability - 0.02).clamp(0, 1),
        yesProbability,
      ],
    );
  }
}

class AgentCardModel {
  const AgentCardModel({
    required this.name,
    required this.status,
    required this.summary,
    required this.pnl,
  });

  final String name;
  final String status;
  final String summary;
  final double pnl;

  factory AgentCardModel.fromJson(Map<String, dynamic> json) {
    return AgentCardModel(
      name: (json['agent'] as String).replaceAll('-', ' '),
      status: json['status'] as String,
      summary: json['summary'] as String,
      pnl: (json['pnl'] as num).toDouble(),
    );
  }
}

class PortfolioPosition {
  const PortfolioPosition({
    required this.marketId,
    required this.marketTitle,
    required this.side,
    required this.size,
    required this.avgPrice,
    required this.markPrice,
    required this.pnl,
  });

  final int marketId;
  final String marketTitle;
  final String side;
  final double size;
  final double avgPrice;
  final double markPrice;
  final double pnl;

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) {
    return PortfolioPosition(
      marketId: json['market_id'] as int,
      marketTitle: json['market_title'] as String,
      side: json['side'] as String,
      size: (json['size'] as num).toDouble(),
      avgPrice: (json['avg_price'] as num).toDouble(),
      markPrice: (json['mark_price'] as num).toDouble(),
      pnl: (json['pnl'] as num).toDouble(),
    );
  }
}

class LiveMarketUpdate {
  const LiveMarketUpdate({
    required this.market,
    required this.yesProbability,
    required this.confidence,
    required this.timestamp,
  });

  final String market;
  final double yesProbability;
  final double confidence;
  final DateTime timestamp;

  factory LiveMarketUpdate.fromJson(Map<String, dynamic> json) {
    return LiveMarketUpdate(
      market: json['market'] as String,
      yesProbability: (json['yes_probability'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
