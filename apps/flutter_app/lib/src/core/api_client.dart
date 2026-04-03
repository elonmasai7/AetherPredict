import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'constants.dart';
import 'models.dart';

class ApiClient {
  const ApiClient();

  Future<List<Market>> fetchMarkets() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/markets'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => Market.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<AgentCardModel>> fetchAgents() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/agents'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => AgentCardModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<PortfolioPosition>> fetchPortfolio() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/portfolio/positions'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => PortfolioPosition.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<PortfolioRiskSnapshot> fetchRisk() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/portfolio/risk'));
    return PortfolioRiskSnapshot.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<ExposureSlice>> fetchExposure() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/portfolio/exposure'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => ExposureSlice.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<PerformancePoint>> fetchPerformance() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/portfolio/performance'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => PerformancePoint.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CopilotRecommendation> fetchCopilot(String marketId, String walletAddress) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/ai/copilot/recommendation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'market_id': marketId,
        'wallet_address': walletAddress,
        'portfolio_data': {},
      }),
    );
    return CopilotRecommendation.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<SentimentFeed> fetchSentimentFeed(String marketId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/ai/market/sentiment-feed'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'market_id': marketId}),
    );
    return SentimentFeed.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/notifications/history'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String type) async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/leaderboard/$type'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<BundleModel>> fetchBundles() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/bundles'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => BundleModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<InsuranceQuote> fetchInsuranceQuote(String positionId) async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/insurance/quote?position_id=$positionId'));
    return InsuranceQuote.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<AutoHedgePlan> fetchAutoHedge(String marketId, double positionSize, {bool enable = true}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/portfolio/auto-hedge'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'market_id': marketId,
        'current_side': 'YES',
        'position_size': positionSize,
        'enable': enable,
      }),
    );
    return AutoHedgePlan.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<DiscussionComment>> fetchComments(int marketId) async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/market/comments?market_id=$marketId'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => DiscussionComment.fromJson(item as Map<String, dynamic>)).toList();
  }

  Stream<LiveMarketUpdate> marketUpdates() {
    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsMarketsUrl));
    return channel.stream.map((event) {
      final payload = jsonDecode(event as String) as Map<String, dynamic>;
      return LiveMarketUpdate.fromJson(payload);
    });
  }
}
