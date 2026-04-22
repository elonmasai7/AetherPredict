class Market {
  const Market({
    required this.id,
    required this.title,
    required this.category,
    required this.oracleSource,
    required this.resolutionSource,
    required this.onChainAddress,
    required this.yesProbability,
    required this.noProbability,
    required this.aiConfidence,
    required this.expiry,
    required this.participantCount,
    required this.riskScore,
    required this.consensusShift,
    required this.volume,
    required this.liquidity,
    required this.points,
    required this.liquidityIntelligence,
  });

  final String id;
  final String title;
  final String category;
  final String oracleSource;
  final String resolutionSource;
  final String? onChainAddress;
  final double yesProbability;
  final double noProbability;
  final double aiConfidence;
  final DateTime? expiry;
  final int participantCount;
  final double riskScore;
  final double consensusShift;
  final double volume;
  final double liquidity;
  final List<double> points;
  final LiquiditySummary liquidityIntelligence;

  factory Market.fromJson(Map<String, dynamic> json) {
    final yesProbability = _safeProbability(json['yes_probability']);
    final noProbability = 1 - yesProbability;
    final aiConfidence = _safeProbability(json['ai_confidence']);
    final oracleSource = (json['oracle_source'] as String?) ?? '';
    final points = _parseProbabilityPoints(json);
    final previous =
        points.length > 1 ? points[points.length - 2] : yesProbability;
    final participants = _readInt(json['participant_count']) ??
        _readInt(json['participants']) ??
        (((json['volume'] as num?)?.toDouble() ?? 0) / 75000)
            .round()
            .clamp(18, 3200)
            .toInt();
    final riskRaw = _readDouble(json['risk_score']) ??
        (100 - (aiConfidence * 100)).clamp(6, 94).toDouble();
    final riskScore = riskRaw <= 1 ? riskRaw * 100 : riskRaw;
    final consensusShift = _readDouble(json['consensus_shift']) ??
        ((yesProbability - previous) * 100);
    return Market(
      id: json['id'].toString(),
      title: json['title'] as String,
      category: json['category'] as String,
      oracleSource: oracleSource,
      resolutionSource: (json['resolution_source'] as String?) ??
          (oracleSource.isEmpty ? 'Verified Oracle Network' : oracleSource),
      onChainAddress: json['on_chain_address'] as String?,
      yesProbability: yesProbability,
      noProbability: noProbability,
      aiConfidence: aiConfidence,
      expiry: _readDateTime(
        json['expiry'] ?? json['expires_at'] ?? json['resolution_window_end'],
      ),
      participantCount: participants,
      riskScore: riskScore.clamp(0, 100).toDouble(),
      consensusShift: consensusShift,
      volume: _readDouble(json['volume']) ?? 0,
      liquidity: _readDouble(json['liquidity']) ?? 0,
      points: points,
      liquidityIntelligence: LiquiditySummary.fromJson(
        Map<String, dynamic>.from(
          (json['liquidity_intelligence'] as Map?) ?? const {},
        ),
        fallbackYesProbability: yesProbability,
      ),
    );
  }
}

class LiquiditySummary {
  const LiquiditySummary({
    required this.bestYesBid,
    required this.bestYesAsk,
    required this.impliedNoBid,
    required this.impliedNoAsk,
    required this.spreadWidthCents,
    required this.liquidityLabel,
    required this.riskLabel,
  });

  final double bestYesBid;
  final double bestYesAsk;
  final double impliedNoBid;
  final double impliedNoAsk;
  final int spreadWidthCents;
  final String liquidityLabel;
  final String riskLabel;

  factory LiquiditySummary.fromJson(
    Map<String, dynamic> json, {
    required double fallbackYesProbability,
  }) {
    final implied = Map<String, dynamic>.from(
      (json['implied_no_spread'] as Map?) ?? const {},
    );
    final spread = _readInt(json['spread_width_cents']) ?? 4;
    final bestBid =
        _readDouble(json['best_yes_bid']) ?? (fallbackYesProbability - spread / 200);
    final bestAsk =
        _readDouble(json['best_yes_ask']) ?? (fallbackYesProbability + spread / 200);
    return LiquiditySummary(
      bestYesBid: bestBid.clamp(0, 1).toDouble(),
      bestYesAsk: bestAsk.clamp(0, 1).toDouble(),
      impliedNoBid: (_readDouble(implied['bid']) ?? (1 - bestAsk))
          .clamp(0, 1)
          .toDouble(),
      impliedNoAsk: (_readDouble(implied['ask']) ?? (1 - bestBid))
          .clamp(0, 1)
          .toDouble(),
      spreadWidthCents: spread,
      liquidityLabel: (json['liquidity_label'] as String?) ?? 'Moderate Liquidity',
      riskLabel: (json['risk_label'] as String?) ?? 'Medium Risk',
    );
  }
}

class LiquidityDetail {
  const LiquidityDetail({
    required this.spread,
    required this.depth,
    required this.concentration,
    required this.eventDriven,
    required this.expiryDecay,
    required this.retail,
    required this.informationShock,
    required this.risk,
    required this.marketMaker,
    required this.liquidityScore,
  });

  final LiquiditySummary spread;
  final Map<String, dynamic> depth;
  final Map<String, dynamic> concentration;
  final Map<String, dynamic> eventDriven;
  final Map<String, dynamic> expiryDecay;
  final Map<String, dynamic> retail;
  final Map<String, dynamic> informationShock;
  final Map<String, dynamic> risk;
  final Map<String, dynamic> marketMaker;
  final double liquidityScore;

  factory LiquidityDetail.fromJson(Map<String, dynamic> json) {
    final spread = Map<String, dynamic>.from((json['spread'] as Map?) ?? const {});
    return LiquidityDetail(
      spread: LiquiditySummary.fromJson(
        spread,
        fallbackYesProbability: (_readDouble(spread['best_yes_ask']) ?? 0.52),
      ),
      depth: Map<String, dynamic>.from((json['depth'] as Map?) ?? const {}),
      concentration:
          Map<String, dynamic>.from((json['concentration'] as Map?) ?? const {}),
      eventDriven:
          Map<String, dynamic>.from((json['event_driven'] as Map?) ?? const {}),
      expiryDecay:
          Map<String, dynamic>.from((json['expiry_decay'] as Map?) ?? const {}),
      retail: Map<String, dynamic>.from((json['retail'] as Map?) ?? const {}),
      informationShock: Map<String, dynamic>.from(
        (json['information_shock'] as Map?) ?? const {},
      ),
      risk: Map<String, dynamic>.from((json['risk'] as Map?) ?? const {}),
      marketMaker:
          Map<String, dynamic>.from((json['market_maker'] as Map?) ?? const {}),
      liquidityScore: (_readDouble(json['liquidity_score']) ?? 50).toDouble(),
    );
  }
}

class LiquidityDashboard {
  const LiquidityDashboard({
    required this.marketCount,
    required this.marketRankings,
    required this.spreadLeaderboard,
    required this.mostLiquidMarkets,
    required this.leastLiquidMarkets,
    required this.lpDistribution,
    required this.slippageHeatmap,
  });

  final int marketCount;
  final List<Map<String, dynamic>> marketRankings;
  final List<Map<String, dynamic>> spreadLeaderboard;
  final List<Map<String, dynamic>> mostLiquidMarkets;
  final List<Map<String, dynamic>> leastLiquidMarkets;
  final List<Map<String, dynamic>> lpDistribution;
  final List<Map<String, dynamic>> slippageHeatmap;

  factory LiquidityDashboard.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> readRows(String key) => (json[key] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return LiquidityDashboard(
      marketCount: _readInt(json['market_count']) ?? 0,
      marketRankings: readRows('market_rankings'),
      spreadLeaderboard: readRows('spread_leaderboard'),
      mostLiquidMarkets: readRows('most_liquid_markets'),
      leastLiquidMarkets: readRows('least_liquid_markets'),
      lpDistribution: readRows('lp_distribution'),
      slippageHeatmap: readRows('slippage_heatmap'),
    );
  }
}

class AgentCardModel {
  const AgentCardModel({
    required this.name,
    required this.status,
    required this.strategy,
    required this.summary,
    required this.confidence,
    required this.historicalAccuracy,
    required this.roi,
    required this.currentActiveMarkets,
    required this.pnl,
  });

  final String name;
  final String status;
  final String strategy;
  final String summary;
  final double confidence;
  final double historicalAccuracy;
  final double roi;
  final int currentActiveMarkets;
  final double pnl;

  factory AgentCardModel.fromJson(Map<String, dynamic> json) {
    final confidenceRaw = _readDouble(json['confidence']) ??
        _readDouble(json['ai_confidence']) ??
        0.72;
    final accuracyRaw = _readDouble(json['historical_accuracy']) ??
        _readDouble(json['accuracy']) ??
        0.7;
    final roiRaw =
        _readDouble(json['roi']) ?? (_readDouble(json['pnl']) ?? 0) / 100000;
    final activeMarkets = _readInt(json['active_market_count']) ??
        (json['active_markets'] is List
            ? (json['active_markets'] as List<dynamic>).length
            : 4);
    return AgentCardModel(
      name: ((json['agent'] as String?) ??
              (json['name'] as String?) ??
              'Autonomous Agent')
          .replaceAll('-', ' '),
      status: (json['status'] as String?) ?? 'active',
      strategy: (json['strategy'] as String?) ?? 'Autonomous market balancing',
      summary: (json['summary'] as String?) ??
          'Monitoring event markets and rebalancing liquidity.',
      confidence: confidenceRaw <= 1 ? confidenceRaw : confidenceRaw / 100,
      historicalAccuracy: accuracyRaw <= 1 ? accuracyRaw : accuracyRaw / 100,
      roi: roiRaw <= 1 ? roiRaw * 100 : roiRaw,
      currentActiveMarkets: activeMarkets,
      pnl: _readDouble(json['pnl']) ?? 0,
    );
  }
}

double _safeProbability(dynamic value) {
  final raw = _readDouble(value) ?? 0.5;
  final normalized = raw > 1 ? raw / 100 : raw;
  return normalized.clamp(0, 1).toDouble();
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _readDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<double> _parseProbabilityPoints(Map<String, dynamic> json) {
  final candidates = (json['probability_points'] as List<dynamic>?) ??
      (json['points'] as List<dynamic>?);
  if (candidates != null && candidates.isNotEmpty) {
    final parsed = candidates.map(_safeProbability).toList(growable: false);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }

  final yes = _safeProbability(json['yes_probability']);
  return [
    (yes - 0.1).clamp(0, 1).toDouble(),
    (yes - 0.05).clamp(0, 1).toDouble(),
    (yes - 0.02).clamp(0, 1).toDouble(),
    yes,
  ];
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

class TxUpdate {
  const TxUpdate({
    this.tradeId,
    this.txId,
    required this.marketId,
    required this.status,
    required this.txHash,
  });

  final int? tradeId;
  final int? txId;
  final int marketId;
  final String status;
  final String txHash;

  factory TxUpdate.fromJson(Map<String, dynamic> json) {
    return TxUpdate(
      tradeId: json['trade_id'] as int?,
      txId: json['tx_id'] as int?,
      marketId: json['market_id'] as int,
      status: json['status'] as String,
      txHash: json['tx_hash'] as String,
    );
  }
}

class CopilotRecommendation {
  const CopilotRecommendation({
    required this.action,
    required this.confidence,
    required this.risk,
    required this.reasoning,
    required this.positionSize,
    required this.sentimentTrend,
  });

  final String action;
  final int confidence;
  final String risk;
  final String reasoning;
  final String positionSize;
  final String sentimentTrend;

  factory CopilotRecommendation.fromJson(Map<String, dynamic> json) {
    return CopilotRecommendation(
      action: json['action'] as String,
      confidence: json['confidence'] as int,
      risk: json['risk'] as String,
      reasoning: json['reasoning'] as String,
      positionSize: json['position_size'] as String,
      sentimentTrend: (json['sentiment_trend'] ?? 'NEUTRAL') as String,
    );
  }
}

class PortfolioRiskSnapshot {
  const PortfolioRiskSnapshot({
    required this.totalExposure,
    required this.riskScore,
    required this.maxLoss,
    required this.var95,
    required this.volatilityScore,
    required this.confidenceWeightedRisk,
  });

  final double totalExposure;
  final String riskScore;
  final double maxLoss;
  final double var95;
  final double volatilityScore;
  final double confidenceWeightedRisk;

  factory PortfolioRiskSnapshot.fromJson(Map<String, dynamic> json) {
    return PortfolioRiskSnapshot(
      totalExposure: (json['total_exposure'] as num).toDouble(),
      riskScore: json['risk_score'] as String,
      maxLoss: (json['max_loss'] as num).toDouble(),
      var95: (json['var_95'] as num).toDouble(),
      volatilityScore: (json['volatility_score'] as num).toDouble(),
      confidenceWeightedRisk:
          (json['confidence_weighted_risk'] as num).toDouble(),
    );
  }
}

class WalletBalance {
  const WalletBalance({
    required this.symbol,
    required this.balance,
    required this.network,
    required this.priceUsd,
    required this.valueUsd,
  });
  final String symbol;
  final double balance;
  final String network;
  final double priceUsd;
  final double valueUsd;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      symbol: json['symbol'] as String,
      balance: (json['balance'] as num).toDouble(),
      network: json['network'] as String? ?? 'hashkey',
      priceUsd: (json['price_usd'] as num?)?.toDouble() ?? 0,
      valueUsd: (json['value_usd'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ExposureSlice {
  const ExposureSlice({required this.category, required this.allocation});

  final String category;
  final double allocation;

  factory ExposureSlice.fromJson(Map<String, dynamic> json) {
    return ExposureSlice(
      category: json['category'] as String,
      allocation: (json['allocation'] as num).toDouble(),
    );
  }
}

class PerformancePoint {
  const PerformancePoint({required this.label, required this.pnl});

  final String label;
  final double pnl;

  factory PerformancePoint.fromJson(Map<String, dynamic> json) {
    return PerformancePoint(
      label: json['label'] as String,
      pnl: (json['pnl'] as num).toDouble(),
    );
  }
}

class AppNotification {
  const AppNotification({required this.level, required this.message});

  final String level;
  final String message;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      level: json['level'] as String,
      message: json['message'] as String,
    );
  }
}

class PreparedTrade {
  const PreparedTrade({required this.tradeId, required this.tx});

  final int tradeId;
  final Map<String, dynamic> tx;

  factory PreparedTrade.fromJson(Map<String, dynamic> json) {
    return PreparedTrade(
      tradeId: json['trade_id'] as int,
      tx: json['tx'] as Map<String, dynamic>,
    );
  }
}

class TradeExecution {
  const TradeExecution({
    required this.id,
    required this.marketId,
    required this.side,
    required this.status,
    this.txHash,
  });

  final int id;
  final int marketId;
  final String side;
  final String status;
  final String? txHash;

  factory TradeExecution.fromJson(Map<String, dynamic> json) {
    return TradeExecution(
      id: json['id'] as int,
      marketId: json['market_id'] as int,
      side: json['side'] as String,
      status: json['status'] as String,
      txHash: json['tx_hash'] as String?,
    );
  }
}

class DisputeHistoryEntry {
  const DisputeHistoryEntry({
    required this.id,
    required this.marketId,
    required this.status,
    required this.evidenceUrl,
    required this.createdAt,
    this.txHash,
    this.chainStatus,
  });

  final int id;
  final int marketId;
  final String status;
  final String evidenceUrl;
  final String createdAt;
  final String? txHash;
  final String? chainStatus;

  factory DisputeHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DisputeHistoryEntry(
      id: json['id'] as int,
      marketId: json['market_id'] as int,
      status: json['status'] as String,
      evidenceUrl: json['evidence_url'] as String,
      createdAt: json['created_at'] as String,
      txHash: json['tx_hash'] as String?,
      chainStatus: json['chain_status'] as String?,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.score,
    required this.roi,
    required this.roi7d,
    required this.roi30d,
    required this.winRate,
    required this.lifetimeAccuracy,
    required this.copiedFollowers,
    required this.assetsCopied,
    required this.period,
  });

  final int rank;
  final int? userId;
  final String name;
  final double score;
  final double roi;
  final double roi7d;
  final double roi30d;
  final double winRate;
  final double lifetimeAccuracy;
  final int copiedFollowers;
  final double assetsCopied;
  final String period;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      roi: (json['roi'] as num).toDouble(),
      roi7d: (json['roi_7d'] as num?)?.toDouble() ?? 0,
      roi30d: (json['roi_30d'] as num?)?.toDouble() ?? 0,
      winRate: (json['win_rate'] as num).toDouble(),
      lifetimeAccuracy: (json['lifetime_accuracy'] as num?)?.toDouble() ?? 0,
      copiedFollowers: (json['copied_followers'] as num?)?.toInt() ?? 0,
      assetsCopied: (json['assets_copied'] as num?)?.toDouble() ?? 0,
      period: json['period'] as String,
    );
  }
}

class SentimentFeed {
  const SentimentFeed({
    required this.sentimentScore,
    required this.trend,
    required this.newsItems,
    required this.confidenceShift,
  });

  final double sentimentScore;
  final String trend;
  final List<NewsItem> newsItems;
  final int confidenceShift;

  factory SentimentFeed.fromJson(Map<String, dynamic> json) {
    final items = (json['news_items'] as List<dynamic>? ?? []);
    return SentimentFeed(
      sentimentScore: (json['sentiment_score'] as num).toDouble(),
      trend: json['trend'] as String,
      newsItems: items
          .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      confidenceShift: (json['confidence_shift'] as num).toInt(),
    );
  }
}

class NewsItem {
  const NewsItem({required this.headline, required this.source});

  final String headline;
  final String source;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      headline: json['headline'] as String,
      source: json['source'] as String,
    );
  }
}

class BundleModel {
  const BundleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.markets,
    required this.targetReturn,
    required this.riskLevel,
  });

  final String id;
  final String name;
  final String description;
  final String theme;
  final List<String> markets;
  final double targetReturn;
  final String riskLevel;

  factory BundleModel.fromJson(Map<String, dynamic> json) {
    return BundleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      theme: json['theme'] as String,
      markets: (json['markets'] as List<dynamic>).cast<String>(),
      targetReturn: (json['target_return'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
    );
  }
}

class InsuranceQuote {
  const InsuranceQuote({
    required this.positionId,
    required this.premiumBps,
    required this.coverageAmount,
    required this.eligibleRisks,
  });

  final String positionId;
  final int premiumBps;
  final double coverageAmount;
  final List<String> eligibleRisks;

  factory InsuranceQuote.fromJson(Map<String, dynamic> json) {
    return InsuranceQuote(
      positionId: json['position_id'] as String,
      premiumBps: json['premium_bps'] as int,
      coverageAmount: (json['coverage_amount'] as num).toDouble(),
      eligibleRisks: (json['eligible_risks'] as List<dynamic>).cast<String>(),
    );
  }
}

class AutoHedgePlan {
  const AutoHedgePlan({
    required this.enabled,
    required this.hedgeRatio,
    required this.protectionScore,
    required this.estimatedLossReduction,
  });

  final bool enabled;
  final double hedgeRatio;
  final int protectionScore;
  final double estimatedLossReduction;

  factory AutoHedgePlan.fromJson(Map<String, dynamic> json) {
    return AutoHedgePlan(
      enabled: json['enabled'] as bool,
      hedgeRatio: (json['hedge_ratio'] as num).toDouble(),
      protectionScore: json['protection_score'] as int,
      estimatedLossReduction:
          (json['estimated_loss_reduction'] as num).toDouble(),
    );
  }
}

class DiscussionComment {
  const DiscussionComment({
    required this.id,
    required this.marketId,
    required this.author,
    required this.content,
    required this.upvotes,
    this.evidenceUrl,
    this.parentId,
  });

  final int id;
  final int marketId;
  final String author;
  final String content;
  final int upvotes;
  final String? evidenceUrl;
  final int? parentId;

  factory DiscussionComment.fromJson(Map<String, dynamic> json) {
    return DiscussionComment(
      id: json['id'] as int,
      marketId: json['market_id'] as int,
      author: json['author'] as String,
      content: json['content'] as String,
      upvotes: json['upvotes'] as int,
      evidenceUrl: json['evidence_url'] as String?,
      parentId: json['parent_id'] as int?,
    );
  }
}

class VaultModel {
  const VaultModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.strategyDescription,
    required this.riskProfile,
    required this.collateralTokenDecimals,
    required this.autoExecuteEnabled,
    required this.targetMarkets,
    required this.performanceHistory,
    required this.currentAllocation,
    required this.aiConfidenceScore,
    required this.managerType,
    required this.roi7d,
    required this.roi30d,
    required this.winRate,
    required this.volatility,
    required this.activeSubscribers,
    required this.totalAum,
    required this.status,
    required this.smartLiquidity,
  });

  final int id;
  final String title;
  final String slug;
  final String strategyDescription;
  final String riskProfile;
  final int collateralTokenDecimals;
  final bool autoExecuteEnabled;
  final List<String> targetMarkets;
  final List<Map<String, dynamic>> performanceHistory;
  final Map<String, dynamic> currentAllocation;
  final double aiConfidenceScore;
  final String managerType;
  final double roi7d;
  final double roi30d;
  final double winRate;
  final double volatility;
  final int activeSubscribers;
  final double totalAum;
  final String status;
  final Map<String, dynamic> smartLiquidity;

  factory VaultModel.fromJson(Map<String, dynamic> json) {
    return VaultModel(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      strategyDescription: json['strategy_description'] as String,
      riskProfile: json['risk_profile'] as String,
      collateralTokenDecimals:
          (json['collateral_token_decimals'] as num?)?.toInt() ?? 18,
      autoExecuteEnabled: (json['auto_execute_enabled'] as bool?) ?? false,
      targetMarkets:
          (json['target_markets'] as List<dynamic>? ?? []).cast<String>(),
      performanceHistory: (json['performance_history'] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      currentAllocation:
          Map<String, dynamic>.from(json['current_allocation'] as Map? ?? {}),
      aiConfidenceScore: (json['ai_confidence_score'] as num).toDouble(),
      managerType: json['manager_type'] as String,
      roi7d: (json['roi_7d'] as num).toDouble(),
      roi30d: (json['roi_30d'] as num).toDouble(),
      winRate: (json['win_rate'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      activeSubscribers: (json['active_subscribers'] as num).toInt(),
      totalAum: (json['total_aum'] as num).toDouble(),
      status: json['status'] as String,
      smartLiquidity:
          Map<String, dynamic>.from(json['smart_liquidity'] as Map? ?? {}),
    );
  }
}

class VaultTrade {
  const VaultTrade({
    required this.id,
    required this.vaultId,
    required this.marketId,
    required this.side,
    required this.allocation,
    required this.amount,
    required this.price,
    required this.confidence,
    required this.reasoning,
    required this.status,
    required this.createdAt,
    this.txHash,
  });

  final int id;
  final int vaultId;
  final int marketId;
  final String side;
  final double allocation;
  final double amount;
  final double price;
  final double confidence;
  final String reasoning;
  final String status;
  final String createdAt;
  final String? txHash;

  factory VaultTrade.fromJson(Map<String, dynamic> json) {
    return VaultTrade(
      id: json['id'] as int,
      vaultId: json['vault_id'] as int,
      marketId: json['market_id'] as int,
      side: json['side'] as String,
      allocation: (json['allocation'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
      status: json['status'] as String,
      txHash: json['tx_hash'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class VaultPerformancePoint {
  const VaultPerformancePoint({
    required this.timestamp,
    required this.navPerShare,
    required this.aum,
    required this.roiPeriod,
    required this.winRate,
    required this.volatility,
    required this.confidence,
  });

  final String timestamp;
  final double navPerShare;
  final double aum;
  final double roiPeriod;
  final double winRate;
  final double volatility;
  final double confidence;

  factory VaultPerformancePoint.fromJson(Map<String, dynamic> json) {
    return VaultPerformancePoint(
      timestamp: json['timestamp'] as String,
      navPerShare: (json['nav_per_share'] as num).toDouble(),
      aum: (json['aum'] as num).toDouble(),
      roiPeriod: (json['roi_period'] as num).toDouble(),
      winRate: (json['win_rate'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class PredictFlowHealth {
  const PredictFlowHealth({
    required this.status,
    required this.service,
    required this.markets,
  });

  final String status;
  final String service;
  final int markets;

  factory PredictFlowHealth.fromJson(Map<String, dynamic> json) {
    return PredictFlowHealth(
      status: (json['status'] as String?) ?? 'unknown',
      service: (json['service'] as String?) ?? 'predictflow-dart',
      markets: _readInt(json['markets']) ?? 0,
    );
  }
}

class PredictFlowMarketSnapshot {
  const PredictFlowMarketSnapshot({
    required this.id,
    required this.title,
    required this.category,
    required this.yesPrice,
    required this.noPrice,
    required this.spreadTier,
    required this.liquidityUsd,
    required this.volume24h,
    required this.resolutionSource,
    required this.resolved,
  });

  final String id;
  final String title;
  final String category;
  final double yesPrice;
  final double noPrice;
  final String spreadTier;
  final double liquidityUsd;
  final double volume24h;
  final String resolutionSource;
  final bool resolved;

  factory PredictFlowMarketSnapshot.fromJson(Map<String, dynamic> json) {
    return PredictFlowMarketSnapshot(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Untitled market',
      category: (json['category'] as String?) ?? 'Prediction',
      yesPrice: (_readDouble(json['yesPrice']) ?? 0.5).toDouble(),
      noPrice: (_readDouble(json['noPrice']) ?? 0.5).toDouble(),
      spreadTier: (json['spreadTier'] as String?) ?? 'UNKNOWN',
      liquidityUsd: (_readDouble(json['liquidityUsd']) ?? 0).toDouble(),
      volume24h: (_readDouble(json['volume24h']) ?? 0).toDouble(),
      resolutionSource:
          (json['resolutionSource'] as String?) ?? 'PredictFlow engine',
      resolved: (json['resolved'] as bool?) ?? false,
    );
  }
}

class PredictFlowPosition {
  const PredictFlowPosition({
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
  final String outcome;
  final double shares;
  final double avgEntry;
  final double markPrice;
  final double unrealizedPnl;

  factory PredictFlowPosition.fromJson(Map<String, dynamic> json) {
    return PredictFlowPosition(
      marketId: (json['marketId'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Untitled market',
      outcome: (json['outcome'] as String?) ?? 'YES',
      shares: (_readDouble(json['shares']) ?? 0).toDouble(),
      avgEntry: (_readDouble(json['avgEntry']) ?? 0).toDouble(),
      markPrice: (_readDouble(json['markPrice']) ?? 0).toDouble(),
      unrealizedPnl: (_readDouble(json['unrealizedPnl']) ?? 0).toDouble(),
    );
  }
}

class PredictFlowPortfolio {
  const PredictFlowPortfolio({
    required this.wallet,
    required this.collateralBalance,
    required this.realizedPnl,
    required this.positions,
  });

  final String wallet;
  final double collateralBalance;
  final double realizedPnl;
  final List<PredictFlowPosition> positions;

  factory PredictFlowPortfolio.fromJson(Map<String, dynamic> json) {
    return PredictFlowPortfolio(
      wallet: (json['wallet'] as String?) ?? 'predictflow-wallet',
      collateralBalance: (_readDouble(json['collateralBalance']) ?? 0).toDouble(),
      realizedPnl: (_readDouble(json['realizedPnl']) ?? 0).toDouble(),
      positions: (json['positions'] as List<dynamic>? ?? [])
          .map((item) => PredictFlowPosition.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class PredictFlowPreview {
  const PredictFlowPreview({
    required this.sharesOut,
    required this.avgPrice,
    required this.priceImpact,
    required this.collateralOut,
  });

  final double sharesOut;
  final double avgPrice;
  final double priceImpact;
  final double collateralOut;

  factory PredictFlowPreview.fromJson(Map<String, dynamic> json) {
    return PredictFlowPreview(
      sharesOut: (_readDouble(json['sharesOut']) ?? 0).toDouble(),
      avgPrice: (_readDouble(json['avgPrice']) ?? 0).toDouble(),
      priceImpact: (_readDouble(json['priceImpact']) ?? 0).toDouble(),
      collateralOut: (_readDouble(json['collateralOut']) ?? 0).toDouble(),
    );
  }
}

class PredictFlowOrderResult {
  const PredictFlowOrderResult({
    required this.orderId,
    required this.marketId,
    required this.fillCount,
    required this.wallet,
    required this.snapshot,
  });

  final String orderId;
  final String marketId;
  final int fillCount;
  final String wallet;
  final PredictFlowMarketSnapshot snapshot;

  factory PredictFlowOrderResult.fromJson(Map<String, dynamic> json) {
    final order = Map<String, dynamic>.from((json['order'] as Map?) ?? const {});
    final snapshot = Map<String, dynamic>.from((json['snapshot'] as Map?) ?? const {});
    return PredictFlowOrderResult(
      orderId: (order['id'] as String?) ?? '',
      marketId: (order['marketId'] as String?) ?? '',
      fillCount: (json['fills'] as List<dynamic>? ?? const []).length,
      wallet: (order['wallet'] as String?) ?? '',
      snapshot: PredictFlowMarketSnapshot.fromJson(snapshot),
    );
  }
}

class CopyRelationshipModel {
  const CopyRelationshipModel({
    required this.id,
    required this.followerUserId,
    required this.sourceUserId,
    required this.sourceType,
    required this.status,
    required this.allocationPct,
    required this.maxLossPct,
    required this.riskLevel,
    required this.autoStopThreshold,
    required this.maxFollowerExposure,
    required this.traderCommissionBps,
    required this.platformFeeBps,
    required this.allowedMarketIds,
  });

  final int id;
  final int followerUserId;
  final int sourceUserId;
  final String sourceType;
  final String status;
  final double allocationPct;
  final double maxLossPct;
  final String riskLevel;
  final double autoStopThreshold;
  final double maxFollowerExposure;
  final int traderCommissionBps;
  final int platformFeeBps;
  final List<int> allowedMarketIds;

  factory CopyRelationshipModel.fromJson(Map<String, dynamic> json) {
    return CopyRelationshipModel(
      id: json['id'] as int,
      followerUserId: json['follower_user_id'] as int,
      sourceUserId: json['source_user_id'] as int,
      sourceType: json['source_type'] as String,
      status: json['status'] as String,
      allocationPct: (json['allocation_pct'] as num).toDouble(),
      maxLossPct: (json['max_loss_pct'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      autoStopThreshold: (json['auto_stop_threshold'] as num).toDouble(),
      maxFollowerExposure: (json['max_follower_exposure'] as num).toDouble(),
      traderCommissionBps: (json['trader_commission_bps'] as num).toInt(),
      platformFeeBps: (json['platform_fee_bps'] as num).toInt(),
      allowedMarketIds:
          (json['allowed_market_ids'] as List<dynamic>? ?? []).cast<int>(),
    );
  }
}

class CopiedTradeModel {
  const CopiedTradeModel({
    required this.id,
    required this.relationshipId,
    required this.sourceTradeId,
    required this.marketId,
    required this.copiedAllocation,
    required this.copiedAmount,
    required this.status,
    required this.createdAt,
    this.followerTradeId,
    this.reason,
  });

  final int id;
  final int relationshipId;
  final int sourceTradeId;
  final int? followerTradeId;
  final int marketId;
  final double copiedAllocation;
  final double copiedAmount;
  final String status;
  final String createdAt;
  final String? reason;

  factory CopiedTradeModel.fromJson(Map<String, dynamic> json) {
    return CopiedTradeModel(
      id: json['id'] as int,
      relationshipId: json['relationship_id'] as int,
      sourceTradeId: json['source_trade_id'] as int,
      followerTradeId: json['follower_trade_id'] as int?,
      marketId: json['market_id'] as int,
      copiedAllocation: (json['copied_allocation'] as num).toDouble(),
      copiedAmount: (json['copied_amount'] as num).toDouble(),
      status: json['status'] as String,
      reason: json['reason'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class CopyPerformanceSnapshotModel {
  const CopyPerformanceSnapshotModel({
    required this.timestamp,
    required this.roi7d,
    required this.roi30d,
    required this.lifetimeAccuracy,
    required this.copiedFollowers,
    required this.assetsCopied,
    required this.drawdownPct,
  });

  final String timestamp;
  final double roi7d;
  final double roi30d;
  final double lifetimeAccuracy;
  final int copiedFollowers;
  final double assetsCopied;
  final double drawdownPct;

  factory CopyPerformanceSnapshotModel.fromJson(Map<String, dynamic> json) {
    return CopyPerformanceSnapshotModel(
      timestamp: json['timestamp'] as String,
      roi7d: (json['roi_7d'] as num).toDouble(),
      roi30d: (json['roi_30d'] as num).toDouble(),
      lifetimeAccuracy: (json['lifetime_accuracy'] as num).toDouble(),
      copiedFollowers: (json['copied_followers'] as num).toInt(),
      assetsCopied: (json['assets_copied'] as num).toDouble(),
      drawdownPct: (json['drawdown_pct'] as num).toDouble(),
    );
  }
}

class CopyPortfolioSummaryModel {
  const CopyPortfolioSummaryModel({
    required this.copiedTraders,
    required this.liveCopiedPositions,
    required this.copiedRoi,
    required this.activeAlerts,
    required this.performanceByTrader,
  });

  final int copiedTraders;
  final int liveCopiedPositions;
  final double copiedRoi;
  final int activeAlerts;
  final List<Map<String, dynamic>> performanceByTrader;

  factory CopyPortfolioSummaryModel.fromJson(Map<String, dynamic> json) {
    return CopyPortfolioSummaryModel(
      copiedTraders: (json['copied_traders'] as num).toInt(),
      liveCopiedPositions: (json['live_copied_positions'] as num).toInt(),
      copiedRoi: (json['copied_roi'] as num).toDouble(),
      activeAlerts: (json['active_alerts'] as num).toInt(),
      performanceByTrader:
          (json['performance_by_trader'] as List<dynamic>? ?? [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
    );
  }
}
