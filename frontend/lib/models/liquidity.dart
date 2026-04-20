class LiquidityModel {
  const LiquidityModel({
    required this.marketId,
    required this.spreadCents,
    required this.spreadTier,
    required this.makerConcentration,
    required this.topMakerSharePct,
    required this.depthYes,
    required this.depthNo,
    this.warning,
  });

  final int marketId;
  final int spreadCents;
  final String spreadTier;
  final double makerConcentration;
  final double topMakerSharePct;
  final double depthYes;
  final double depthNo;
  final String? warning;

  factory LiquidityModel.fromJson(Map<String, dynamic> json) {
    final depth = Map<String, dynamic>.from(json['depth_usd'] as Map? ?? {});
    return LiquidityModel(
      marketId: json['market_id'] as int,
      spreadCents: (json['spread_cents'] as num).toInt(),
      spreadTier: json['spread_tier'] as String,
      makerConcentration: (json['maker_concentration'] as num).toDouble(),
      topMakerSharePct: (json['top_maker_share_pct'] as num).toDouble(),
      depthYes: (depth['yes'] as num?)?.toDouble() ?? 0,
      depthNo: (depth['no'] as num?)?.toDouble() ?? 0,
      warning: json['liquidity_warning'] as String?,
    );
  }
}
