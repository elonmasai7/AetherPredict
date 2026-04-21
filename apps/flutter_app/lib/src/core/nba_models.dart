class PlatformHomeModel {
  const PlatformHomeModel({
    required this.generatedAt,
    required this.overview,
    required this.featuredMarketId,
    required this.liveGames,
    required this.markets,
    required this.news,
    required this.agents,
    required this.leaderboard,
    required this.activityFeed,
    required this.recentPredictions,
  });

  final DateTime generatedAt;
  final NbaOverview overview;
  final int? featuredMarketId;
  final List<NbaLiveGame> liveGames;
  final List<NbaMarket> markets;
  final List<NbaNewsItem> news;
  final List<NbaAgent> agents;
  final List<NbaLeaderboardEntry> leaderboard;
  final List<NbaPredictionActivity> activityFeed;
  final List<NbaPredictionActivity> recentPredictions;

  factory PlatformHomeModel.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final rows = json[key] as List<dynamic>? ?? const [];
      return rows
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return PlatformHomeModel(
      generatedAt: DateTime.parse(json['generated_at'] as String),
      overview: NbaOverview.fromJson(
        Map<String, dynamic>.from(json['overview'] as Map),
      ),
      featuredMarketId: json['featured_market_id'] as int?,
      liveGames: parseList('live_games', NbaLiveGame.fromJson),
      markets: parseList('markets', NbaMarket.fromJson),
      news: parseList('news', NbaNewsItem.fromJson),
      agents: parseList('agents', NbaAgent.fromJson),
      leaderboard: parseList('leaderboard', NbaLeaderboardEntry.fromJson),
      activityFeed: parseList('activity_feed', NbaPredictionActivity.fromJson),
      recentPredictions:
          parseList('recent_predictions', NbaPredictionActivity.fromJson),
    );
  }
}

class NbaOverview {
  const NbaOverview({
    required this.activeMarkets,
    required this.liveGames,
    required this.modelAccuracy,
    required this.totalLiquidity,
    required this.openPredictions,
    required this.predictionRoi,
  });

  final int activeMarkets;
  final int liveGames;
  final double modelAccuracy;
  final double totalLiquidity;
  final int openPredictions;
  final double predictionRoi;

  factory NbaOverview.fromJson(Map<String, dynamic> json) {
    return NbaOverview(
      activeMarkets: (json['active_markets'] as num).toInt(),
      liveGames: (json['live_games'] as num).toInt(),
      modelAccuracy: (json['model_accuracy'] as num).toDouble(),
      totalLiquidity: (json['total_liquidity'] as num).toDouble(),
      openPredictions: (json['open_predictions'] as num).toInt(),
      predictionRoi: (json['prediction_roi'] as num).toDouble(),
    );
  }
}

class NbaLiveGame {
  const NbaLiveGame({
    required this.gameId,
    required this.id,
    required this.matchup,
    required this.status,
    required this.tipoffTime,
    required this.startTime,
    required this.teamA,
    required this.teamB,
    required this.teamAId,
    required this.teamBId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.winProbabilityHome,
    required this.pace,
    required this.headline,
  });

  final String gameId;
  final String id;
  final String matchup;
  final String status;
  final DateTime tipoffTime;
  final DateTime startTime;
  final String teamA;
  final String teamB;
  final String teamAId;
  final String teamBId;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final double winProbabilityHome;
  final double pace;
  final String headline;

  factory NbaLiveGame.fromJson(Map<String, dynamic> json) {
    return NbaLiveGame(
      gameId: json['game_id'] as String,
      id: (json['id'] as String?) ?? json['game_id'] as String,
      matchup: json['matchup'] as String,
      status: json['status'] as String,
      tipoffTime: DateTime.parse(json['tipoff_time'] as String),
      startTime: DateTime.parse(
        (json['start_time'] as String?) ?? json['tipoff_time'] as String,
      ),
      teamA: (json['team_a'] as String?) ?? json['home_team'] as String,
      teamB: (json['team_b'] as String?) ?? json['away_team'] as String,
      teamAId: (json['team_a_id'] as String?) ?? 'home',
      teamBId: (json['team_b_id'] as String?) ?? 'away',
      homeTeam: json['home_team'] as String,
      awayTeam: json['away_team'] as String,
      homeScore: (json['home_score'] as num).toInt(),
      awayScore: (json['away_score'] as num).toInt(),
      winProbabilityHome: (json['win_probability_home'] as num).toDouble(),
      pace: (json['pace'] as num).toDouble(),
      headline: json['headline'] as String,
    );
  }
}

class NbaNewsItem {
  const NbaNewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.publishedAt,
    required this.urgency,
    required this.tag,
    this.team,
    this.player,
  });

  final String id;
  final String title;
  final String summary;
  final String source;
  final String url;
  final DateTime publishedAt;
  final String urgency;
  final String tag;
  final String? team;
  final String? player;

  factory NbaNewsItem.fromJson(Map<String, dynamic> json) {
    return NbaNewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      source: json['source'] as String,
      url: json['url'] as String? ?? '',
      publishedAt: DateTime.parse(json['published_at'] as String),
      urgency: json['urgency'] as String,
      tag: json['tag'] as String,
      team: json['team'] as String?,
      player: json['player'] as String?,
    );
  }
}

class NbaAgent {
  const NbaAgent({
    required this.key,
    required this.name,
    required this.specialty,
    required this.status,
    required this.confidence,
    required this.historicalAccuracy,
    required this.roi,
    required this.activeMarkets,
    required this.summary,
    required this.recommendation,
  });

  final String key;
  final String name;
  final String specialty;
  final String status;
  final double confidence;
  final double historicalAccuracy;
  final double roi;
  final int activeMarkets;
  final String summary;
  final String recommendation;

  factory NbaAgent.fromJson(Map<String, dynamic> json) {
    return NbaAgent(
      key: json['key'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      status: json['status'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      historicalAccuracy: (json['historical_accuracy'] as num).toDouble(),
      roi: (json['roi'] as num).toDouble(),
      activeMarkets: (json['active_markets'] as num).toInt(),
      summary: json['summary'] as String,
      recommendation: json['recommendation'] as String,
    );
  }
}

class NbaLeaderboardEntry {
  const NbaLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.accuracy,
    required this.roi,
    required this.consistency,
    required this.predictions,
    required this.streak,
  });

  final int rank;
  final String name;
  final double accuracy;
  final double roi;
  final double consistency;
  final int predictions;
  final int streak;

  factory NbaLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return NbaLeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      name: json['name'] as String,
      accuracy: (json['accuracy'] as num).toDouble(),
      roi: (json['roi'] as num).toDouble(),
      consistency: (json['consistency'] as num).toDouble(),
      predictions: (json['predictions'] as num).toInt(),
      streak: (json['streak'] as num).toInt(),
    );
  }
}

class NbaMarket {
  const NbaMarket({
    required this.id,
    required this.slug,
    required this.title,
    required this.marketType,
    required this.category,
    required this.matchup,
    required this.primarySubject,
    required this.yesLabel,
    required this.noLabel,
    required this.yesProbability,
    required this.noProbability,
    required this.aiConfidence,
    required this.volume,
    required this.liquidity,
    required this.spreadBps,
    required this.depth,
    required this.slippage,
    required this.liquidityScore,
    required this.teamForm,
    required this.playerContext,
    required this.probabilityPoints,
    required this.aiInsight,
    required this.latestNews,
    required this.expiresAt,
    required this.confidenceLabel,
  });

  final int id;
  final String slug;
  final String title;
  final String marketType;
  final String category;
  final String matchup;
  final String primarySubject;
  final String yesLabel;
  final String noLabel;
  final double yesProbability;
  final double noProbability;
  final double aiConfidence;
  final double volume;
  final double liquidity;
  final double spreadBps;
  final double depth;
  final double slippage;
  final double liquidityScore;
  final Map<String, dynamic> teamForm;
  final Map<String, dynamic> playerContext;
  final List<double> probabilityPoints;
  final String aiInsight;
  final List<NbaNewsItem> latestNews;
  final DateTime expiresAt;
  final String confidenceLabel;

  factory NbaMarket.fromJson(Map<String, dynamic> json) {
    final news = json['latest_news'] as List<dynamic>? ?? const [];
    final points = json['probability_points'] as List<dynamic>? ?? const [];
    return NbaMarket(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String,
      title: json['title'] as String,
      marketType: json['market_type'] as String,
      category: json['category'] as String,
      matchup: json['matchup'] as String,
      primarySubject: json['primary_subject'] as String,
      yesLabel: json['yes_label'] as String,
      noLabel: json['no_label'] as String,
      yesProbability: (json['yes_probability'] as num).toDouble(),
      noProbability: (json['no_probability'] as num).toDouble(),
      aiConfidence: (json['ai_confidence'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      liquidity: (json['liquidity'] as num).toDouble(),
      spreadBps: (json['spread_bps'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      slippage: (json['slippage'] as num).toDouble(),
      liquidityScore: (json['liquidity_score'] as num).toDouble(),
      teamForm: Map<String, dynamic>.from(
        json['team_form'] as Map? ?? const {},
      ),
      playerContext: Map<String, dynamic>.from(
        json['player_context'] as Map? ?? const {},
      ),
      probabilityPoints: points
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
      aiInsight: json['ai_insight'] as String,
      latestNews: news
          .map((item) =>
              NbaNewsItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      confidenceLabel: json['confidence_label'] as String,
    );
  }
}

class NbaTeam {
  const NbaTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.conference,
    required this.color,
    required this.accent,
    required this.logoText,
    required this.winPct,
    required this.lastFive,
  });

  final String id;
  final String name;
  final String shortName;
  final String conference;
  final String color;
  final String accent;
  final String logoText;
  final double winPct;
  final String lastFive;

  factory NbaTeam.fromJson(Map<String, dynamic> json) {
    return NbaTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String,
      conference: json['conference'] as String,
      color: json['color'] as String,
      accent: json['accent'] as String,
      logoText: json['logo_text'] as String,
      winPct: (json['win_pct'] as num).toDouble(),
      lastFive: json['last_five'] as String,
    );
  }
}

class NbaPlayer {
  const NbaPlayer({
    required this.id,
    required this.name,
    required this.teamId,
    required this.teamName,
    required this.position,
    required this.statsJson,
  });

  final String id;
  final String name;
  final String teamId;
  final String teamName;
  final String position;
  final Map<String, dynamic> statsJson;

  factory NbaPlayer.fromJson(Map<String, dynamic> json) {
    return NbaPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
      position: json['position'] as String,
      statsJson: Map<String, dynamic>.from(
        json['stats_json'] as Map? ?? const {},
      ),
    );
  }
}

class NbaPredictionActivity {
  const NbaPredictionActivity({
    required this.id,
    required this.user,
    required this.market,
    required this.pick,
    required this.confidence,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String user;
  final String market;
  final String pick;
  final String confidence;
  final double amount;
  final DateTime createdAt;

  factory NbaPredictionActivity.fromJson(Map<String, dynamic> json) {
    return NbaPredictionActivity(
      id: json['id'] as String,
      user: json['user'] as String,
      market: json['market'] as String,
      pick: json['pick'] as String,
      confidence: json['confidence'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class StrategyPreviewModel {
  const StrategyPreviewModel({
    required this.title,
    required this.summary,
    required this.probability,
    required this.confidence,
    required this.executionReady,
    required this.rationale,
    required this.safeguards,
    this.suggestedMarketId,
  });

  final String title;
  final String summary;
  final double probability;
  final double confidence;
  final bool executionReady;
  final int? suggestedMarketId;
  final List<String> rationale;
  final List<String> safeguards;

  factory StrategyPreviewModel.fromJson(Map<String, dynamic> json) {
    return StrategyPreviewModel(
      title: json['title'] as String,
      summary: json['summary'] as String,
      probability: (json['probability'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      executionReady: json['execution_ready'] as bool? ?? false,
      suggestedMarketId: json['suggested_market_id'] as int?,
      rationale: (json['rationale'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      safeguards: (json['safeguards'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class AiPredictionModel {
  const AiPredictionModel({
    required this.marketId,
    required this.probability,
    required this.confidence,
    required this.predictedSide,
    required this.reasoning,
    required this.suggestedAmount,
    this.impactLevel,
  });

  final int? marketId;
  final double probability;
  final double confidence;
  final String predictedSide;
  final List<String> reasoning;
  final double suggestedAmount;
  final String? impactLevel;

  factory AiPredictionModel.fromJson(Map<String, dynamic> json) {
    return AiPredictionModel(
      marketId: json['market_id'] as int?,
      probability: (json['probability'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      predictedSide: json['predicted_side'] as String,
      reasoning: (json['reasoning'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      suggestedAmount: (json['suggested_amount'] as num).toDouble(),
      impactLevel: json['impact_level'] as String?,
    );
  }
}

class LiquidityBookModel {
  const LiquidityBookModel({
    required this.marketId,
    required this.liquidity,
    required this.spread,
    required this.depth,
    required this.slippage,
    required this.liquidityScore,
    required this.bids,
    required this.asks,
  });

  final int marketId;
  final double liquidity;
  final double spread;
  final double depth;
  final double slippage;
  final double liquidityScore;
  final List<Map<String, dynamic>> bids;
  final List<Map<String, dynamic>> asks;

  factory LiquidityBookModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
    return LiquidityBookModel(
      marketId: (json['market_id'] as num).toInt(),
      liquidity: (json['liquidity'] as num).toDouble(),
      spread: (json['spread'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      slippage: (json['slippage'] as num).toDouble(),
      liquidityScore: (json['liquidity_score'] as num).toDouble(),
      bids: rows('bids'),
      asks: rows('asks'),
    );
  }
}
