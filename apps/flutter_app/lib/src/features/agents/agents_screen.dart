import 'package:flutter/widgets.dart';

import '../nba/nba_command_center_screen.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbaCommandCenterScreen(section: NbaSection.aiAgents);
  }
}
