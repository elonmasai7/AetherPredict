import 'package:flutter/material.dart';

import '../core/theme.dart';

Future<void> showTradeExecutionModal(BuildContext context,
    {required String side, required String market}) async {
  final amount = TextEditingController();
  final limit = TextEditingController();
  final sl = TextEditingController();
  final tp = TextEditingController();
  final slip = TextEditingController(text: '0.5');

  try {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AetherColors.bgElevated,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AetherColors.border)),
          title: Text('Prepare $side Forecast Position'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: amount,
                      decoration: const InputDecoration(
                          labelText: 'Open Position Size (USD)')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: limit,
                      decoration: const InputDecoration(
                          labelText: 'Target Probability (%)')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: sl,
                      decoration: const InputDecoration(
                          labelText: 'Close Forecast Trigger')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: tp,
                      decoration: const InputDecoration(
                          labelText: 'Confidence Target')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: slip,
                      decoration: const InputDecoration(
                          labelText: 'Slippage Tolerance %')),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Forecast positions require a connected signing wallet and backend settlement wiring. This dialog captures real inputs without inventing a confirmation hash.',
                      style: TextStyle(color: AetherColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if ([amount.text, limit.text, sl.text, tp.text, slip.text]
                    .any((value) => value.trim().isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Enter complete forecast parameters before continuing.')),
                  );
                  return;
                }

                Navigator.pop(context);
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AetherColors.bgElevated,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AetherColors.border)),
                    title: const Text('Forecast Position Ready for Signature'),
                    content: Text(
                      'Event market: $market\nPosition: $side\nAmount: ${amount.text}\nTarget probability: ${limit.text}\n\nNo transaction has been broadcast yet.',
                    ),
                    actions: [
                      FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close')),
                    ],
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  } finally {
    amount.dispose();
    limit.dispose();
    sl.dispose();
    tp.dispose();
    slip.dispose();
  }
}
