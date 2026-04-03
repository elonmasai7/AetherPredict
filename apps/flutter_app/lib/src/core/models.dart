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
}
