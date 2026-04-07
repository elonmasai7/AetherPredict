import 'package:flutter/material.dart';

import '../../core/theme.dart';

class CopySettingsDialog extends StatefulWidget {
  const CopySettingsDialog({
    super.key,
    required this.title,
    required this.initialAllocation,
    required this.initialMaxLoss,
    required this.initialAutoStop,
    required this.initialRisk,
  });

  final String title;
  final double initialAllocation;
  final double initialMaxLoss;
  final double initialAutoStop;
  final String initialRisk;

  @override
  State<CopySettingsDialog> createState() => _CopySettingsDialogState();
}

class _CopySettingsDialogState extends State<CopySettingsDialog> {
  late TextEditingController allocation;
  late TextEditingController maxLoss;
  late TextEditingController autoStop;
  String riskLevel = 'MEDIUM';

  @override
  void initState() {
    super.initState();
    allocation = TextEditingController(text: widget.initialAllocation.toStringAsFixed(2));
    maxLoss = TextEditingController(text: widget.initialMaxLoss.toStringAsFixed(2));
    autoStop = TextEditingController(text: widget.initialAutoStop.toStringAsFixed(2));
    riskLevel = widget.initialRisk;
  }

  @override
  void dispose() {
    allocation.dispose();
    maxLoss.dispose();
    autoStop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AetherColors.bgElevated,
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Allocation % of balance'),
            const SizedBox(height: 6),
            TextField(
              controller: allocation,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0.20'),
            ),
            const SizedBox(height: 12),
            const Text('Max loss %'),
            const SizedBox(height: 6),
            TextField(
              controller: maxLoss,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0.08'),
            ),
            const SizedBox(height: 12),
            const Text('Auto stop threshold'),
            const SizedBox(height: 6),
            TextField(
              controller: autoStop,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0.08'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: riskLevel,
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Low Risk')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Medium Risk')),
                DropdownMenuItem(value: 'HIGH', child: Text('High Risk')),
              ],
              onChanged: (value) => setState(() => riskLevel = value ?? 'MEDIUM'),
              decoration: const InputDecoration(labelText: 'Risk Level'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final allocationValue = double.tryParse(allocation.text) ?? widget.initialAllocation;
            final maxLossValue = double.tryParse(maxLoss.text) ?? widget.initialMaxLoss;
            final autoStopValue = double.tryParse(autoStop.text) ?? widget.initialAutoStop;
            Navigator.pop(context, {
              'allocation_pct': allocationValue,
              'max_loss_pct': maxLossValue,
              'auto_stop_threshold': autoStopValue,
              'risk_level': riskLevel,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
