import 'package:flutter/widgets.dart';

import '../nba/nba_command_center_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbaCommandCenterScreen(section: NbaSection.news);
  }
}
