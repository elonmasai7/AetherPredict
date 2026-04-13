import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class MarketResolutionCenterScreen extends StatelessWidget {
  const MarketResolutionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Market Resolution Center',
      subtitle:
          'Premium AI resolution workflow with evidence review, juror dispute windows, and on-chain final settlement.',
      child: ListView(
        children: [
          EnterprisePanel(
            child: Wrap(
              spacing: AetherSpacing.sm,
              runSpacing: AetherSpacing.sm,
              children: const [
                StatusBadge(
                    label: 'Pending Markets: 6', color: AetherColors.warning),
                StatusBadge(
                    label: 'AI Consensus Ready: 4',
                    color: AetherColors.success),
                StatusBadge(
                    label: 'Open Dispute Windows: 2',
                    color: AetherColors.warning),
                StatusBadge(
                    label: 'Finalized Today: 9', color: AetherColors.success),
              ],
            ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          EnterpriseDataTable<_ResolutionRow>(
            title: 'Pending Market Resolution Queue',
            subtitle:
                'Evidence sources, AI consensus, confidence score, juror dispute window, and expected final outcome.',
            rows: const [
              _ResolutionRow(
                market: 'Will BTC exceed \$120k by Dec 31 2026?',
                evidenceSource:
                    'HashKey Oracle Mesh + Exchange Index Composite',
                aiConsensus: 'YES',
                confidenceScore: 0.82,
                disputeWindow: '24h remaining',
                finalOutcome: 'Pending finality',
              ),
              _ResolutionRow(
                market: 'Will ETH ETF volume double by Q4 2026?',
                evidenceSource: 'SEC Filings + Issuer Flow Feeds',
                aiConsensus: 'YES',
                confidenceScore: 0.76,
                disputeWindow: '18h remaining',
                finalOutcome: 'Pending finality',
              ),
              _ResolutionRow(
                market: 'Will HashKey Chain TVL exceed \$1B by Q3 2026?',
                evidenceSource: 'On-chain TVL Oracle Snapshot',
                aiConsensus: 'NO',
                confidenceScore: 0.71,
                disputeWindow: 'Closed',
                finalOutcome: 'Finalized NO',
              ),
            ],
            rowId: (row) => row.market,
            searchHint: 'Search market or evidence source',
            filters: [
              EnterpriseTableFilter(
                label: 'Confidence > 75%',
                predicate: (row) => row.confidenceScore >= 0.75,
              ),
              EnterpriseTableFilter(
                label: 'Dispute Open',
                predicate: (row) =>
                    row.disputeWindow.toLowerCase().contains('remaining'),
              ),
            ],
            columns: [
              EnterpriseTableColumn(
                label: 'Event Market',
                width: 280,
                cell: (row) => row.market,
                sortValue: (row) => row.market,
              ),
              EnterpriseTableColumn(
                label: 'Evidence Source',
                width: 250,
                cell: (row) => row.evidenceSource,
                sortValue: (row) => row.evidenceSource,
              ),
              EnterpriseTableColumn(
                label: 'AI Consensus',
                width: 110,
                cell: (row) => row.aiConsensus,
                sortValue: (row) => row.aiConsensus,
              ),
              EnterpriseTableColumn(
                label: 'Confidence',
                width: 100,
                numeric: true,
                cell: (row) =>
                    '${(row.confidenceScore * 100).toStringAsFixed(1)}%',
                sortValue: (row) => row.confidenceScore,
              ),
              EnterpriseTableColumn(
                label: 'Juror Window',
                width: 120,
                cell: (row) => row.disputeWindow,
                sortValue: (row) => row.disputeWindow,
              ),
              EnterpriseTableColumn(
                label: 'Final Outcome',
                width: 120,
                cell: (row) => row.finalOutcome,
                sortValue: (row) => row.finalOutcome,
              ),
            ],
            expandedBuilder: (row) => Row(
              children: [
                StatusBadge(
                  label: row.aiConsensus == 'YES'
                      ? 'Consensus YES'
                      : 'Consensus NO',
                  color: row.aiConsensus == 'YES'
                      ? AetherColors.success
                      : AetherColors.warning,
                ),
                const SizedBox(width: AetherSpacing.sm),
                const Text(
                  'Workflow: expiry → AI evidence evaluation → confidence output → on-chain resolution → dispute window → final settlement',
                  style: TextStyle(color: AetherColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          EnterprisePanel(
            title: 'Resolution Workflow Standard',
            subtitle:
                'Canonical process for all AetherPredict market outcomes.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _WorkflowText(
                    '1. Market expires and enters AI resolution state.'),
                _WorkflowText(
                    '2. Evidence sources are ingested and scored by reliability and timeliness.'),
                _WorkflowText(
                    '3. AI consensus and confidence score are published on-chain.'),
                _WorkflowText(
                    '4. Juror dispute window opens for evidence challenges.'),
                _WorkflowText(
                    '5. If no valid dispute succeeds, final outcome is settled on-chain.'),
                _WorkflowText(
                    '6. YES/NO payouts are finalized and audit logs are preserved.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolutionRow {
  const _ResolutionRow({
    required this.market,
    required this.evidenceSource,
    required this.aiConsensus,
    required this.confidenceScore,
    required this.disputeWindow,
    required this.finalOutcome,
  });

  final String market;
  final String evidenceSource;
  final String aiConsensus;
  final double confidenceScore;
  final String disputeWindow;
  final String finalOutcome;
}

class _WorkflowText extends StatelessWidget {
  const _WorkflowText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.sm),
      child: Text(text),
    );
  }
}
