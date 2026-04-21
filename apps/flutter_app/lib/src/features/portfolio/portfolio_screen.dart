import 'package:flutter/widgets.dart';

import '../nba/nba_command_center_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbaCommandCenterScreen(section: NbaSection.myPredictions);
  }
}
