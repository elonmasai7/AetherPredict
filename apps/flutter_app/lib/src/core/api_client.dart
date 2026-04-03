import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'constants.dart';
import 'models.dart';

class ApiClient {
  const ApiClient();

  Future<List<Market>> fetchMarkets() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/markets'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => Market.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<AgentCardModel>> fetchAgents() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/agents'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => AgentCardModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<PortfolioPosition>> fetchPortfolio() async {
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/portfolio/positions'));
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => PortfolioPosition.fromJson(item as Map<String, dynamic>)).toList();
  }

  Stream<LiveMarketUpdate> marketUpdates() {
    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsMarketsUrl));
    return channel.stream.map((event) {
      final payload = jsonDecode(event as String) as Map<String, dynamic>;
      return LiveMarketUpdate.fromJson(payload);
    });
  }
}
