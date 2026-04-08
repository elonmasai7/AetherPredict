import 'dart:async';

import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import 'constants.dart';

enum WalletType { phantom, walletConnect, metaMask, coinbase }

class WalletAccount {
  const WalletAccount({required this.address, required this.balanceUsd});
  final String address;
  final double balanceUsd;
}

class WalletService {
  Web3App? _app;
  SessionData? _session;

  Future<Web3App> init() async {
    if (_app != null) return _app!;
    _app = await Web3App.createInstance(
      projectId: AppConfig.walletConnectProjectId,
      metadata: const PairingMetadata(
        name: 'AetherPredict',
        description: 'AI-powered on-chain prediction markets on HashKey Chain',
        url: 'https://aetherpredict.local',
        icons: ['https://walletconnect.com/walletconnect-logo.png'],
        redirect: Redirect(
          native: 'aetherpredict://',
          universal: 'https://aetherpredict.local',
        ),
      ),
    );
    _session = currentSession();
    return _app!;
  }

  Future<WalletAccount> connect(WalletType type) async {
    if (AppConfig.walletConnectProjectId.isEmpty) {
      throw UnsupportedError(
        'WalletConnect is not configured. Set WALLETCONNECT_PROJECT_ID before connecting wallets.',
      );
    }

    final app = await init();
    final connection = await app.connect(
      requiredNamespaces: {
        'eip155': const RequiredNamespace(
          chains: ['eip155:133'],
          methods: [
            'eth_sendTransaction',
            'personal_sign',
            'eth_signTypedData'
          ],
          events: ['accountsChanged', 'chainChanged'],
        ),
      },
    );
    final session = await connection.session.future;
    _session = session;
    final accounts = session.namespaces['eip155']?.accounts;
    final account = accounts != null && accounts.isNotEmpty ? accounts.first : null;
    if (account == null) {
      throw StateError('Wallet connected without an account address.');
    }
    final parts = account.split(':');
    final address = parts.isNotEmpty ? parts.last : account;
    return WalletAccount(address: address, balanceUsd: 0);
  }

  SessionData? currentSession() {
    if (_app == null) return null;
    final sessions = _app!.sessions.getAll();
    if (sessions.isEmpty) return null;
    return sessions.first;
  }

  Stream<dynamic> sessionEvents() {
    final app = _app;
    if (app == null) {
      return const Stream.empty();
    }
    late final EventHandler<SessionEvent> handler;
    late final StreamController<SessionEvent> controller;
    controller = StreamController<SessionEvent>.broadcast(
      onListen: () {
        handler = (event) {
          if (event != null) {
            controller.add(event);
          }
        };
        app.onSessionEvent.subscribe(handler);
      },
      onCancel: () {
        app.onSessionEvent.unsubscribe(handler);
      },
    );
    return controller.stream;
  }

  Future<int?> currentChainId() async {
    final session = _session ?? currentSession();
    if (session == null) return null;
    final chains = session.namespaces['eip155']?.chains;
    final chain = chains != null && chains.isNotEmpty ? chains.first : null;
    if (chain == null) return null;
    final parts = chain.split(':');
    return parts.length == 2 ? int.tryParse(parts[1]) : null;
  }

  Future<void> switchChain(int chainId) async {
    final session = _session ?? currentSession();
    if (session == null) {
      throw StateError('Connect a wallet before switching chains.');
    }
    final app = await init();
    await app.request(
      topic: session.topic,
      chainId: 'eip155:$chainId',
      request: SessionRequestParams(
        method: 'wallet_switchEthereumChain',
        params: [
          {'chainId': '0x${chainId.toRadixString(16)}'}
        ],
      ),
    );
  }

  Future<void> disconnect() async {
    if (_app == null) return;
    for (final s in _app!.sessions.getAll()) {
      await _app!.disconnectSession(
        topic: s.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
    }
    _session = null;
  }

  Future<String> signTrade(String payload) async {
    final session = currentSession();
    if (session == null) {
      throw StateError('Connect a wallet before signing a trade.');
    }
    throw UnsupportedError(
      'Interactive trade signing is not wired through the Flutter wallet bridge yet.',
    );
  }

  Future<String> sendTransaction(Map<String, dynamic> tx) async {
    final session = _session ?? currentSession();
    if (session == null) {
      throw StateError('Connect a wallet before submitting a transaction.');
    }
    final app = await init();
    final result = await app.request(
      topic: session.topic,
      chainId: 'eip155:133',
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [tx],
      ),
    );
    return result as String;
  }
}
