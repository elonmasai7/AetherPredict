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
    final account = session.namespaces['eip155']?.accounts.firstOrNull;
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

  Future<void> disconnect() async {
    if (_app == null) return;
    for (final s in _app!.sessions.getAll()) {
      await _app!.disconnectSession(
        topic: s.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
    }
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
}

extension _FirstOrNullExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
