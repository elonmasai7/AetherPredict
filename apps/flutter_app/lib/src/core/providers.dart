import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models.dart';
import 'wallet_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => const ApiClient());
final walletServiceProvider = Provider<WalletService>((ref) => WalletService());

final marketListProvider = FutureProvider<List<Market>>((ref) async {
  return ref.read(apiClientProvider).fetchMarkets();
});

final selectedMarketIndexProvider = StateProvider<int>((ref) => 0);

final selectedMarketProvider = Provider<AsyncValue<Market>>((ref) {
  final marketsValue = ref.watch(marketListProvider);
  final selectedIndex = ref.watch(selectedMarketIndexProvider);
  return marketsValue.whenData((items) => items[selectedIndex.clamp(0, items.length - 1)]);
});

final agentListProvider = FutureProvider<List<AgentCardModel>>((ref) async {
  return ref.read(apiClientProvider).fetchAgents();
});

final portfolioProvider = FutureProvider<List<PortfolioPosition>>((ref) async {
  return ref.read(apiClientProvider).fetchPortfolio();
});

final marketUpdatesProvider = StreamProvider<LiveMarketUpdate>((ref) {
  return ref.read(apiClientProvider).marketUpdates();
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
