import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'constants.dart';
import 'models.dart';

class ApiClient {
  const ApiClient();

  Future<List<Market>> fetchMarkets() async {
    final response = await _get('/markets');
    final payload = _decodeList(response, endpoint: '/markets');
    return payload.map((item) => Market.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<AgentCardModel>> fetchAgents() async {
    final response = await _get('/agents');
    final payload = _decodeList(response, endpoint: '/agents');
    return payload.map((item) => AgentCardModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<PortfolioPosition>> fetchPortfolio() async {
    final response = await _get('/portfolio/positions');
    final payload = _decodeList(response, endpoint: '/portfolio/positions');
    return payload.map((item) => PortfolioPosition.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<PortfolioRiskSnapshot> fetchRisk() async {
    final response = await _get('/portfolio/risk');
    return PortfolioRiskSnapshot.fromJson(_decodeMap(response, endpoint: '/portfolio/risk'));
  }

  Future<List<ExposureSlice>> fetchExposure() async {
    final response = await _get('/portfolio/exposure');
    final payload = _decodeList(response, endpoint: '/portfolio/exposure');
    return payload.map((item) => ExposureSlice.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<PerformancePoint>> fetchPerformance() async {
    final response = await _get('/portfolio/performance');
    final payload = _decodeList(response, endpoint: '/portfolio/performance');
    return payload.map((item) => PerformancePoint.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CopilotRecommendation> fetchCopilot(String marketId, String walletAddress) async {
    final response = await _post(
      '/ai/copilot/recommendation',
      {
        'market_id': marketId,
        'wallet_address': walletAddress,
        'portfolio_data': {},
      },
    );
    return CopilotRecommendation.fromJson(_decodeMap(response, endpoint: '/ai/copilot/recommendation'));
  }

  Future<SentimentFeed> fetchSentimentFeed(String marketId) async {
    final response = await _post('/ai/market/sentiment-feed', {'market_id': marketId});
    return SentimentFeed.fromJson(_decodeMap(response, endpoint: '/ai/market/sentiment-feed'));
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _get('/notifications/history');
    final payload = _decodeList(response, endpoint: '/notifications/history');
    return payload.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String type) async {
    final response = await _get('/leaderboard/$type');
    final payload = _decodeList(response, endpoint: '/leaderboard/$type');
    return payload.map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<BundleModel>> fetchBundles() async {
    final response = await _get('/bundles');
    final payload = _decodeList(response, endpoint: '/bundles');
    return payload.map((item) => BundleModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<InsuranceQuote> fetchInsuranceQuote(String positionId) async {
    final response = await _get('/insurance/quote?position_id=$positionId');
    return InsuranceQuote.fromJson(_decodeMap(response, endpoint: '/insurance/quote'));
  }

  Future<AutoHedgePlan> fetchAutoHedge(String marketId, double positionSize, {bool enable = true}) async {
    final response = await _post(
      '/portfolio/auto-hedge',
      {
        'market_id': marketId,
        'current_side': 'YES',
        'position_size': positionSize,
        'enable': enable,
      },
    );
    return AutoHedgePlan.fromJson(_decodeMap(response, endpoint: '/portfolio/auto-hedge'));
  }

  Future<List<DiscussionComment>> fetchComments(int marketId) async {
    final response = await _get('/market/comments?market_id=$marketId');
    final payload = _decodeList(response, endpoint: '/market/comments');
    return payload.map((item) => DiscussionComment.fromJson(item as Map<String, dynamic>)).toList();
  }

  Stream<LiveMarketUpdate> marketUpdates() {
    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsMarketsUrl));
    return channel.stream.map((event) {
      try {
        final payload = jsonDecode(event as String) as Map<String, dynamic>;
        return LiveMarketUpdate.fromJson(payload);
      } catch (_) {
        throw ApiException('Invalid websocket payload from ${AppConfig.wsMarketsUrl}');
      }
    });
  }

  Future<http.Response> _get(String endpoint) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      _ensureSuccess(response, endpoint: endpoint);
      return response;
    } on SocketException {
      throw ApiException('Cannot reach server at ${uri.host}:${uri.port}');
    } on HttpException catch (error) {
      throw ApiException('Network error on $endpoint: $error');
    } on FormatException {
      throw ApiException('Malformed URL for endpoint $endpoint');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Unexpected request failure on $endpoint: $error');
    }
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      _ensureSuccess(response, endpoint: endpoint);
      return response;
    } on SocketException {
      throw ApiException('Cannot reach server at ${uri.host}:${uri.port}');
    } on HttpException catch (error) {
      throw ApiException('Network error on $endpoint: $error');
    } on FormatException {
      throw ApiException('Malformed URL for endpoint $endpoint');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Unexpected request failure on $endpoint: $error');
    }
  }

  void _ensureSuccess(http.Response response, {required String endpoint}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = response.body.trim();
    final detail = body.isEmpty
        ? 'empty response body'
        : body.length > 180
            ? '${body.substring(0, 180)}...'
            : body;
    throw ApiException('Request failed ($endpoint): HTTP ${response.statusCode} - $detail');
  }

  Map<String, dynamic> _decodeMap(http.Response response, {required String endpoint}) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw ApiException('Expected JSON object from $endpoint');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('Invalid JSON object from $endpoint');
    }
  }

  List<dynamic> _decodeList(http.Response response, {required String endpoint}) {
    try {
      final data = jsonDecode(response.body);
      if (data is List<dynamic>) {
        return data;
      }
      throw ApiException('Expected JSON array from $endpoint');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('Invalid JSON array from $endpoint');
    }
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
