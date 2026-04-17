import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';
import 'strategy_engine_models.dart';
import 'strategy_engine_widgets.dart';

class StrategyAiBuilderScreen extends ConsumerStatefulWidget {
  const StrategyAiBuilderScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<StrategyAiBuilderScreen> createState() =>
      _StrategyAiBuilderScreenState();
}

class _StrategyAiBuilderScreenState
    extends ConsumerState<StrategyAiBuilderScreen> {
  late final TextEditingController _promptController;
  ActionButtonState _buildState = ActionButtonState.idle;
  StrategyBuildResultModel? _result;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text:
          'Build an arbitrage detection model for the same event across related BTC prediction markets using ETF flows and sentiment.',
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _buildPipeline() async {
    setState(() => _buildState = ActionButtonState.loading);
    try {
      final result = await ref
          .read(apiClientProvider)
          .buildStrategyFromPrompt(_promptController.text.trim());
      ref.invalidate(strategyEngineStateProvider);
      ref.invalidate(strategyMonitorProvider);
      ref.invalidate(strategyRankingProvider);
      if (!mounted) return;
      setState(() {
        _result = result;
        _buildState = ActionButtonState.success;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Strategy generated: ${result.strategy.name}')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _buildState = ActionButtonState.failure);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Build failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final content = StrategyShell(
      title: 'AI Builder',
      subtitle:
          'Prompts can describe arbitrage, cross-market lag, speed-based reaction, or entirely new prediction-market automations.',
      currentPath: '/strategy-engine/ai-builder',
      child: ListView(
          children: [
            EnterprisePanel(
              title: 'Plain-Language Strategy Prompt',
              subtitle:
                  'Describe a market microstructure edge or custom forecasting thesis and the backend AI planner will persist a real strategy record.',
              trailing: ActionStateButton(
                label: 'Generate Pipeline',
                state: _buildState,
                onPressed: _buildPipeline,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _promptController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe the market, catalyst inputs, lag/arbitrage edge, and probability outcome you want to forecast.',
                    ),
                  ),
                  const SizedBox(height: AetherSpacing.md),
                  const Wrap(
                    spacing: AetherSpacing.md,
                    runSpacing: AetherSpacing.md,
                    children: [
                      StrategyMetricCard(
                        label: 'Arbitrage Detection',
                        value: 'Cross-venue gaps',
                        detail:
                            'Exploit implied-probability mismatches for the same event.',
                      ),
                      StrategyMetricCard(
                        label: 'Cross-Market Analysis',
                        value: 'Lag capture',
                        detail:
                            'Trade correlated markets when one reprices slower than another.',
                        color: AetherColors.warning,
                      ),
                      StrategyMetricCard(
                        label: 'Speed-Based Opportunity',
                        value: 'Public data first',
                        detail:
                            'Act on records, matchups, injuries, and other open information before repricing.',
                        color: AetherColors.success,
                      ),
                      StrategyMetricCard(
                        label: 'Innovative',
                        value: 'Invent new signals',
                        detail:
                            'Blend sources and let the builder create a new automation thesis from scratch.',
                        color: AetherColors.accentSoft,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: AetherSpacing.lg),
              EnterprisePanel(
                title: result.strategy.name,
                subtitle:
                    'Live response from the backend build endpoint, ready for Canon workflow commands.',
                child: StrategyCodeBlock(
                  lines: [
                    'project: ${result.strategy.projectName}',
                    'template: ${result.strategy.templateName}',
                    'market: ${result.strategy.market}',
                    'stage: ${result.strategy.stage}',
                    'confidence: ${result.strategy.confidence.toStringAsFixed(2)}',
                    'canon init',
                    'canon start',
                    'canon deploy',
                  ],
                ),
              ),
              const SizedBox(height: AetherSpacing.lg),
              EnterprisePanel(
                title: 'Generated Project Files',
                subtitle:
                    'Canon scaffolding and export assets returned by the backend service.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final file in result.projectFiles)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AetherSpacing.sm),
                        child: Text(
                          '• ${file.path}',
                          style: numericStyle(context, size: 13),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AetherSpacing.lg),
              Wrap(
                spacing: AetherSpacing.lg,
                runSpacing: AetherSpacing.lg,
                children: [
                  for (final agent in result.agents)
                    SizedBox(
                      width: 350,
                      child: EnterprisePanel(
                        title: agent.name,
                        subtitle: agent.job,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final output in agent.outputs)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AetherSpacing.xs),
                                child: Text(
                                  '• $output',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AetherColors.bg,
        body: SafeArea(child: content),
      );
    }
    return AppScaffold(
      title: 'Strategy Engine',
      subtitle:
          'AI builder for turning plain-language forecasting ideas into a typed prediction workflow with deployment-ready validation.',
      child: content,
    );
  }
}
