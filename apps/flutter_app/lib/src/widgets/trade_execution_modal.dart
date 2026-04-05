import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

Future<void> showTradeExecutionModal(BuildContext context,
    {required String side, required String market}) async {
  final amount = TextEditingController(text: '1000');
  final limit = TextEditingController(text: '0.74');
  final sl = TextEditingController(text: '0.62');
  final tp = TextEditingController(text: '0.88');
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
          title: Text('Execute $side Trade'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: amount,
                      decoration: const InputDecoration(
                          labelText: 'Market Order Size (USD)')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: limit,
                      decoration: const InputDecoration(
                          labelText: 'Limit Order Price')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: sl,
                      decoration:
                          const InputDecoration(labelText: 'Stop Loss')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: tp,
                      decoration:
                          const InputDecoration(labelText: 'Take Profit')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: slip,
                      decoration: const InputDecoration(
                          labelText: 'Slippage Tolerance %')),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Estimated Fees: \$4.80 • Gas: \$2.14 • Expected Payout: \$1,284',
                        style: TextStyle(color: AetherColors.muted)),
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
                final amountValue = double.tryParse(amount.text);
                final limitValue = double.tryParse(limit.text);
                final slValue = double.tryParse(sl.text);
                final tpValue = double.tryParse(tp.text);
                final slippageValue = double.tryParse(slip.text);

                if ([amountValue, limitValue, slValue, tpValue, slippageValue]
                    .contains(null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please enter valid numeric trade parameters.')),
                  );
                  return;
                }

                Navigator.pop(context);
                final hash = _fakeHash();
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AetherColors.bgElevated,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AetherColors.border)),
                    title: const Text('Trade Executed Successfully'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Market: $market'),
                        Text('Side: $side'),
                        const SizedBox(height: 8),
                        Text('Tx Hash: $hash',
                            style: numericStyle(context, size: 12)),
                        const SizedBox(height: 8),
                        TextButton(
                            onPressed: () {},
                            child: const Text('View on Explorer')),
                      ],
                    ),
                    actions: [
                      FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done')),
                    ],
                  ),
                );
              },
              child: const Text('Confirm Trade'),
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

String _fakeHash() {
  const chars = 'abcdef0123456789';
  final random = Random();
  return '0x${List.generate(64, (_) => chars[random.nextInt(chars.length)]).join()}';
}
