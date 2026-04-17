import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class StrategyMetricCard extends StatelessWidget {
  const StrategyMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AetherColors.accent;
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(AetherSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tone.withValues(alpha: 0.2),
            AetherColors.bgPanel,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AetherRadii.lg),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AetherColors.muted),
          ),
          const SizedBox(height: AetherSpacing.sm),
          Text(
            value,
            style: numericStyle(context, size: 22, weight: FontWeight.w700),
          ),
          const SizedBox(height: AetherSpacing.xs),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class StrategyEngineSectionNav extends StatelessWidget {
  const StrategyEngineSectionNav({super.key, required this.currentPath});

  final String currentPath;

  static const _items = [
    ('My Strategies', '/strategy-engine'),
    ('Templates', '/strategy-engine/templates'),
    ('AI Builder', '/strategy-engine/ai-builder'),
    ('Automation Monitor', '/strategy-engine/automation-monitor'),
    ('Performance Ranking', '/strategy-engine/performance-ranking'),
  ];

  @override
  Widget build(BuildContext context) {
    return EnterprisePanel(
      padding: const EdgeInsets.all(AetherSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in _items) ...[
              _NavPill(
                label: item.$1,
                selected: currentPath == item.$2,
                onTap: () => context.go(item.$2),
              ),
              if (item != _items.last) const SizedBox(width: AetherSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AetherColors.accent : AetherColors.bgPanel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AetherColors.accent : AetherColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AetherColors.text : AetherColors.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class StrategyShell extends StatelessWidget {
  const StrategyShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentPath,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StrategyEngineSectionNav(currentPath: currentPath),
        const SizedBox(height: AetherSpacing.lg),
        EnterprisePanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.hub_rounded, size: 26, color: AetherColors.accent),
              const SizedBox(width: AetherSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AetherSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const StatusBadge(label: 'Prediction-first infrastructure'),
            ],
          ),
        ),
        const SizedBox(height: AetherSpacing.lg),
        Expanded(child: child),
      ],
    );
  }
}

class StrategyCodeBlock extends StatelessWidget {
  const StrategyCodeBlock({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AetherSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F16),
        borderRadius: BorderRadius.circular(AetherRadii.lg),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: numericStyle(
                  context,
                  size: 13,
                  weight: FontWeight.w500,
                  color: AetherColors.text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
