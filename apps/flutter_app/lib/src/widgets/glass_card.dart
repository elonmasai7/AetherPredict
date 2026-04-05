import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.useGlass = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool useGlass;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: useGlass ? AetherColors.bgPanel.withValues(alpha: 0.72) : AetherColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AetherColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (!useGlass) return panel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: panel,
      ),
    );
  }
}
