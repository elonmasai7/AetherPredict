import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'constants.dart';
import 'models.dart';
import 'nba_models.dart';
import '../features/strategy_engine/strategy_engine_models.dart';

class ApiClient {
  const ApiClient({
    String? Function()? readAccessToken,
    Future<bool> Function()? refreshAccessToken,
  })  : _readAccessToken = readAccessToken,
        _refreshAccessToken = refreshAccessToken;

  final String? Function()? _readAccessToken;
  final Future<bool> Function()? _refreshAccessToken;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return _decodeMap(response, endpoint: '/auth/login');
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _post('/auth/register', {
      'email': email,
      'password': password,
      if (displayName != null && displayName.trim().isNotEmpty)
        'display_name': displayName.trim(),
    });
    return _decodeMap(response, endpoint: '/auth/register');
  }

  Future<List<Market>> fetchMarkets() async {
    final response = await _get('/markets');
    final payload = _decodeList(response, endpoint: '/markets');
    return payload
        .map((item) => Market.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PlatformHomeModel> fetchPlatformHome() async {
    final response = await _get('/platform/home');
    return PlatformHomeModel.fromJson(
      _decodeMap(response, endpoint: '/platform/home'),
    );
  }

  Future<StrategyPreviewModel> previewStrategy({
    required String prompt,
    required List<String> dataSources,
    required String riskLevel,
    required bool automationEnabled,
  }) async {
    final response = await _post('/platform/strategy/preview', {
      'prompt': prompt,
      'data_sources': dataSources,
      'risk_level': riskLevel,
      'automation_enabled': automationEnabled,
    });
    return StrategyPreviewModel.fromJson(
      _decodeMap(response, endpoint: '/platform/strategy/preview'),
    );
  }

  Future<LiquidityDetail> fetchMarketLiquidity(String marketId) async {
    final response = await _get('/markets/$marketId/liquidity');
    final payload =
        _decodeMap(response, endpoint: '/markets/$marketId/liquidity');
    return LiquidityDetail.fromJson(
      Map<String, dynamic>.from(
          payload['liquidity_intelligence'] as Map? ?? {}),
    );
  }

  Future<LiquidityDashboard> fetchLiquidityDashboard() async {
    final response = await _get('/markets/liquidity/dashboard');
    return LiquidityDashboard.fromJson(
      _decodeMap(response, endpoint: '/markets/liquidity/dashboard'),
    );
  }

  Future<PredictFlowHealth> fetchPredictFlowHealth() async {
    final response = await _getFromBaseUrl(
      AppConfig.predictFlowBaseUrl,
      '/health',
      endpointLabel: 'predictflow:/health',
    );
    return PredictFlowHealth.fromJson(
      _decodeMap(response, endpoint: 'predictflow:/health'),
    );
  }

  Future<List<PredictFlowMarketSnapshot>> fetchPredictFlowMarkets() async {
    final response = await _getFromBaseUrl(
      AppConfig.predictFlowBaseUrl,
      '/api/markets',
      endpointLabel: 'predictflow:/api/markets',
    );
    final payload = _decodeList(response, endpoint: 'predictflow:/api/markets');
    return payload
        .map((item) =>
            PredictFlowMarketSnapshot.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PredictFlowPortfolio> fetchPredictFlowDashboard(String wallet) async {
    final response = await _getFromBaseUrl(
      AppConfig.predictFlowBaseUrl,
      '/api/dashboard/$wallet',
      endpointLabel: 'predictflow:/api/dashboard/$wallet',
    );
    return PredictFlowPortfolio.fromJson(
      _decodeMap(response, endpoint: 'predictflow:/api/dashboard/$wallet'),
    );
  }

  Future<PredictFlowPreview> previewPredictFlowOrder({
    required String marketId,
    required String outcome,
    required String side,
    required double shares,
    String type = 'MARKET',
    double? limitPrice,
  }) async {
    final response = await _postToBaseUrl(
      AppConfig.predictFlowBaseUrl,
      '/api/preview',
      {
        'marketId': marketId,
        'outcome': outcome,
        'side': side,
        'type': type,
        'shares': shares,
        if (limitPrice != null) 'limitPrice': limitPrice,
      },
      endpointLabel: 'predictflow:/api/preview',
    );
    return PredictFlowPreview.fromJson(
      _decodeMap(response, endpoint: 'predictflow:/api/preview'),
    );
  }

  Future<PredictFlowOrderResult> placePredictFlowOrder({
    required String marketId,
    required String wallet,
    required String outcome,
    required String side,
    required double shares,
    String type = 'MARKET',
    double? limitPrice,
  }) async {
    final response = await _postToBaseUrl(
      AppConfig.predictFlowBaseUrl,
      '/api/orders',
      {
        'marketId': marketId,
        'wallet': wallet,
        'outcome': outcome,
        'side': side,
        'type': type,
        'shares': shares,
        if (limitPrice != null) 'limitPrice': limitPrice,
      },
      endpointLabel: 'predictflow:/api/orders',
    );
    return PredictFlowOrderResult.fromJson(
      _decodeMap(response, endpoint: 'predictflow:/api/orders'),
    );
  }

  Future<List<AgentCardModel>> fetchAgents() async {
    final response = await _get('/agents');
    final payload = _decodeList(response, endpoint: '/agents');
    return payload
        .map((item) => AgentCardModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PortfolioPosition>> fetchPortfolio() async {
    final response = await _get('/portfolio/positions');
    final payload = _decodeList(response, endpoint: '/portfolio/positions');
    return payload
        .map((item) => PortfolioPosition.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PortfolioRiskSnapshot> fetchRisk() async {
    final response = await _get('/portfolio/risk');
    return PortfolioRiskSnapshot.fromJson(
        _decodeMap(response, endpoint: '/portfolio/risk'));
  }

  Future<List<ExposureSlice>> fetchExposure() async {
    final response = await _get('/portfolio/exposure');
    final payload = _decodeList(response, endpoint: '/portfolio/exposure');
    return payload
        .map((item) => ExposureSlice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PerformancePoint>> fetchPerformance() async {
    final response = await _get('/portfolio/performance');
    final payload = _decodeList(response, endpoint: '/portfolio/performance');
    return payload
        .map((item) => PerformancePoint.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CopilotRecommendation> fetchCopilot(
      String marketId, String walletAddress) async {
    final response = await _post(
      '/ai/copilot/recommendation',
      {
        'market_id': marketId,
        'wallet_address': walletAddress,
        'portfolio_data': {},
      },
    );
    return CopilotRecommendation.fromJson(
        _decodeMap(response, endpoint: '/ai/copilot/recommendation'));
  }

  Future<SentimentFeed> fetchSentimentFeed(String marketId) async {
    final response =
        await _post('/ai/market/sentiment-feed', {'market_id': marketId});
    return SentimentFeed.fromJson(
        _decodeMap(response, endpoint: '/ai/market/sentiment-feed'));
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _get('/notifications/history');
    final payload = _decodeList(response, endpoint: '/notifications/history');
    return payload
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String type) async {
    final response = await _get('/leaderboard/$type');
    final payload = _decodeList(response, endpoint: '/leaderboard/$type');
    return payload
        .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<BundleModel>> fetchBundles() async {
    final response = await _get('/bundles');
    final payload = _decodeList(response, endpoint: '/bundles');
    return payload
        .map((item) => BundleModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<VaultModel>> fetchVaults({String? category}) async {
    final suffix = category == null ? '' : '?category=$category';
    final response = await _get('/vaults$suffix');
    final payload = _decodeList(response, endpoint: '/vaults');
    return payload
        .map((item) => VaultModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VaultModel> fetchVaultById(int id) async {
    final response = await _get('/vaults/$id');
    return VaultModel.fromJson(_decodeMap(response, endpoint: '/vaults/$id'));
  }

  Future<List<VaultTrade>> fetchVaultTrades(int vaultId) async {
    final response = await _get('/vaults/$vaultId/trades');
    final payload = _decodeList(response, endpoint: '/vaults/$vaultId/trades');
    return payload
        .map((item) => VaultTrade.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<VaultPerformancePoint>> fetchVaultPerformance(int vaultId) async {
    final response = await _get('/vaults/$vaultId/performance');
    final payload =
        _decodeList(response, endpoint: '/vaults/$vaultId/performance');
    return payload
        .map((item) =>
            VaultPerformancePoint.fromJson(item as Map<String, dynamic>))
        .toList();
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

  Future<CopyRelationshipModel> followTrader(
      Map<String, dynamic> payload) async {
    final response = await _post('/copy-trading/follow', payload);
    return CopyRelationshipModel.fromJson(
        _decodeMap(response, endpoint: '/copy-trading/follow'));
  }

  Future<CopyRelationshipModel> unfollowTrader(int sourceUserId) async {
    final response = await _post('/copy-trading/unfollow/$sourceUserId', {});
    return CopyRelationshipModel.fromJson(
        _decodeMap(response, endpoint: '/copy-trading/unfollow'));
  }

  Future<CopyRelationshipModel> updateCopySettings(
      int relationshipId, Map<String, dynamic> payload) async {
    final response =
        await _patch('/copy-trading/settings/$relationshipId', payload);
    return CopyRelationshipModel.fromJson(_decodeMap(response,
        endpoint: '/copy-trading/settings/$relationshipId'));
  }

  Future<List<CopyRelationshipModel>> fetchCopyRelationships() async {
    final response = await _get('/copy-trading/relationships');
    final payload =
        _decodeList(response, endpoint: '/copy-trading/relationships');
    return payload
        .map((item) =>
            CopyRelationshipModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CopiedTradeModel>> fetchCopiedTrades() async {
    final response = await _get('/copy-trading/trades');
    final payload = _decodeList(response, endpoint: '/copy-trading/trades');
    return payload
        .map((item) => CopiedTradeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CopyPerformanceSnapshotModel>> fetchCopyPerformance(
      int relationshipId) async {
    final response = await _get('/copy-trading/performance/$relationshipId');
    final payload = _decodeList(response,
        endpoint: '/copy-trading/performance/$relationshipId');
    return payload
        .map((item) =>
            CopyPerformanceSnapshotModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CopyRelationshipModel> stopCopying(int relationshipId) async {
    final response = await _post('/copy-trading/stop/$relationshipId', {});
    return CopyRelationshipModel.fromJson(
        _decodeMap(response, endpoint: '/copy-trading/stop/$relationshipId'));
  }

  Future<CopyPortfolioSummaryModel> fetchCopyPortfolioSummary() async {
    final response = await _get('/copy-trading/portfolio');
    return CopyPortfolioSummaryModel.fromJson(
        _decodeMap(response, endpoint: '/copy-trading/portfolio'));
  }

  Future<InsuranceQuote> fetchInsuranceQuote(String positionId) async {
    final response = await _get('/insurance/quote?position_id=$positionId');
    return InsuranceQuote.fromJson(
        _decodeMap(response, endpoint: '/insurance/quote'));
  }

  Future<AutoHedgePlan> fetchAutoHedge(String marketId, double positionSize,
      {bool enable = true}) async {
    final response = await _post(
      '/portfolio/auto-hedge',
      {
        'market_id': marketId,
        'current_side': 'YES',
        'position_size': positionSize,
        'enable': enable,
      },
    );
    return AutoHedgePlan.fromJson(
        _decodeMap(response, endpoint: '/portfolio/auto-hedge'));
  }

  Future<List<DiscussionComment>> fetchComments(int marketId) async {
    final response = await _get('/market/comments?market_id=$marketId');
    final payload = _decodeList(response, endpoint: '/market/comments');
    return payload
        .map((item) => DiscussionComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StrategyEngineStateModel> fetchStrategyEngineState() async {
    final response = await _get('/strategy-engine/state');
    return StrategyEngineStateModel.fromJson(
        _decodeMap(response, endpoint: '/strategy-engine/state'));
  }

  Future<List<StrategyTemplateModel>> fetchStrategyTemplates() async {
    final response = await _get('/strategy-engine/templates');
    final payload =
        _decodeList(response, endpoint: '/strategy-engine/templates');
    return payload
        .map((item) =>
            StrategyTemplateModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StrategyBuildResultModel> buildStrategyFromPrompt(
      String prompt) async {
    final response = await _post('/strategy-engine/build', {'prompt': prompt});
    return StrategyBuildResultModel.fromJson(
        _decodeMap(response, endpoint: '/strategy-engine/build'));
  }

  Future<CanonActionResultModel> runCanonCommand(
      String strategyId, String command) async {
    final response = await _post(
        '/strategy-engine/strategies/$strategyId/canon/$command', {});
    return CanonActionResultModel.fromJson(_decodeMap(response,
        endpoint: '/strategy-engine/strategies/$strategyId/canon/$command'));
  }

  Future<List<StrategyMonitorLogModel>> fetchStrategyMonitor() async {
    final response = await _get('/strategy-engine/monitor');
    final payload =
        _decodeMap(response, endpoint: '/strategy-engine/monitor')['logs']
                as List<dynamic>? ??
            [];
    return payload
        .map((item) =>
            StrategyMonitorLogModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<StrategyRankingEntryModel>> fetchStrategyRanking() async {
    final response = await _get('/strategy-engine/ranking');
    final payload =
        _decodeMap(response, endpoint: '/strategy-engine/ranking')['entries']
                as List<dynamic>? ??
            [];
    return payload
        .map((item) =>
            StrategyRankingEntryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CanonProjectExportModel> exportStrategyProject(
      String strategyId) async {
    final response =
        await _get('/strategy-engine/strategies/$strategyId/export/manifest');
    return CanonProjectExportModel.fromJson(_decodeMap(response,
        endpoint: '/strategy-engine/strategies/$strategyId/export/manifest'));
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
    return channel.stream
        .map((event) => jsonDecode(event as String) as Map<String, dynamic>);
  }

  Stream<Map<String, dynamic>> copyUpdates() {
    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsCopyUrl));
    return channel.stream
        .map((event) => jsonDecode(event as String) as Map<String, dynamic>);
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
    return PreparedTrade.fromJson(
        _decodeMap(response, endpoint: '/trades/prepare'));
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
    return TradeExecution.fromJson(
        _decodeMap(response, endpoint: '/trades/$tradeId/submit'));
  }

  Future<TradeExecution> placePrediction({
    required int marketId,
    required String side,
    required double collateralAmount,
    required double price,
    required String walletAddress,
  }) async {
    final response = await _post('/trades', {
      'market_id': marketId,
      'side': side,
      'collateral_amount': collateralAmount,
      'price': price,
      'wallet_address': walletAddress,
      'order_type': 'MARKET',
    });
    return TradeExecution.fromJson(_decodeMap(response, endpoint: '/trades'));
  }

  Future<List<WalletBalance>> fetchWalletBalances() async {
    final response = await _get('/portfolio/balances');
    final payload = _decodeList(response, endpoint: '/portfolio/balances');
    return payload
        .map((item) => WalletBalance.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DisputeHistoryEntry>> fetchDisputeHistory() async {
    final response = await _get('/disputes/history');
    final payload = _decodeList(response, endpoint: '/disputes/history');
    return payload
        .map((item) =>
            DisputeHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Market> createMarket(Map<String, dynamic> payload) async {
    final response = await _post('/markets', payload);
    return Market.fromJson(_decodeMap(response, endpoint: '/markets'));
  }

  Future<Market> fetchMarketById(int id) async {
    final response = await _get('/markets/$id');
    return Market.fromJson(_decodeMap(response, endpoint: '/markets/$id'));
  }

  Future<Map<String, dynamic>> buildCreateMarketTx(
      Map<String, dynamic> payload) async {
    final response = await _post('/blockchain/create-market', payload);
    return _decodeMap(response, endpoint: '/blockchain/create-market')['tx']
        as Map<String, dynamic>;
  }

  Future<int> createMarketChainTx(int marketId, String walletAddress) async {
    final response = await _post('/chain-tx/market-create',
        {'market_id': marketId, 'wallet_address': walletAddress});
    final message =
        _decodeMap(response, endpoint: '/chain-tx/market-create')['message']
            as String;
    return int.parse(message);
  }

  Future<void> submitChainTx(
      int txId, String txHash, String walletAddress) async {
    await _post('/chain-tx/$txId/submit',
        {'tx_hash': txHash, 'wallet_address': walletAddress});
  }

  Future<Map<String, dynamic>> buildDisputeTx(
      Map<String, dynamic> payload) async {
    final response = await _post('/blockchain/dispute', payload);
    return _decodeMap(response, endpoint: '/blockchain/dispute')['tx']
        as Map<String, dynamic>;
  }

  Future<int> createDisputeChainTx(
      int marketId, String walletAddress, String evidenceUri) async {
    final response = await _post('/chain-tx/dispute', {
      'market_id': marketId,
      'wallet_address': walletAddress,
      'evidence_uri': evidenceUri,
    });
    final message =
        _decodeMap(response, endpoint: '/chain-tx/dispute')['message']
            as String;
    return int.parse(message);
  }

  Future<http.Response> _get(String endpoint) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    return _requestWithRetry(
      endpoint: endpoint,
      send: (headers) => http.get(uri, headers: headers),
    );
  }

  Future<http.Response> _getFromBaseUrl(
    String baseUrl,
    String endpoint, {
    required String endpointLabel,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return _requestWithRetry(
      endpoint: endpointLabel,
      send: (headers) => http.get(uri, headers: headers),
    );
  }

  Future<http.Response> _post(
      String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    return _requestWithRetry(
      endpoint: endpoint,
      includeJsonContentType: true,
      send: (headers) => http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> _patch(
      String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    return _requestWithRetry(
      endpoint: endpoint,
      includeJsonContentType: true,
      send: (headers) => http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> _postToBaseUrl(
    String baseUrl,
    String endpoint,
    Map<String, dynamic> body, {
    required String endpointLabel,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return _requestWithRetry(
      endpoint: endpointLabel,
      includeJsonContentType: true,
      send: (headers) => http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> _requestWithRetry({
    required String endpoint,
    required Future<http.Response> Function(Map<String, String> headers) send,
    bool includeJsonContentType = false,
  }) async {
    try {
      var response = await send(_headers(
        includeJsonContentType: includeJsonContentType,
      )).timeout(const Duration(seconds: 10));
      final refreshAccessToken = _refreshAccessToken;
      if (response.statusCode == 401 &&
          refreshAccessToken != null &&
          !endpoint.startsWith('/auth/')) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          response = await send(_headers(
            includeJsonContentType: includeJsonContentType,
          )).timeout(const Duration(seconds: 10));
        }
      }
      _ensureSuccess(response, endpoint: endpoint);
      return response;
    } on TimeoutException {
      throw ApiException('Request timed out for $endpoint');
    } on http.ClientException catch (error) {
      throw ApiException('Network error on $endpoint: $error');
    } on FormatException {
      throw ApiException('Malformed URL for endpoint $endpoint');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Unexpected request failure on $endpoint: $error');
    }
  }

  Map<String, String> _headers({bool includeJsonContentType = false}) {
    final headers = <String, String>{};
    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }
    final token = _readAccessToken?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
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
    throw ApiException(
        'Request failed ($endpoint): HTTP ${response.statusCode} - $detail');
  }

  Map<String, dynamic> _decodeMap(http.Response response,
      {required String endpoint}) {
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

  List<dynamic> _decodeList(http.Response response,
      {required String endpoint}) {
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
