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
  return marketsValue.whenData((items) => items[selectedIndex.clamp(0, items.length - 1)]);
});
final selectedMarketFutureProvider = FutureProvider<Market>((ref) async {
  final items = await ref.watch(marketListProvider.future);
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
final insuranceQuoteProvider = FutureProvider<InsuranceQuote>((ref) async => ref.read(apiClientProvider).fetchInsuranceQuote('demo-position'));
final autoHedgeProvider = FutureProvider<AutoHedgePlan>((ref) async => ref.read(apiClientProvider).fetchAutoHedge('btc-120k-2026', 4200));

final copilotProvider = FutureProvider<CopilotRecommendation>((ref) async {
  final wallet = ref.watch(walletSessionProvider);
  final market = await ref.watch(selectedMarketFutureProvider.future);
  return ref.read(apiClientProvider).fetchCopilot(market.id, wallet.address ?? '0xdemo');
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
  const WalletSessionState({this.address, this.connected = false, this.error});

  final String? address;
  final bool connected;
  final String? error;

  WalletSessionState copyWith({String? address, bool? connected, String? error}) {
    return WalletSessionState(
      address: address ?? this.address,
      connected: connected ?? this.connected,
      error: error,
    );
  }
}

class WalletSessionNotifier extends StateNotifier<WalletSessionState> {
  WalletSessionNotifier(this._walletService) : super(const WalletSessionState());

  final WalletService _walletService;

  Future<void> restore() async {
    final session = _walletService.currentSession();
    if (session == null) return;
    final accounts = session.namespaces['eip155']?.accounts;
    state = state.copyWith(address: accounts?.isNotEmpty == true ? accounts!.first : null, connected: accounts?.isNotEmpty == true);
  }

  Future<void> connect() async {
    try {
      final session = await _walletService.connect();
      final accounts = session?.namespaces['eip155']?.accounts;
      final account = accounts?.isNotEmpty == true ? accounts!.first : null;
      state = state.copyWith(address: account, connected: account != null, error: null);
    } catch (error) {
      state = state.copyWith(error: error.toString(), connected: false);
    }
  }
}

final walletSessionProvider = StateNotifierProvider<WalletSessionNotifier, WalletSessionState>((ref) {
  return WalletSessionNotifier(ref.read(walletServiceProvider));
});
