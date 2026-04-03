class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');
  static const wsMarketsUrl = String.fromEnvironment('WS_MARKETS_URL', defaultValue: 'ws://localhost:8000/ws/markets');
  static const walletConnectProjectId = String.fromEnvironment('WALLETCONNECT_PROJECT_ID', defaultValue: '');
}
