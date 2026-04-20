import 'dart:convert';
import 'dart:io';

import 'package:predictflow/predictflow.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

Outcome _parseOutcome(String value) {
  switch (value.toUpperCase()) {
    case 'YES':
      return Outcome.yes;
    case 'NO':
      return Outcome.no;
    default:
      throw const FormatException('Outcome must be YES or NO.');
  }
}

Side _parseSide(String value) {
  switch (value.toUpperCase()) {
    case 'BUY':
      return Side.buy;
    case 'SELL':
      return Side.sell;
    default:
      throw const FormatException('Side must be BUY or SELL.');
  }
}

OrderType _parseOrderType(String value) {
  switch (value.toUpperCase()) {
    case 'MARKET':
      return OrderType.market;
    case 'LIMIT':
      return OrderType.limit;
    default:
      throw const FormatException('Type must be MARKET or LIMIT.');
  }
}

Future<Map<String, dynamic>> _readJson(Request request) async {
  final body = await request.readAsString();
  return Map<String, dynamic>.from(jsonDecode(body) as Map);
}

void main() async {
  final engine = PredictFlowEngine();
  final router = Router()
    ..get('/health', (Request request) {
      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'service': 'predictflow-dart',
          'markets': engine.listMarkets().length,
        }),
        headers: {'content-type': 'application/json'},
      );
    })
    ..get('/api/markets', (Request request) {
      return Response.ok(
        jsonEncode(engine.listMarkets().map((item) => item.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    })
    ..get('/api/markets/<marketId>', (Request request, String marketId) {
      return Response.ok(
        jsonEncode(engine.getMarketSnapshot(marketId)),
        headers: {'content-type': 'application/json'},
      );
    })
    ..get('/api/dashboard/<wallet>', (Request request, String wallet) {
      return Response.ok(
        jsonEncode(engine.getPortfolio(wallet).toJson()),
        headers: {'content-type': 'application/json'},
      );
    })
    ..post('/api/preview', (Request request) async {
      final body = await _readJson(request);
      final result = engine.previewOrder(
        marketId: body['marketId'] as String,
        outcome: _parseOutcome(body['outcome'] as String),
        side: _parseSide(body['side'] as String),
        type: _parseOrderType(body['type'] as String),
        shares: (body['shares'] as num).toDouble(),
        limitPrice: (body['limitPrice'] as num?)?.toDouble(),
      );
      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'content-type': 'application/json'},
      );
    })
    ..post('/api/orders', (Request request) async {
      final body = await _readJson(request);
      final result = engine.placeOrder(
        marketId: body['marketId'] as String,
        wallet: body['wallet'] as String,
        outcome: _parseOutcome(body['outcome'] as String),
        side: _parseSide(body['side'] as String),
        type: _parseOrderType(body['type'] as String),
        shares: (body['shares'] as num).toDouble(),
        limitPrice: (body['limitPrice'] as num?)?.toDouble(),
      );
      return Response(
        201,
        body: jsonEncode(result.toJson()),
        headers: {'content-type': 'application/json'},
      );
    })
    ..post('/api/liquidity', (Request request) async {
      final body = await _readJson(request);
      final market = engine.addLiquidity(
        body['marketId'] as String,
        body['wallet'] as String,
        (body['collateral'] as num).toDouble(),
      );
      return Response.ok(
        jsonEncode(market.toJson()),
        headers: {'content-type': 'application/json'},
      );
    })
    ..post('/api/resolve', (Request request) async {
      final body = await _readJson(request);
      final market = engine.resolveMarket(
        body['marketId'] as String,
        _parseOutcome(body['outcome'] as String),
      );
      return Response.ok(
        jsonEncode(market.toJson()),
        headers: {'content-type': 'application/json'},
      );
    });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler((Request request) async {
        try {
          return await router.call(request);
        } on StateError catch (error) {
          return Response(
            400,
            body: jsonEncode({'error': error.message}),
            headers: {'content-type': 'application/json'},
          );
        } on FormatException catch (error) {
          return Response(
            400,
            body: jsonEncode({'error': error.message}),
            headers: {'content-type': 'application/json'},
          );
        } catch (error) {
          return Response.internalServerError(
            body: jsonEncode({'error': error.toString()}),
            headers: {'content-type': 'application/json'},
          );
        }
      });

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    int.parse(Platform.environment['PORT'] ?? '8081'),
  );

  stdout.writeln(
    'PredictFlow Dart server listening on http://${server.address.host}:${server.port}',
  );
}
