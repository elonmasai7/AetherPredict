import 'package:flutter/material.dart';

class SpreadBadge extends StatelessWidget {
  const SpreadBadge({super.key, required this.spreadCents, required this.tier});

  final int spreadCents;
  final String tier;

  Color get _color {
    if (spreadCents <= 2) return const Color(0xFF1FA971);
    if (spreadCents <= 5) return const Color(0xFFE0A11B);
    return const Color(0xFFD54B4B);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color),
      ),
      child: Text(
        'Spread ${spreadCents}¢ · $tier',
        style: TextStyle(color: _color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
