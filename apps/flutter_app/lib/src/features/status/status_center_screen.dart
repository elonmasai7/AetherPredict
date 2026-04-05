import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class StatusCenterScreen extends StatelessWidget {
  const StatusCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const statuses = [
      ('Oracle Status', 'Healthy', AetherColors.success),
      ('AI Engine', 'Running', AetherColors.success),
      ('Settlement', 'Normal', AetherColors.success),
      ('WebSocket Health', 'Stable', AetherColors.success),
      ('Dispute Queue Size', '4 Open', AetherColors.warning),
      ('API Uptime', '99.98%', AetherColors.success),
    ];

    return AppScaffold(
      title: 'Status Center',
      child: ListView(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final s in statuses)
                SizedBox(
                  width: 280,
                  child: GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.$1, style: const TextStyle(color: AetherColors.muted)),
                              const SizedBox(height: 4),
                              Text(s.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Maintenance Window', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('No maintenance scheduled. Next patch window: 2026-04-12 02:00 UTC.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
