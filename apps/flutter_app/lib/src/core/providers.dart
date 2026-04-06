import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models.dart';
import 'wallet_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => const ApiClient());
final walletServiceProvider = Provider<WalletService>((ref) => WalletService());

final marketListProvider = FutureProvider<List<Market>>((ref) async => ref.read(apiClientProvider).fetchMarkets());
final selectedMarketIndexProvider = StateProvider<int>((ref) => 0);
final selectedMarketProvider = Provider<AsyncValue<Market>>((ref) {
  final marketsValue = ref.watch(marketListProvider);
  final selectedIndex = ref.watch(selectedMarketIndexProvider);
  return marketsValue.whenData((items) {
    if (items.isEmpty) {
      throw StateError('No markets available.');
    }
    return items[selectedIndex.clamp(0, items.length - 1)];
  });
});
final selectedMarketFutureProvider = FutureProvider<Market>((ref) async {
  final items = await ref.watch(marketListProvider.future);
  if (items.isEmpty) {
    throw StateError('No markets available.');
  }
  final selectedIndex = ref.watch(selectedMarketIndexProvider);
  return items[selectedIndex.clamp(0, items.length - 1)];
});

final agentListProvider = FutureProvider<List<AgentCardModel>>((ref) async => ref.read(apiClientProvider).fetchAgents());
final portfolioProvider = FutureProvider<List<PortfolioPosition>>((ref) async => ref.read(apiClientProvider).fetchPortfolio());
final marketUpdatesProvider = StreamProvider<LiveMarketUpdate>((ref) => ref.read(apiClientProvider).marketUpdates());
final riskProvider = FutureProvider<PortfolioRiskSnapshot>((ref) async => ref.read(apiClientProvider).fetchRisk());
final exposureProvider = FutureProvider<List<ExposureSlice>>((ref) async => ref.read(apiClientProvider).fetchExposure());
final performanceProvider = FutureProvider<List<PerformancePoint>>((ref) async => ref.read(apiClientProvider).fetchPerformance());
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async => ref.read(apiClientProvider).fetchNotifications());
final traderLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async => ref.read(apiClientProvider).fetchLeaderboard('traders'));
final agentLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async => ref.read(apiClientProvider).fetchLeaderboard('agents'));
final jurorLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async => ref.read(apiClientProvider).fetchLeaderboard('jurors'));
final bundleProvider = FutureProvider<List<BundleModel>>((ref) async => ref.read(apiClientProvider).fetchBundles());
final insuranceQuoteProvider = FutureProvider<InsuranceQuote>((ref) async => ref.read(apiClientProvider).fetchInsuranceQuote('0'));
final autoHedgeProvider = FutureProvider<AutoHedgePlan>((ref) async {
  final market = await ref.watch(selectedMarketFutureProvider.future);
  return ref.read(apiClientProvider).fetchAutoHedge(market.id, 0);
});

final copilotProvider = FutureProvider<CopilotRecommendation>((ref) async {
  final wallet = ref.watch(walletSessionProvider);
  final market = await ref.watch(selectedMarketFutureProvider.future);
  return ref.read(apiClientProvider).fetchCopilot(market.id, wallet.address ?? '');
});

final sentimentFeedProvider = FutureProvider<SentimentFeed>((ref) async {
  final market = await ref.watch(selectedMarketFutureProvider.future);
  return ref.read(apiClientProvider).fetchSentimentFeed(market.id);
});

final discussionProvider = FutureProvider<List<DiscussionComment>>((ref) async {
  final market = await ref.watch(selectedMarketFutureProvider.future);
  final marketId = int.tryParse(market.id) ?? 1;
  return ref.read(apiClientProvider).fetchComments(marketId);
});

class WalletSessionState {
  const WalletSessionState({
    this.address,
    this.connected = false,
    this.error,
    this.type,
    this.balanceUsd = 0,
    this.portfolioValue = 0,
    this.activePositions = 0,
  });

  final String? address;
  final bool connected;
  final String? error;
  final WalletType? type;
  final double balanceUsd;
  final double portfolioValue;
  final int activePositions;

  WalletSessionState copyWith({
    String? address,
    bool? connected,
    String? error,
    WalletType? type,
    double? balanceUsd,
    double? portfolioValue,
    int? activePositions,
  }) {
    return WalletSessionState(
      address: address ?? this.address,
      connected: connected ?? this.connected,
      error: error,
      type: type ?? this.type,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      portfolioValue: portfolioValue ?? this.portfolioValue,
      activePositions: activePositions ?? this.activePositions,
    );
  }
}

class WalletSessionNotifier extends StateNotifier<WalletSessionState> {
  WalletSessionNotifier(this._walletService, this._ref) : super(const WalletSessionState());

  final WalletService _walletService;
  final Ref _ref;

  Future<void> restore() async {
    final session = _walletService.currentSession();
    if (session == null) return;
    final accounts = session.namespaces['eip155']?.accounts;
    final address = accounts?.isNotEmpty == true ? accounts!.first : null;
    await _syncPortfolio(address: address, type: WalletType.walletConnect, fallbackBalance: 0);
  }

  Future<void> connect(WalletType type) async {
    try {
      final account = await _walletService.connect(type);
      await _syncPortfolio(address: account.address, type: type, fallbackBalance: account.balanceUsd);
    } catch (error) {
      state = state.copyWith(error: error.toString(), connected: false);
    }
  }

  Future<void> disconnect() async {
    await _walletService.disconnect();
    state = const WalletSessionState();
  }

  Future<String> signTrade(String payload) async {
    return _walletService.signTrade(payload);
  }

  Future<void> _syncPortfolio({required String? address, required WalletType type, required double fallbackBalance}) async {
    final positions = await _ref.read(portfolioProvider.future).catchError((_) => <PortfolioPosition>[]);
    final portfolioValue = positions.fold<double>(0, (sum, p) => sum + (p.size * p.markPrice));
    state = state.copyWith(
      address: address,
      connected: address != null,
      type: type,
      balanceUsd: fallbackBalance,
      portfolioValue: portfolioValue,
      activePositions: positions.length,
      error: null,
    );
  }
}

final walletSessionProvider = StateNotifierProvider<WalletSessionNotifier, WalletSessionState>((ref) {
  return WalletSessionNotifier(ref.read(walletServiceProvider), ref);
});
