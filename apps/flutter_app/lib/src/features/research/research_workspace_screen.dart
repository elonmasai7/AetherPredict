import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class ResearchWorkspaceScreen extends StatefulWidget {
  const ResearchWorkspaceScreen({super.key});

  @override
  State<ResearchWorkspaceScreen> createState() =>
      _ResearchWorkspaceScreenState();
}

class _ResearchWorkspaceScreenState extends State<ResearchWorkspaceScreen> {
  final _thesisController = TextEditingController(
    text: 'Thesis Summary\n'
        '- BTC trend persistence remains supported by ETF net inflows and on-chain participation recovery.\n'
        '- Tactical plan: maintain probability bias with tighter downside invalidation under macro event risk windows.\n\n'
        'Invalidation\n'
        '- Market volume divergence for 3 consecutive sessions\n'
        '- Macro liquidity impulse negative for two weekly prints\n\n'
        'Forecast Plan\n'
        '- Open forecast tranches at 58-61% implied probability\n'
        '- Risk mitigation trigger above 80 bps realized spread widening',
  );

  String _draftState = 'Saved 2m ago';
  ActionButtonState _saveState = ActionButtonState.idle;

  @override
  void dispose() {
    _thesisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Research & Thesis',
      subtitle:
          'Collaborative event thesis development, evidence management, and forecast publication.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1220;
          if (compact) {
            return ListView(
              children: [
                _watchlistZone(),
                const SizedBox(height: AetherSpacing.lg),
                _editorZone(),
                const SizedBox(height: AetherSpacing.lg),
                _insightZone(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: _watchlistZone()),
              const SizedBox(width: AetherSpacing.lg),
              Expanded(child: _editorZone()),
              const SizedBox(width: AetherSpacing.lg),
              SizedBox(width: 360, child: _insightZone()),
            ],
          );
        },
      ),
    );
  }

  Widget _watchlistZone() {
    const watchRows = [
      _ResearchWatchRow('BTC > 120k before Dec 2026', 'Macro', 'High'),
      _ResearchWatchRow('ETH ETF volume doubles by Q4', 'Flows', 'Medium'),
      _ResearchWatchRow('HashKey TVL > 50M by Q3', 'On-chain', 'Medium'),
      _ResearchWatchRow('SOL staking APR holds > 7%', 'Yield', 'Low'),
    ];

    return EnterpriseDataTable<_ResearchWatchRow>(
      title: 'Research Watchlist',
      subtitle: 'Active hypotheses under monitoring.',
      rows: watchRows,
      rowId: (row) => row.title,
      searchHint: 'Search watchlist',
      filters: [
        EnterpriseTableFilter(
          label: 'High Priority',
          predicate: (row) => row.priority == 'High',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Hypothesis',
          width: 200,
          cell: (row) => row.title,
          sortValue: (row) => row.title,
        ),
        EnterpriseTableColumn(
          label: 'Domain',
          width: 75,
          cell: (row) => row.domain,
          sortValue: (row) => row.domain,
        ),
        EnterpriseTableColumn(
          label: 'Priority',
          width: 70,
          cell: (row) => row.priority,
          sortValue: (row) => row.priority,
        ),
      ],
      expandedBuilder: (row) => Text(
        'Assigned to Research Desk • Next update due 14:30 UTC',
        style: const TextStyle(color: AetherColors.muted),
      ),
    );
  }

  Widget _editorZone() {
    return EnterprisePanel(
      title: 'Thesis Editor',
      subtitle:
          'Draft, validate, and publish desk-level prediction intelligence.',
      trailing: Wrap(
        spacing: AetherSpacing.sm,
        children: [
          StatusBadge(label: _draftState),
          ActionStateButton(
            label: 'Save Draft',
            state: _saveState,
            onPressed: _saveDraft,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 300,
            child: TextField(
              controller: _thesisController,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText:
                    'Write thesis, invalidation criteria, catalysts, and forecasting notes...',
              ),
            ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          EnterpriseDataTable<_EvidenceItem>(
            title: 'Evidence Intake',
            subtitle: 'Source validation queue with confidence scoring.',
            rows: const [
              _EvidenceItem('ETF Flow Tape', 'Net inflow acceleration', 0.89),
              _EvidenceItem(
                  'On-chain Monitor', 'Active address recovery', 0.81),
              _EvidenceItem('Funding Basis', 'Crowding risk elevated', 0.67),
              _EvidenceItem('Macro Liquidity', 'Impulse flattening', 0.62),
            ],
            rowId: (row) => row.source,
            searchHint: 'Search evidence intake',
            filters: [
              EnterpriseTableFilter(
                label: 'High Confidence',
                predicate: (row) => row.confidence >= 0.8,
              ),
            ],
            columns: [
              EnterpriseTableColumn(
                label: 'Source',
                width: 180,
                cell: (row) => row.source,
                sortValue: (row) => row.source,
              ),
              EnterpriseTableColumn(
                label: 'Signal',
                width: 260,
                cell: (row) => row.signal,
                sortValue: (row) => row.signal,
              ),
              EnterpriseTableColumn(
                label: 'Confidence',
                width: 100,
                numeric: true,
                cell: (row) => '${(row.confidence * 100).toStringAsFixed(1)}%',
                sortValue: (row) => row.confidence,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightZone() {
    return Column(
      children: [
        EnterprisePanel(
          title: 'AI Insight Snapshot',
          subtitle: 'Current model interpretation and confidence posture.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              StatusBadge(label: '84% confidence'),
              SizedBox(height: AetherSpacing.sm),
              Text(
                  'Positive factors: ETF flows, participation recovery, implied vol compression.'),
              SizedBox(height: AetherSpacing.sm),
              Text(
                  'Risks: regulatory headline uncertainty, macro liquidity inflection.'),
            ],
          ),
        ),
        const SizedBox(height: AetherSpacing.lg),
        EnterpriseDataTable<_ModelRunRow>(
          title: 'Model Health',
          subtitle: 'Recent inference runs and output quality checks.',
          rows: const [
            _ModelRunRow('run_20260408_1410', 'Completed', 1320, 0.92),
            _ModelRunRow('run_20260408_1352', 'Completed', 1284, 0.90),
            _ModelRunRow('run_20260408_1328', 'Warning', 2114, 0.74),
            _ModelRunRow('run_20260408_1305', 'Completed', 1402, 0.88),
          ],
          rowId: (row) => row.runId,
          searchHint: 'Search model run id',
          filters: [
            EnterpriseTableFilter(
              label: 'Warnings',
              predicate: (row) => row.status == 'Warning',
            ),
          ],
          columns: [
            EnterpriseTableColumn(
              label: 'Run ID',
              width: 170,
              cell: (row) => row.runId,
              sortValue: (row) => row.runId,
            ),
            EnterpriseTableColumn(
              label: 'Status',
              width: 90,
              cell: (row) => row.status,
              sortValue: (row) => row.status,
            ),
            EnterpriseTableColumn(
              label: 'Latency',
              width: 80,
              numeric: true,
              cell: (row) => '${row.latencyMs} ms',
              sortValue: (row) => row.latencyMs,
            ),
            EnterpriseTableColumn(
              label: 'Quality',
              width: 70,
              numeric: true,
              cell: (row) => '${(row.quality * 100).toStringAsFixed(0)}%',
              sortValue: (row) => row.quality,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveDraft() async {
    if (_saveState == ActionButtonState.loading) return;

    setState(() {
      _saveState = ActionButtonState.loading;
      _draftState = 'Saving...';
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _saveState = ActionButtonState.success;
      _draftState = 'Saved just now';
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _saveState = ActionButtonState.idle;
    });
  }
}

class _ResearchWatchRow {
  const _ResearchWatchRow(this.title, this.domain, this.priority);

  final String title;
  final String domain;
  final String priority;
}

class _EvidenceItem {
  const _EvidenceItem(this.source, this.signal, this.confidence);

  final String source;
  final String signal;
  final double confidence;
}

class _ModelRunRow {
  const _ModelRunRow(this.runId, this.status, this.latencyMs, this.quality);

  final String runId;
  final String status;
  final int latencyMs;
  final double quality;
}
