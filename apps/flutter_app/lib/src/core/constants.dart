import 'package:flutter/foundation.dart';

class AppConfig {
  static const walletConnectProjectId = String.fromEnvironment('WALLETCONNECT_PROJECT_ID', defaultValue: '');
  static const explorerBaseUrl = String.fromEnvironment(
    'EXPLORER_URL',
    defaultValue: 'https://explorer.hashkeychain.example',
  );

  static String get apiBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final base = Uri.base;
      final host = base.host;
      final port = base.hasPort ? ':${base.port}' : '';
      return '${base.scheme}://$host$port';
    }
    return 'http://localhost:8000';
  }

  static String get wsMarketsUrl {
    const configured = String.fromEnvironment('WS_MARKETS_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final base = Uri.base;
      final scheme = base.scheme == 'https' ? 'wss' : 'ws';
      final host = base.host;
      final port = base.hasPort ? ':${base.port}' : '';
      return '$scheme://$host$port/ws/markets';
    }
    return 'ws://localhost:8000/ws/markets';
  }

  static String get wsTxUrl {
    const configured = String.fromEnvironment('WS_TX_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final base = Uri.base;
      final scheme = base.scheme == 'https' ? 'wss' : 'ws';
      final host = base.host;
      final port = base.hasPort ? ':${base.port}' : '';
      return '$scheme://$host$port/ws/tx';
    }
    return 'ws://localhost:8000/ws/tx';
  }

  static String get wsVaultsUrl {
    const configured = String.fromEnvironment('WS_VAULTS_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final base = Uri.base;
      final scheme = base.scheme == 'https' ? 'wss' : 'ws';
      final host = base.host;
      final port = base.hasPort ? ':${base.port}' : '';
      return '$scheme://$host$port/ws/vaults';
    }
    return 'ws://localhost:8000/ws/vaults';
  }

  static String get wsCopyUrl {
    const configured = String.fromEnvironment('WS_COPY_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      final base = Uri.base;
      final scheme = base.scheme == 'https' ? 'wss' : 'ws';
      final host = base.host;
      final port = base.hasPort ? ':${base.port}' : '';
      return '$scheme://$host$port/ws/copy';
    }
    return 'ws://localhost:8000/ws/copy';
  }
}
