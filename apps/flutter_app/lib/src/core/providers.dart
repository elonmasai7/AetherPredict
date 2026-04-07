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
final txUpdatesProvider = StreamProvider<TxUpdate>((ref) => ref.read(apiClientProvider).txUpdates());
final riskProvider = FutureProvider<PortfolioRiskSnapshot>((ref) async => ref.read(apiClientProvider).fetchRisk());
final exposureProvider = FutureProvider<List<ExposureSlice>>((ref) async => ref.read(apiClientProvider).fetchExposure());
final performanceProvider = FutureProvider<List<PerformancePoint>>((ref) async => ref.read(apiClientProvider).fetchPerformance());
final walletBalancesProvider = FutureProvider<List<WalletBalance>>((ref) async => ref.read(apiClientProvider).fetchWalletBalances());
final disputeHistoryProvider = FutureProvider<List<DisputeHistoryEntry>>((ref) async => ref.read(apiClientProvider).fetchDisputeHistory());
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async => ref.read(apiClientProvider).fetchNotifications());
final traderLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async => ref.read(apiClientProvider).fetchLeaderboard('traders'));
final agentLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async => ref.read(apiClientProvider).fetchLeaderboard('agents'));
final jurorLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async => ref.read(apiClientProvider).fetchLeaderboard('jurors'));
final bundleProvider = FutureProvider<List<BundleModel>>((ref) async => ref.read(apiClientProvider).fetchBundles());
final vaultProvider = FutureProvider<List<VaultModel>>((ref) async => ref.read(apiClientProvider).fetchVaults());
final topVaultsProvider = FutureProvider<List<VaultModel>>((ref) async => ref.read(apiClientProvider).fetchVaults(category: 'top-performing'));
final lowRiskVaultsProvider = FutureProvider<List<VaultModel>>((ref) async => ref.read(apiClientProvider).fetchVaults(category: 'low-risk'));
final aiVaultsProvider = FutureProvider<List<VaultModel>>((ref) async => ref.read(apiClientProvider).fetchVaults(category: 'ai-managed'));
final humanVaultsProvider = FutureProvider<List<VaultModel>>((ref) async => ref.read(apiClientProvider).fetchVaults(category: 'human-managed'));
final vaultDetailProvider = FutureProvider.family<VaultModel, int>((ref, vaultId) async {
  return ref.read(apiClientProvider).fetchVaultById(vaultId);
});
final vaultTradesProvider = FutureProvider.family<List<VaultTrade>, int>((ref, vaultId) async {
  return ref.read(apiClientProvider).fetchVaultTrades(vaultId);
});
final vaultPerformanceProvider = FutureProvider.family<List<VaultPerformancePoint>, int>((ref, vaultId) async {
  return ref.read(apiClientProvider).fetchVaultPerformance(vaultId);
});
final copyRelationshipsProvider = FutureProvider<List<CopyRelationshipModel>>((ref) async {
  return ref.read(apiClientProvider).fetchCopyRelationships();
});
final copiedTradesProvider = FutureProvider<List<CopiedTradeModel>>((ref) async {
  return ref.read(apiClientProvider).fetchCopiedTrades();
});
final copyPortfolioProvider = FutureProvider<CopyPortfolioSummaryModel>((ref) async {
  return ref.read(apiClientProvider).fetchCopyPortfolioSummary();
});
final copyPerformanceProvider = FutureProvider.family<List<CopyPerformanceSnapshotModel>, int>((ref, relationshipId) async {
  return ref.read(apiClientProvider).fetchCopyPerformance(relationshipId);
});
final vaultUpdatesProvider = StreamProvider<Map<String, dynamic>>((ref) => ref.read(apiClientProvider).vaultUpdates());
final copyUpdatesProvider = StreamProvider<Map<String, dynamic>>((ref) => ref.read(apiClientProvider).copyUpdates());
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
  bool _listening = false;
  bool _restored = false;

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final session = _walletService.currentSession();
    if (session == null) return;
    final accounts = session.namespaces['eip155']?.accounts;
    final address = accounts?.isNotEmpty == true ? accounts!.first : null;
    await _syncPortfolio(address: address, type: WalletType.walletConnect, fallbackBalance: 0);
    _listenWalletEvents();
  }

  Future<void> connect(WalletType type) async {
    try {
      final account = await _walletService.connect(type);
      await _syncPortfolio(address: account.address, type: type, fallbackBalance: account.balanceUsd);
      _listenWalletEvents();
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
    final balances = await _ref.read(walletBalancesProvider.future).catchError((_) => <WalletBalance>[]);
    final balanceUsd = balances.isEmpty ? fallbackBalance : balances.fold<double>(0, (sum, b) => sum + b.valueUsd);
    final portfolioValue = positions.fold<double>(0, (sum, p) => sum + (p.size * p.markPrice));
    state = state.copyWith(
      address: address,
      connected: address != null,
      type: type,
      balanceUsd: balanceUsd,
      portfolioValue: portfolioValue,
      activePositions: positions.length,
      error: null,
    );
  }

  void _listenWalletEvents() {
    if (_listening) return;
    _listening = true;
    _walletService.sessionEvents().listen((event) {
      final data = event is Map<String, dynamic> ? event : <String, dynamic>{};
      if (data['name'] == 'accountsChanged') {
        final accounts = data['data'] as List<dynamic>? ?? [];
        final address = accounts.isNotEmpty ? accounts.first.toString() : null;
        _syncPortfolio(address: address, type: state.type ?? WalletType.walletConnect, fallbackBalance: 0);
      }
      if (data['name'] == 'chainChanged') {
        _syncPortfolio(address: state.address, type: state.type ?? WalletType.walletConnect, fallbackBalance: state.balanceUsd);
      }
    });
  }
}

final walletSessionProvider = StateNotifierProvider<WalletSessionNotifier, WalletSessionState>((ref) {
  return WalletSessionNotifier(ref.read(walletServiceProvider), ref);
});
