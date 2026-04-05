import 'dart:math';

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
            universal: 'https://aetherpredict.local'),
      ),
    );
    return _app!;
  }

  Future<WalletAccount> connect(WalletType type) async {
    if (type == WalletType.walletConnect) {
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
      final account = session.namespaces['eip155']?.accounts.firstOrNull ??
          _fakeAddress(type);
      return WalletAccount(address: account, balanceUsd: _mockBalance(type));
    }

    return WalletAccount(
        address: _fakeAddress(type), balanceUsd: _mockBalance(type));
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
    final random = Random();
    const chars = 'abcdef0123456789';
    return '0x${List.generate(64, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  double _mockBalance(WalletType type) {
    switch (type) {
      case WalletType.phantom:
        return 182450.52;
      case WalletType.walletConnect:
        return 97310.11;
      case WalletType.metaMask:
        return 126004.88;
      case WalletType.coinbase:
        return 84592.05;
    }
  }

  String _fakeAddress(WalletType type) {
    switch (type) {
      case WalletType.phantom:
        return 'Phntm8x3k2...a91';
      case WalletType.walletConnect:
        return '0xA37HEr...0001';
      case WalletType.metaMask:
        return '0xF4a8d2...9bc1';
      case WalletType.coinbase:
        return '0xCb0d43...7ef2';
    }
  }
}

extension _FirstOrNullExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
