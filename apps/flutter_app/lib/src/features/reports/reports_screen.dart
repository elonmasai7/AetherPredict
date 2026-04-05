import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports',
      child: ListView(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _FilterField(label: 'Start Date'),
              _FilterField(label: 'End Date'),
              _FilterField(label: 'Account'),
              _FilterField(label: 'Report Type'),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Export Workflows', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Export CSV')),
                    OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Generate PDF Statement')),
                    OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.history), label: const Text('Transaction History')),
                    OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.analytics_outlined), label: const Text('Performance Report')),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Recent Report Jobs', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Generated')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Format')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: const [
                    DataRow(cells: [DataCell(Text('2026-04-05 15:18')), DataCell(Text('Performance Statement')), DataCell(Text('PDF')), DataCell(Text('Completed'))]),
                    DataRow(cells: [DataCell(Text('2026-04-05 14:02')), DataCell(Text('Transaction History')), DataCell(Text('CSV')), DataCell(Text('Completed'))]),
                    DataRow(cells: [DataCell(Text('2026-04-05 09:41')), DataCell(Text('Risk Summary')), DataCell(Text('PDF')), DataCell(Text('Completed'))]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextField(decoration: InputDecoration(labelText: label)),
    );
  }
}
