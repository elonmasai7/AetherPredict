import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/liquidity.dart';
import '../models/market.dart';
import 'auth_provider.dart';

final marketListProvider = FutureProvider<List<MarketModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    return await api.fetchMarkets();
  } catch (_) {
    return api.cachedMarkets();
  }
});

final selectedMarketIdProvider = StateProvider<int?>((ref) => null);

final selectedMarketProvider = Provider<MarketModel?>((ref) {
  final selectedId = ref.watch(selectedMarketIdProvider);
  final markets = ref.watch(marketListProvider).valueOrNull ?? const <MarketModel>[];
  if (selectedId == null && markets.isNotEmpty) {
    return markets.first;
  }
  for (final market in markets) {
    if (market.id == selectedId) {
      return market;
    }
  }
  return markets.isEmpty ? null : markets.first;
});

final liquidityProvider = FutureProvider.family<LiquidityModel, int>((ref, marketId) async {
  return ref.read(apiServiceProvider).fetchLiquidity(marketId);
});

final liveOddsProvider = StreamProvider.family<Map<String, dynamic>, int>((ref, marketId) {
  final api = ref.read(apiServiceProvider);
  final controller = StreamController<Map<String, dynamic>>();
  final sub = api.connectOddsStream(marketId).listen(controller.add, onError: controller.addError);
  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });
  return controller.stream;
});
