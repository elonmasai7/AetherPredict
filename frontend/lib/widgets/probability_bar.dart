import 'package:flutter/material.dart';

class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({super.key, required this.yesProbability});

  final double yesProbability;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            Expanded(
              flex: (yesProbability * 1000).round(),
              child: Container(color: const Color(0xFF20B486)),
            ),
            Expanded(
              flex: ((1 - yesProbability) * 1000).round(),
              child: Container(color: const Color(0xFFEA5C5C)),
            ),
          ],
        ),
      ),
    );
  }
}
