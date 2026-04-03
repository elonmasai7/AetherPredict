import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_data.dart';
import 'models.dart';

final marketListProvider = Provider<List<Market>>((ref) => markets);
final selectedMarketProvider = Provider<Market>((ref) => markets.first);
final agentListProvider = Provider<List<AgentCardModel>>((ref) => agents);
