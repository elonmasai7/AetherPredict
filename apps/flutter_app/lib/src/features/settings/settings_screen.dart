import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      child: ListView(
        children: const [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preferences', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                Text('Dark mode first, wallet alerts enabled, confidence stream enabled.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
