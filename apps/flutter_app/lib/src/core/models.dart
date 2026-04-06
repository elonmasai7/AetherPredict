class Market {
  const Market({
    required this.id,
    required this.title,
    required this.category,
    required this.oracleSource,
    required this.yesProbability,
    required this.aiConfidence,
    required this.volume,
    required this.liquidity,
    required this.points,
  });

  final String id;
  final String title;
  final String category;
  final String oracleSource;
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
      oracleSource: (json['oracle_source'] ?? '') as String,
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
      confidenceWeightedRisk: (json['confidence_weighted_risk'] as num).toDouble(),
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

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.roi,
    required this.winRate,
    required this.period,
  });

  final int rank;
  final String name;
  final double score;
  final double roi;
  final double winRate;
  final String period;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      roi: (json['roi'] as num).toDouble(),
      winRate: (json['win_rate'] as num).toDouble(),
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
      newsItems: items.map((item) => NewsItem.fromJson(item as Map<String, dynamic>)).toList(),
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
      estimatedLossReduction: (json['estimated_loss_reduction'] as num).toDouble(),
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
