import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';
import 'strategy_engine_models.dart';
import 'strategy_engine_widgets.dart';

class StrategyTemplatesScreen extends ConsumerWidget {
  const StrategyTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesValue = ref.watch(strategyTemplatesProvider);
    return AppScaffold(
      title: 'Strategy Engine',
      subtitle:
          'Prediction-market-native TypeScript templates for forecasting systems, automation hooks, and probability intelligence.',
      child: StrategyShell(
        title: 'Templates',
        subtitle:
            'Live backend templates for event forecasting, sentiment, cross-market correlation, and macro prediction.',
        currentPath: '/strategy-engine/templates',
        child: templatesValue.when(
          data: (templates) => ListView(
            children: [
              Wrap(
                spacing: AetherSpacing.lg,
                runSpacing: AetherSpacing.lg,
                children: [
                  for (final template in templates)
                    _TemplateCard(template: template),
                ],
              ),
              const SizedBox(height: AetherSpacing.lg),
              const EnterprisePanel(
                title: 'Microstructure Automation Add-Ons',
                subtitle:
                    'These templates can be extended with arbitrage, cross-market lag, speed-based, and custom inventive automations.',
                child: StrategyCodeBlock(
                  lines: [
                    'automationModes: [',
                    '  "arbitrage-detection",',
                    '  "cross-market-analysis",',
                    '  "speed-based-opportunity",',
                    '  "innovative",',
                    ']',
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EnterprisePanel(
            title: 'Unable to load templates',
            child: Text(
              error.toString(),
              style: const TextStyle(color: AetherColors.critical),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final StrategyTemplateModel template;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: EnterprisePanel(
        title: template.name,
        subtitle: template.description,
        trailing: const StatusBadge(label: 'Backend template'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(label: 'Best Fit'),
            Text(template.useCase, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AetherSpacing.md),
            const _SectionTitle(label: 'Typed Interfaces'),
            Wrap(
              spacing: AetherSpacing.sm,
              runSpacing: AetherSpacing.sm,
              children: [
                for (final item in template.interfaces) Chip(label: Text(item)),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            const _SectionTitle(label: 'Ingestion Layer'),
            for (final source in template.ingestionSources)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $source',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: AetherSpacing.md),
            const _SectionTitle(label: 'Confidence Scoring'),
            Text(
              template.confidenceMethod,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AetherSpacing.md),
            const _SectionTitle(label: 'Execution Hook'),
            Text(
              template.executionHook,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.xs),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AetherColors.accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
