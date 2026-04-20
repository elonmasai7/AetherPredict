import 'package:flutter/foundation.dart';

class AppConfig {
  static const walletConnectProjectId =
      String.fromEnvironment('WALLETCONNECT_PROJECT_ID', defaultValue: '');
  static const explorerBaseUrl = String.fromEnvironment(
    'EXPLORER_URL',
    defaultValue: 'https://explorer.hashkeychain.example',
  );

  static String get apiBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final origin = _webBackendOrigin();
      return '${origin.scheme}://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}';
    }
    return 'http://localhost:8000';
  }

  static String get wsMarketsUrl {
    const configured =
        String.fromEnvironment('WS_MARKETS_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final origin = _webBackendOrigin();
      final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}/ws/markets';
    }
    return 'ws://localhost:8000/ws/markets';
  }

  static String get wsTxUrl {
    const configured = String.fromEnvironment('WS_TX_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final origin = _webBackendOrigin();
      final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}/ws/tx';
    }
    return 'ws://localhost:8000/ws/tx';
  }

  static String get wsVaultsUrl {
    const configured =
        String.fromEnvironment('WS_VAULTS_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final origin = _webBackendOrigin();
      final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}/ws/vaults';
    }
    return 'ws://localhost:8000/ws/vaults';
  }

  static String get wsCopyUrl {
    const configured = String.fromEnvironment('WS_COPY_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final origin = _webBackendOrigin();
      final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}/ws/copy';
    }
    return 'ws://localhost:8000/ws/copy';
  }

  static String get predictFlowBaseUrl {
    const configured =
        String.fromEnvironment('PREDICTFLOW_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final base = Uri.base;
      final scheme = base.scheme;
      final host = base.host;
      return '$scheme://$host:8081';
    }
    return 'http://localhost:8081';
  }

  static Uri _webBackendOrigin() {
    final base = Uri.base;
    final isLocalHost = base.host == 'localhost' || base.host == '127.0.0.1';

    // Local dev default: Flutter web server on :8080, backend on :8000.
    if (isLocalHost && base.port == 8080) {
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: 8000,
      );
    }

    if (base.hasPort) {
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.port,
      );
    }
    return Uri(
      scheme: base.scheme,
      host: base.host,
    );
  }
}
