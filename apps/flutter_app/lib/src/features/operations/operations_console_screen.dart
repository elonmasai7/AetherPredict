import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class OperationsConsoleScreen extends StatelessWidget {
  const OperationsConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Operations Console',
      child: ListView(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _OpsMetric(title: 'Protocol Health', value: '99.98%', detail: 'SLA over last 24h'),
              _OpsMetric(title: 'Dispute Queue', value: '4', detail: '2 high priority'),
              _OpsMetric(title: 'Flagged Wallets', value: '13', detail: 'Monitoring active'),
              _OpsMetric(title: 'Oracle Drift', value: '0.12%', detail: 'Within threshold'),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Operational Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Component')),
                    DataColumn(label: Text('Event')),
                    DataColumn(label: Text('Severity')),
                  ],
                  rows: const [
                    DataRow(cells: [DataCell(Text('15:29:14')), DataCell(Text('Oracle Mesh')), DataCell(Text('Cross-feed sync complete')), DataCell(Text('Info'))]),
                    DataRow(cells: [DataCell(Text('15:12:52')), DataCell(Text('Liquidity Sentinel')), DataCell(Text('Depth reduced on BTC market')), DataCell(Text('Warning'))]),
                    DataRow(cells: [DataCell(Text('14:58:31')), DataCell(Text('Dispute Engine')), DataCell(Text('Escalated case #2981')), DataCell(Text('Critical'))]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('System Incidents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                Text('No unresolved incidents in the past 6 hours.'),
                SizedBox(height: 8),
                Text('Last incident: API latency spike at 12:14 UTC, resolved in 4m.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsMetric extends StatelessWidget {
  const _OpsMetric({required this.title, required this.value, required this.detail});
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AetherColors.muted)),
            const SizedBox(height: 8),
            Text(value, style: numericStyle(context, size: 28)),
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(color: AetherColors.muted)),
          ],
        ),
      ),
    );
  }
}
