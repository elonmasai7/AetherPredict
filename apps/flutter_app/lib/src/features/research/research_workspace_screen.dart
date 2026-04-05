import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class ResearchWorkspaceScreen extends StatefulWidget {
  const ResearchWorkspaceScreen({super.key});

  @override
  State<ResearchWorkspaceScreen> createState() => _ResearchWorkspaceScreenState();
}

class _ResearchWorkspaceScreenState extends State<ResearchWorkspaceScreen> {
  final _notes = TextEditingController(text: 'Thesis: ETF-driven liquidity expansion supports BTC upside skew through Q4.\n\nEvidence:\n- Net inflows accelerating\n- Basis spread tightening\n- On-chain active addresses recovering\n');

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 1200;

    return AppScaffold(
      title: 'Research Workspace',
      child: compact
          ? ListView(
              children: [
                _watchlistPanel(),
                const SizedBox(height: 16),
                _editorPanel(),
                const SizedBox(height: 16),
                _insightsPanel(),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 300, child: _watchlistPanel()),
                const SizedBox(width: 16),
                Expanded(child: _editorPanel()),
                const SizedBox(width: 16),
                SizedBox(width: 340, child: _insightsPanel()),
              ],
            ),
    );
  }

  Widget _watchlistPanel() {
    const watchlist = [
      'BTC > 120k before Dec 31 2026',
      'HashKey Chain TVL > 50M by Q3',
      'ETH ETF volume doubles by year end',
      'SOL staking APR remains above 7%',
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Watchlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...watchlist.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AetherColors.border),
                color: AetherColors.bgPanel,
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_outline, size: 16, color: AetherColors.muted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Market')),
        ],
      ),
    );
  }

  Widget _editorPanel() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Private Notes & Thesis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.attach_file), label: const Text('Attach Evidence')),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.save_outlined), label: const Text('Save Strategy')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _notes,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write market thesis, catalysts, invalidation criteria, and trade plan...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightsPanel() {
    const positives = ['ETF inflows +18%', 'Volume momentum +12%', 'Open interest improving'];
    const negatives = ['Regulatory uncertainty -5%', 'Funding rate crowding risk'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Confidence 84%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Positive Factors', style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 8),
          ...positives.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('+ $p', style: const TextStyle(color: AetherColors.success)),
              )),
          const SizedBox(height: 10),
          const Text('Negative Factors', style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 8),
          ...negatives.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('- $n', style: const TextStyle(color: AetherColors.warning)),
              )),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Reasoning Chain', style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 8),
          const Text('Macro liquidity regime remains constructive. On-chain participation supports continuation with moderate drawdown risk.'),
        ],
      ),
    );
  }
}
