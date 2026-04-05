import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import 'constants.dart';

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
        redirect: Redirect(native: 'aetherpredict://', universal: 'https://aetherpredict.local'),
      ),
    );
    return _app!;
  }

  Future<SessionData?> connect() async {
    final app = await init();
    final connection = await app.connect(
      requiredNamespaces: {
        'eip155': const RequiredNamespace(
          chains: ['eip155:133'],
          methods: ['eth_sendTransaction', 'personal_sign', 'eth_signTypedData'],
          events: ['accountsChanged', 'chainChanged'],
        ),
      },
    );
    return await connection.session.future;
  }

  SessionData? currentSession() {
    if (_app == null) return null;
    final sessions = _app!.sessions.getAll();
    if (sessions.isEmpty) return null;
    return sessions.first;
  }
}
