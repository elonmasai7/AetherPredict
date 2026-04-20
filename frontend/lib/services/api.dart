import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/liquidity.dart';
import '../models/market.dart';
import '../models/portfolio.dart';

class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000',
            ),
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );

  final Dio _dio;
  final _secureStorage = const FlutterSecureStorage();
  static const _tokenKey = 'predictodds_token';
  static const _providerKey = 'predictodds_provider_creds';

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox('predictodds_cache');
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await token();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<String?> token() => _secureStorage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _secureStorage.write(key: _tokenKey, value: token);

  Future<void> saveProviderCreds(Map<String, dynamic> payload) =>
      _secureStorage.write(key: _providerKey, value: jsonEncode(payload));

  Future<Map<String, dynamic>?> readProviderCreds() async {
    final raw = await _secureStorage.read(key: _providerKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> register(String email, String password) async {
    await _dio.post('/auth/register', data: {'email': email, 'password': password});
  }

  Future<void> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    await saveToken(response.data['access_token'] as String);
  }

  Future<void> saveProviderCredentials(Map<String, dynamic> payload) async {
    await saveProviderCreds(payload);
    await _dio.post('/auth/provider-credentials', data: payload);
  }

  Future<List<MarketModel>> fetchMarkets() async {
    final response = await _dio.get('/markets');
    final markets = (response.data as List<dynamic>)
        .map((item) => MarketModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    await Hive.box('predictodds_cache').put(
      'markets',
      markets.map((e) => {
            'id': e.id,
            'title': e.title,
            'event': e.event,
            'provider': e.provider,
            'yes_price': e.yesPrice,
            'no_price': e.noPrice,
            'implied_probability': e.impliedProbability,
            'spread_cents': e.spreadCents,
            'spread_tier': e.spreadTier,
            'liquidity_usd': e.liquidityUsd,
            'end_ts': e.endTs.toIso8601String(),
            'odds_history': e.oddsHistory,
            'order_book': {
              'yes_bids': e.orderBook.yesBids.map((l) => {'price': l.price, 'shares': l.shares}).toList(),
              'yes_asks': e.orderBook.yesAsks.map((l) => {'price': l.price, 'shares': l.shares}).toList(),
              'no_bids': e.orderBook.noBids.map((l) => {'price': l.price, 'shares': l.shares}).toList(),
              'no_asks': e.orderBook.noAsks.map((l) => {'price': l.price, 'shares': l.shares}).toList(),
              'best_yes_bid': e.orderBook.bestYesBid,
              'best_yes_ask': e.orderBook.bestYesAsk,
            },
          }).toList(),
    );
    return markets;
  }

  List<MarketModel> cachedMarkets() {
    final raw = Hive.box('predictodds_cache').get('markets', defaultValue: []) as List<dynamic>;
    return raw
        .map((item) => MarketModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<MarketModel> fetchOdds(int marketId) async {
    final response = await _dio.get('/markets/$marketId/odds');
    final data = Map<String, dynamic>.from(response.data as Map);
    return MarketModel.fromJson({
      'id': marketId,
      'title': data['title'],
      'event': data['event'],
      'provider': 'live',
      'yes_price': data['yes_price'],
      'no_price': data['no_price'],
      'implied_probability': data['implied_probability'],
      'spread_cents': data['bid_ask_spread_cents'],
      'spread_tier': data['spread_tier'],
      'liquidity_usd': ((data['order_book_depth'] as Map)['yes'] as num).toDouble() +
          (((data['order_book_depth'] as Map)['no'] as num).toDouble()),
      'end_ts': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'odds_history': data['history'] ?? [],
      'order_book': data['order_book'],
    });
  }

  Future<LiquidityModel> fetchLiquidity(int marketId) async {
    final response = await _dio.get('/liquidity/$marketId');
    return LiquidityModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Map<String, dynamic>> trade(int marketId, String side, double notional) async {
    final response = await _dio.post('/trade/$marketId', data: {'side': side, 'notional': notional});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<DashboardModel> fetchDashboard() async {
    final response = await _dio.get('/portfolio/dashboard');
    final dashboard = DashboardModel.fromJson(Map<String, dynamic>.from(response.data as Map));
    await Hive.box('predictodds_cache').put(
      'positions',
      dashboard.positions
          .map((e) => {
                'position_id': e.positionId,
                'market_id': e.marketId,
                'title': e.title,
                'side': e.side,
                'shares': e.shares,
                'avg_price': e.avgPrice,
                'mark_price': e.markPrice,
                'pnl': e.pnl,
                'spread_cents': e.spreadCents,
                'volume': e.volume,
              })
          .toList(),
    );
    return dashboard;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get('/portfolio/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Stream<Map<String, dynamic>> connectOddsStream(int marketId) {
    final wsBase = const String.fromEnvironment(
      'WS_BASE_URL',
      defaultValue: 'ws://localhost:8000',
    );
    final channel = WebSocketChannel.connect(Uri.parse('$wsBase/ws/odds/$marketId'));
    final heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {
      channel.sink.add('ping');
    });
    return channel.stream.map((event) {
      return Map<String, dynamic>.from(jsonDecode(event as String) as Map);
    }).asBroadcastStream(onCancel: (subscription) {
      heartbeat.cancel();
      channel.sink.close();
    });
  }
}
