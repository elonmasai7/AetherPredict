import 'package:flutter/widgets.dart';

import '../nba/nba_command_center_screen.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbaCommandCenterScreen(section: NbaSection.leaderboard);
  }
}
