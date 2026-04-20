class PositionModel {
  const PositionModel({
    required this.positionId,
    required this.marketId,
    required this.title,
    required this.side,
    required this.shares,
    required this.avgPrice,
    required this.markPrice,
    required this.pnl,
    required this.spreadCents,
    required this.volume,
  });

  final int positionId;
  final int marketId;
  final String title;
  final String side;
  final double shares;
  final double avgPrice;
  final double markPrice;
  final double pnl;
  final int spreadCents;
  final double volume;

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      positionId: json['position_id'] as int,
      marketId: json['market_id'] as int,
      title: json['title'] as String,
      side: json['side'] as String,
      shares: (json['shares'] as num).toDouble(),
      avgPrice: (json['avg_price'] as num).toDouble(),
      markPrice: (json['mark_price'] as num).toDouble(),
      pnl: (json['pnl'] as num).toDouble(),
      spreadCents: (json['spread_cents'] as num).toInt(),
      volume: (json['volume'] as num).toDouble(),
    );
  }
}

class DashboardModel {
  const DashboardModel({
    required this.cashBalance,
    required this.totalPnl,
    required this.positions,
  });

  final double cashBalance;
  final double totalPnl;
  final List<PositionModel> positions;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      cashBalance: (json['cash_balance'] as num).toDouble(),
      totalPnl: (json['total_pnl'] as num).toDouble(),
      positions: (json['positions'] as List<dynamic>? ?? [])
          .map((e) => PositionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
