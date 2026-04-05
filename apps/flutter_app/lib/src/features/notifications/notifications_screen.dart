import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String category = 'All';

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    const categories = ['All', 'Market Alerts', 'AI Confidence Alerts', 'Whale Alerts', 'Disputes', 'Payouts', 'Hedge Suggestions'];

    return AppScaffold(
      title: 'Notification Center',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categories)
                ChoiceChip(
                  selected: category == c,
                  label: Text(c),
                  onSelected: (_) => setState(() => category = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: notifications.when(
              data: (items) {
                if (items.isEmpty) {
                  return const GlassCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No alerts right now. Live monitoring remains active.'),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final alert = items[index];
                    final level = alert.level.toLowerCase();
                    final severityColor = level == 'critical'
                        ? AetherColors.critical
                        : level == 'warning'
                            ? AetherColors.warning
                            : AetherColors.accent;
                    return GlassCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: severityColor, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert.level.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(alert.message),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
