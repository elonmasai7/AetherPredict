import 'package:flutter/widgets.dart';

import '../nba/nba_command_center_screen.dart';

class MarketListScreen extends StatelessWidget {
  const MarketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbaCommandCenterScreen(section: NbaSection.markets);
  }
}
