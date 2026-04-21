import 'package:flutter/widgets.dart';

import '../nba/nba_command_center_screen.dart';

class LiveGamesScreen extends StatelessWidget {
  const LiveGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbaCommandCenterScreen(section: NbaSection.liveGames);
  }
}
