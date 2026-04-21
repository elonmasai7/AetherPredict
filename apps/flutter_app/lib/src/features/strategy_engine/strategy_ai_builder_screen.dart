import 'package:flutter/widgets.dart';

import '../nba/nba_command_center_screen.dart';

class StrategyAiBuilderScreen extends StatelessWidget {
  const StrategyAiBuilderScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return const NbaCommandCenterScreen(section: NbaSection.strategyLab);
  }
}
