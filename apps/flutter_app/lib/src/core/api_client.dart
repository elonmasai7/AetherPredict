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

  Future<List<VaultModel>> fetchVaults({String? category}) async {
    final suffix = category == null ? '' : '?category=$category';
    final response = await _get('/vaults$suffix');
    final payload = _decodeList(response, endpoint: '/vaults');
    return payload.map((item) => VaultModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<VaultModel> fetchVaultById(int id) async {
    final response = await _get('/vaults/$id');
    return VaultModel.fromJson(_decodeMap(response, endpoint: '/vaults/$id'));
  }

  Future<List<VaultTrade>> fetchVaultTrades(int vaultId) async {
    final response = await _get('/vaults/$vaultId/trades');
    final payload = _decodeList(response, endpoint: '/vaults/$vaultId/trades');
    return payload.map((item) => VaultTrade.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<VaultPerformancePoint>> fetchVaultPerformance(int vaultId) async {
    final response = await _get('/vaults/$vaultId/performance');
    final payload = _decodeList(response, endpoint: '/vaults/$vaultId/performance');
    return payload.map((item) => VaultPerformancePoint.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> depositVault({
    required int vaultId,
    required String walletAddress,
    required double amount,
  }) async {
    final response = await _post('/vaults/deposit', {
      'vault_id': vaultId,
      'wallet_address': walletAddress,
      'amount': amount,
    });
    return _decodeMap(response, endpoint: '/vaults/deposit');
  }

  Future<Map<String, dynamic>> withdrawVault({
    required int vaultId,
    required String walletAddress,
    required double amount,
  }) async {
    final response = await _post('/vaults/withdraw', {
      'vault_id': vaultId,
      'wallet_address': walletAddress,
      'amount': amount,
    });
    return _decodeMap(response, endpoint: '/vaults/withdraw');
  }

  Future<CopyRelationshipModel> followTrader(Map<String, dynamic> payload) async {
    final response = await _post('/copy-trading/follow', payload);
    return CopyRelationshipModel.fromJson(_decodeMap(response, endpoint: '/copy-trading/follow'));
  }

  Future<CopyRelationshipModel> unfollowTrader(int sourceUserId) async {
    final response = await _post('/copy-trading/unfollow/$sourceUserId', {});
    return CopyRelationshipModel.fromJson(_decodeMap(response, endpoint: '/copy-trading/unfollow'));
  }

  Future<CopyRelationshipModel> updateCopySettings(int relationshipId, Map<String, dynamic> payload) async {
    final response = await _patch('/copy-trading/settings/$relationshipId', payload);
    return CopyRelationshipModel.fromJson(_decodeMap(response, endpoint: '/copy-trading/settings/$relationshipId'));
  }

  Future<List<CopyRelationshipModel>> fetchCopyRelationships() async {
    final response = await _get('/copy-trading/relationships');
    final payload = _decodeList(response, endpoint: '/copy-trading/relationships');
    return payload.map((item) => CopyRelationshipModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<CopiedTradeModel>> fetchCopiedTrades() async {
    final response = await _get('/copy-trading/copied-trades');
    final payload = _decodeList(response, endpoint: '/copy-trading/copied-trades');
    return payload.map((item) => CopiedTradeModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<CopyPerformanceSnapshotModel>> fetchCopyPerformance(int relationshipId) async {
    final response = await _get('/copy-trading/performance/$relationshipId');
    final payload = _decodeList(response, endpoint: '/copy-trading/performance/$relationshipId');
    return payload.map((item) => CopyPerformanceSnapshotModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CopyRelationshipModel> stopCopying(int relationshipId) async {
    final response = await _post('/copy-trading/stop/$relationshipId', {});
    return CopyRelationshipModel.fromJson(_decodeMap(response, endpoint: '/copy-trading/stop/$relationshipId'));
  }

  Future<CopyPortfolioSummaryModel> fetchCopyPortfolioSummary() async {
    final response = await _get('/copy-trading/portfolio');
    return CopyPortfolioSummaryModel.fromJson(_decodeMap(response, endpoint: '/copy-trading/portfolio'));
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
    return channel.stream
        .map((event) => jsonDecode(event as String) as Map<String, dynamic>)
        .where((payload) => payload['type'] != 'tx')
        .map((payload) => LiveMarketUpdate.fromJson(payload));
  }

  Stream<TxUpdate> txUpdates() {
    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsTxUrl));
    return channel.stream
        .map((event) => jsonDecode(event as String) as Map<String, dynamic>)
        .where((payload) => payload['type'] == 'tx')
        .map((payload) => TxUpdate.fromJson(payload));
  }

  Stream<Map<String, dynamic>> vaultUpdates() {
    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsVaultsUrl));
    return channel.stream.map((event) => jsonDecode(event as String) as Map<String, dynamic>);
  }

  Stream<Map<String, dynamic>> copyUpdates() {
    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsCopyUrl));
    return channel.stream.map((event) => jsonDecode(event as String) as Map<String, dynamic>);
  }

  Future<PreparedTrade> prepareTrade({
    required String marketId,
    required String side,
    required double collateralAmount,
    required String walletAddress,
  }) async {
    final response = await _post('/trades/prepare', {
      'market_id': int.parse(marketId),
      'side': side,
      'collateral_amount': collateralAmount,
      'wallet_address': walletAddress,
    });
    return PreparedTrade.fromJson(_decodeMap(response, endpoint: '/trades/prepare'));
  }

  Future<TradeExecution> submitTradeHash({
    required int tradeId,
    required String txHash,
    String? walletAddress,
  }) async {
    final response = await _post('/trades/$tradeId/submit', {
      'tx_hash': txHash,
      if (walletAddress != null) 'wallet_address': walletAddress,
    });
    return TradeExecution.fromJson(_decodeMap(response, endpoint: '/trades/$tradeId/submit'));
  }

  Future<List<WalletBalance>> fetchWalletBalances() async {
    final response = await _get('/portfolio/balances');
    final payload = _decodeList(response, endpoint: '/portfolio/balances');
    return payload.map((item) => WalletBalance.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<DisputeHistoryEntry>> fetchDisputeHistory() async {
    final response = await _get('/disputes/history');
    final payload = _decodeList(response, endpoint: '/disputes/history');
    return payload.map((item) => DisputeHistoryEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Market> createMarket(Map<String, dynamic> payload) async {
    final response = await _post('/markets', payload);
    return Market.fromJson(_decodeMap(response, endpoint: '/markets'));
  }

  Future<Market> fetchMarketById(int id) async {
    final response = await _get('/markets/$id');
    return Market.fromJson(_decodeMap(response, endpoint: '/markets/$id'));
  }

  Future<Map<String, dynamic>> buildCreateMarketTx(Map<String, dynamic> payload) async {
    final response = await _post('/blockchain/create-market', payload);
    return _decodeMap(response, endpoint: '/blockchain/create-market')['tx'] as Map<String, dynamic>;
  }

  Future<int> createMarketChainTx(int marketId, String walletAddress) async {
    final response = await _post('/chain-tx/market-create', {'market_id': marketId, 'wallet_address': walletAddress});
    final message = _decodeMap(response, endpoint: '/chain-tx/market-create')['message'] as String;
    return int.parse(message);
  }

  Future<void> submitChainTx(int txId, String txHash, String walletAddress) async {
    await _post('/chain-tx/$txId/submit', {'tx_hash': txHash, 'wallet_address': walletAddress});
  }

  Future<Map<String, dynamic>> buildDisputeTx(Map<String, dynamic> payload) async {
    final response = await _post('/blockchain/dispute', payload);
    return _decodeMap(response, endpoint: '/blockchain/dispute')['tx'] as Map<String, dynamic>;
  }

  Future<int> createDisputeChainTx(int marketId, String walletAddress, String evidenceUri) async {
    final response = await _post('/chain-tx/dispute', {
      'market_id': marketId,
      'wallet_address': walletAddress,
      'evidence_uri': evidenceUri,
    });
    final message = _decodeMap(response, endpoint: '/chain-tx/dispute')['message'] as String;
    return int.parse(message);
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

  Future<http.Response> _patch(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await http
          .patch(
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
