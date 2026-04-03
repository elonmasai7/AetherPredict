import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class DisputeCenterScreen extends StatelessWidget {
  const DisputeCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dispute Center',
      child: ListView(
        children: const [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active dispute', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                Text('Market: Will HashKey Chain TVL exceed \$50M by Q3?'),
                SizedBox(height: 8),
                Text('AI summary: supporting evidence remains mixed; review oracle lag and mirrored TVL data.'),
                SizedBox(height: 8),
                Text('Juror votes: 14 YES / 6 NO'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
