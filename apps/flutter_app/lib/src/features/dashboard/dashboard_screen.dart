import 'package:flutter/widgets.dart';

import '../nba/nba_command_center_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbaCommandCenterScreen(section: NbaSection.overview);
  }
}
