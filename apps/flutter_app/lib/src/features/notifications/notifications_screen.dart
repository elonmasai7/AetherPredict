import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _queueFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final notificationsValue = ref.watch(notificationsProvider);

    return AppScaffold(
      title: 'Alerts',
      subtitle: 'Prioritized event queue for trading, risk, and operations desks.',
      child: notificationsValue.when(
        data: (alerts) {
          final filtered = _applyQueueFilter(alerts);
          final critical = alerts
              .where((item) => item.level.toLowerCase().contains('critical'))
              .length;
          final warning = alerts
              .where((item) => item.level.toLowerCase().contains('warning'))
              .length;

          return ListView(
            children: [
              KpiStrip(
                items: [
                  KpiStripItem(label: 'Total Alerts', value: alerts.length.toString()),
                  KpiStripItem(label: 'Critical', value: critical.toString()),
                  KpiStripItem(label: 'Warning', value: warning.toString()),
                  KpiStripItem(
                    label: 'Informational',
                    value: (alerts.length - critical - warning).toString(),
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.lg),
              EnterprisePanel(
                child: Wrap(
                  spacing: AetherSpacing.sm,
                  runSpacing: AetherSpacing.sm,
                  children: [
                    for (final item in const [
                      'All',
                      'Critical',
                      'Warning',
                      'Info',
                    ])
                      ChoiceChip(
                        label: Text(item),
                        selected: _queueFilter == item,
                        onSelected: (_) => setState(() => _queueFilter = item),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AetherSpacing.lg),
              if (filtered.isEmpty)
                const EmptyStateCard(
                  icon: Icons.notifications_none,
                  title: 'No alerts in this queue',
                  message:
                      'Current filter has no items. Monitoring remains active and new events will stream automatically.',
                )
              else
                EnterpriseDataTable<AppNotification>(
                  title: 'Alert Queue',
                  subtitle: 'Desk actions and acknowledgement states.',
                  rows: filtered,
                  rowId: (row) => '${row.level}-${row.message.hashCode}',
                  searchHint: 'Search alerts',
                  filters: [
                    EnterpriseTableFilter(
                      label: 'Critical',
                      predicate: (row) =>
                          row.level.toLowerCase().contains('critical'),
                    ),
                    EnterpriseTableFilter(
                      label: 'Warning',
                      predicate: (row) => row.level.toLowerCase().contains('warning'),
                    ),
                  ],
                  columns: [
                    EnterpriseTableColumn(
                      label: 'Severity',
                      width: 100,
                      cell: (row) => row.level,
                      sortValue: (row) => row.level,
                    ),
                    EnterpriseTableColumn(
                      label: 'Message',
                      width: 420,
                      cell: (row) => row.message,
                      sortValue: (row) => row.message,
                    ),
                    EnterpriseTableColumn(
                      label: 'Desk',
                      width: 110,
                      cell: (row) => row.level.toLowerCase().contains('critical')
                          ? 'Risk'
                          : row.level.toLowerCase().contains('warning')
                              ? 'Trading'
                              : 'Ops',
                      sortValue: (row) => row.level,
                    ),
                    EnterpriseTableColumn(
                      label: 'State',
                      width: 120,
                      cell: (row) => row.level.toLowerCase().contains('critical')
                          ? 'Action Required'
                          : 'Monitoring',
                      sortValue: (row) => row.level,
                    ),
                  ],
                  expandedBuilder: (row) => Row(
                    children: [
                      StatusBadge(
                        label: row.level,
                        color: row.level.toLowerCase().contains('critical')
                            ? AetherColors.critical
                            : row.level.toLowerCase().contains('warning')
                                ? AetherColors.warning
                                : AetherColors.accent,
                      ),
                      const SizedBox(width: AetherSpacing.sm),
                      const Text(
                        'Escalation policy: notify desk lead after 5 min unresolved state.',
                        style: TextStyle(color: AetherColors.muted),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to load alerts',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  List<AppNotification> _applyQueueFilter(List<AppNotification> alerts) {
    switch (_queueFilter) {
      case 'Critical':
        return alerts
            .where((item) => item.level.toLowerCase().contains('critical'))
            .toList();
      case 'Warning':
        return alerts
            .where((item) => item.level.toLowerCase().contains('warning'))
            .toList();
      case 'Info':
        return alerts
            .where((item) =>
                !item.level.toLowerCase().contains('critical') &&
                !item.level.toLowerCase().contains('warning'))
            .toList();
      default:
        return alerts;
    }
  }
}
