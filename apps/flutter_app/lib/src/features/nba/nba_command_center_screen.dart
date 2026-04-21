import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/nba_models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/market_chart.dart';

enum NbaSection {
  overview,
  liveGames,
  markets,
  myPredictions,
  aiAgents,
  news,
  leaderboard,
  strategyLab,
}

class NbaCommandCenterScreen extends ConsumerStatefulWidget {
  const NbaCommandCenterScreen({
    super.key,
    required this.section,
  });

  final NbaSection section;

  @override
  ConsumerState<NbaCommandCenterScreen> createState() =>
      _NbaCommandCenterScreenState();
}

class _NbaCommandCenterScreenState
    extends ConsumerState<NbaCommandCenterScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '100');
  final TextEditingController _promptController = TextEditingController(
    text: 'Predict Lakers vs Warriors using last 5 games and injury data',
  );
  int? _selectedMarketId;
  String _selectedSide = 'YES';
  double _confidenceLevel = 72;
  bool _automationEnabled = false;
  String _riskLevel = 'balanced';
  bool _executing = false;
  bool _loadingPreview = false;
  StrategyPreviewModel? _preview;

  @override
  void dispose() {
    _amountController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeValue = ref.watch(platformHomeProvider);
    final portfolioValue = ref.watch(portfolioProvider);

    return AppScaffold(
      title: _title(widget.section),
      subtitle: _subtitle(widget.section),
      child: homeValue.when(
        data: (home) {
          final selectedMarket = _resolveSelectedMarket(home);
          final positions = portfolioValue.maybeWhen(
            data: (items) => items,
            orElse: () => const <PortfolioPosition>[],
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1180;
              final main = _buildSectionContent(
                context,
                home,
                selectedMarket,
                positions,
              );
              final side = _buildRightRail(home, selectedMarket);
              return compact
                  ? ListView(
                      children: [
                        _buildOverviewStrip(home.overview),
                        const SizedBox(height: AetherSpacing.lg),
                        main,
                        const SizedBox(height: AetherSpacing.lg),
                        side,
                      ],
                    )
                  : Column(
                      children: [
                        _buildOverviewStrip(home.overview),
                        const SizedBox(height: AetherSpacing.lg),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: main),
                              const SizedBox(width: AetherSpacing.lg),
                              SizedBox(width: 360, child: side),
                            ],
                          ),
                        ),
                      ],
                    );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Surface(
          child: Text(
            'Unable to load NBA platform data: $error',
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent(
    BuildContext context,
    PlatformHomeModel home,
    NbaMarket selectedMarket,
    List<PortfolioPosition> positions,
  ) {
    switch (widget.section) {
      case NbaSection.liveGames:
        return ListView(
          children: [
            _sectionLabel('Live Games'),
            const SizedBox(height: AetherSpacing.md),
            ...home.liveGames.map(_liveGameCard),
            const SizedBox(height: AetherSpacing.lg),
            _sectionLabel('Attached Markets'),
            const SizedBox(height: AetherSpacing.md),
            ...home.markets.take(3).map((market) => Padding(
                  padding: const EdgeInsets.only(bottom: AetherSpacing.md),
                  child: _marketCard(market, selectable: true),
                )),
            const SizedBox(height: AetherSpacing.lg),
            _bottomPanels(home),
          ],
        );
      case NbaSection.markets:
        return ListView(
          children: [
            _sectionLabel('NBA Markets'),
            const SizedBox(height: AetherSpacing.md),
            ...home.markets.map((market) => Padding(
                  padding: const EdgeInsets.only(bottom: AetherSpacing.md),
                  child: _marketCard(market, selectable: true),
                )),
            const SizedBox(height: AetherSpacing.lg),
            _bottomPanels(home),
          ],
        );
      case NbaSection.myPredictions:
        return ListView(
          children: [
            _sectionLabel('My Predictions'),
            const SizedBox(height: AetherSpacing.md),
            _predictionsSummary(positions),
            const SizedBox(height: AetherSpacing.lg),
            if (positions.isEmpty)
              const _Surface(
                child: Text(
                  'No predictions yet. Use the right-hand ticket to create your first NBA market position.',
                ),
              )
            else
              ...positions.map((position) => Padding(
                    padding: const EdgeInsets.only(bottom: AetherSpacing.md),
                    child: _predictionCard(position),
                  )),
          ],
        );
      case NbaSection.aiAgents:
        return ListView(
          children: [
            _sectionLabel('AI Agents'),
            const SizedBox(height: AetherSpacing.md),
            ...home.agents.map(_agentCard),
          ],
        );
      case NbaSection.news:
        return ListView(
          children: [
            _sectionLabel('NBA News Feed'),
            const SizedBox(height: AetherSpacing.md),
            ...home.news.map(_newsCard),
            const SizedBox(height: AetherSpacing.lg),
            _sectionLabel('Markets Impacted Right Now'),
            const SizedBox(height: AetherSpacing.md),
            ...home.markets.take(4).map((market) => Padding(
                  padding: const EdgeInsets.only(bottom: AetherSpacing.md),
                  child: _marketCard(market, selectable: true),
                )),
          ],
        );
      case NbaSection.leaderboard:
        return ListView(
          children: [
            _sectionLabel('Prediction Leaderboard'),
            const SizedBox(height: AetherSpacing.md),
            ...home.leaderboard.map(_leaderboardCard),
          ],
        );
      case NbaSection.strategyLab:
        return ListView(
          children: [
            _sectionLabel('Build Your Strategy'),
            const SizedBox(height: AetherSpacing.md),
            _strategyBuilder(home),
            if (_preview != null) ...[
              const SizedBox(height: AetherSpacing.lg),
              _strategyPreviewCard(home),
            ],
          ],
        );
      case NbaSection.overview:
        return ListView(
          children: [
            _hero(selectedMarket, home),
            const SizedBox(height: AetherSpacing.lg),
            _sectionLabel('Featured Markets'),
            const SizedBox(height: AetherSpacing.md),
            ...home.markets.take(4).map((market) => Padding(
                  padding: const EdgeInsets.only(bottom: AetherSpacing.md),
                  child: _marketCard(market, selectable: true),
                )),
            const SizedBox(height: AetherSpacing.lg),
            _bottomPanels(home),
          ],
        );
    }
  }

  Widget _buildRightRail(PlatformHomeModel home, NbaMarket selectedMarket) {
    return ListView(
      children: [
        _predictionTicket(selectedMarket),
        const SizedBox(height: AetherSpacing.lg),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _panelTitle('AI Insight'),
              const SizedBox(height: AetherSpacing.sm),
              Text(
                selectedMarket.aiInsight,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: AetherSpacing.md),
              _MiniMetric(
                label: 'Confidence',
                value:
                    '${(selectedMarket.aiConfidence * 100).toStringAsFixed(0)}%',
              ),
              _MiniMetric(
                label: 'Liquidity Score',
                value: selectedMarket.liquidityScore.toStringAsFixed(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: AetherSpacing.lg),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _panelTitle('Latest News'),
              const SizedBox(height: AetherSpacing.sm),
              ...selectedMarket.latestNews.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AetherSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill(
                            item.tag,
                            item.urgency == 'high'
                                ? AetherColors.warning
                                : AetherColors.accentSoft),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.summary,
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStrip(NbaOverview overview) {
    return Wrap(
      spacing: AetherSpacing.md,
      runSpacing: AetherSpacing.md,
      children: [
        _overviewChip('Active Markets', overview.activeMarkets.toString()),
        _overviewChip('Live Games', overview.liveGames.toString()),
        _overviewChip(
            'Model Accuracy', '${overview.modelAccuracy.toStringAsFixed(1)}%'),
        _overviewChip('Liquidity', _usd(overview.totalLiquidity)),
        _overviewChip('Open Predictions', overview.openPredictions.toString()),
        _overviewChip('ROI',
            '${overview.predictionRoi >= 0 ? '+' : ''}${overview.predictionRoi.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _hero(NbaMarket selectedMarket, PlatformHomeModel home) {
    return _Surface(
      background: const LinearGradient(
        colors: [Color(0xFF11263D), Color(0xFF1A3C57)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pill('Featured Market', AetherColors.accentSoft),
          const SizedBox(height: AetherSpacing.md),
          Text(
            selectedMarket.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AetherSpacing.sm),
          Text(
            'A clean NBA-first prediction surface with real-time game context, probability movement, team comparison, and execution controls.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFD1DDED),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: MarketChart(points: selectedMarket.probabilityPoints),
                ),
              ),
              const SizedBox(width: AetherSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    _MiniMetric(
                      label: selectedMarket.yesLabel,
                      value:
                          '${(selectedMarket.yesProbability * 100).toStringAsFixed(1)}%',
                    ),
                    _MiniMetric(
                      label: selectedMarket.noLabel,
                      value:
                          '${(selectedMarket.noProbability * 100).toStringAsFixed(1)}%',
                    ),
                    _MiniMetric(
                      label: 'News Signals',
                      value: selectedMarket.latestNews.length.toString(),
                    ),
                    _MiniMetric(
                      label: 'Tracked Agents',
                      value: home.agents.length.toString(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomPanels(PlatformHomeModel home) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        final children = [
          Expanded(child: _liquidityPanel(home.markets.take(4).toList())),
          Expanded(child: _activityPanel('Activity Feed', home.activityFeed)),
          Expanded(
            child: _activityPanel(
              'Recent Predictions',
              home.recentPredictions,
            ),
          ),
        ];
        if (compact) {
          return Column(
            children: [
              _liquidityPanel(home.markets.take(4).toList()),
              const SizedBox(height: AetherSpacing.md),
              _activityPanel('Activity Feed', home.activityFeed),
              const SizedBox(height: AetherSpacing.md),
              _activityPanel('Recent Predictions', home.recentPredictions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            children[0],
            const SizedBox(width: AetherSpacing.md),
            children[1],
            const SizedBox(width: AetherSpacing.md),
            children[2],
          ],
        );
      },
    );
  }

  Widget _liquidityPanel(List<NbaMarket> markets) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Liquidity Metrics'),
          const SizedBox(height: AetherSpacing.md),
          ...markets.map((market) => Padding(
                padding: const EdgeInsets.only(bottom: AetherSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(market.title)),
                    Text(
                      'Spread ${market.spreadBps.toStringAsFixed(0)} bps',
                      style: const TextStyle(color: AetherColors.muted),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _activityPanel(String title, List<NbaPredictionActivity> items) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(title),
          const SizedBox(height: AetherSpacing.md),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AetherSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.user} picked ${item.pick} on ${item.market}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.confidence} • ${_usd(item.amount)}',
                      style: const TextStyle(color: AetherColors.muted),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _predictionTicket(NbaMarket market) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Predict Win / Lose'),
          const SizedBox(height: AetherSpacing.sm),
          Text(
            market.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AetherSpacing.md),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'YES', label: Text(market.yesLabel)),
                    ButtonSegment(value: 'NO', label: Text(market.noLabel)),
                  ],
                  selected: {_selectedSide},
                  onSelectionChanged: (value) {
                    setState(() {
                      _selectedSide = value.first;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AetherSpacing.md),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Input amount',
              prefixText: '\$',
            ),
          ),
          const SizedBox(height: AetherSpacing.md),
          Text(
            'Confidence level ${_confidenceLevel.toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _confidenceLevel,
            min: 50,
            max: 95,
            onChanged: (value) {
              setState(() {
                _confidenceLevel = value;
              });
            },
          ),
          const SizedBox(height: AetherSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Price',
                  value:
                      '${((_selectedSide == 'YES' ? market.yesProbability : market.noProbability) * 100).toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: AetherSpacing.sm),
              Expanded(
                child: _MiniMetric(
                  label: 'Slippage',
                  value: '${market.slippage.toStringAsFixed(2)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AetherSpacing.md),
          FilledButton(
            onPressed: _executing ? null : () => _executePrediction(market),
            child: Text(_executing ? 'Executing...' : 'Execute Prediction'),
          ),
        ],
      ),
    );
  }

  Widget _strategyBuilder(PlatformHomeModel home) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _promptController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Natural language prompt',
              hintText:
                  'Predict Lakers vs Warriors using last 5 games and injury data',
            ),
          ),
          const SizedBox(height: AetherSpacing.md),
          const Wrap(
            spacing: AetherSpacing.sm,
            runSpacing: AetherSpacing.sm,
            children: [
              _StaticChoice(label: 'Stats'),
              _StaticChoice(label: 'News'),
              _StaticChoice(label: 'History'),
            ],
          ),
          const SizedBox(height: AetherSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _riskLevel,
            items: const [
              DropdownMenuItem(
                  value: 'conservative', child: Text('Conservative')),
              DropdownMenuItem(value: 'balanced', child: Text('Balanced')),
              DropdownMenuItem(value: 'aggressive', child: Text('Aggressive')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _riskLevel = value;
              });
            },
            decoration: const InputDecoration(labelText: 'Risk level'),
          ),
          const SizedBox(height: AetherSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _automationEnabled,
            title: const Text('Automation toggle'),
            subtitle:
                const Text('Allow strategy execution after preview approval.'),
            onChanged: (value) {
              setState(() {
                _automationEnabled = value;
              });
            },
          ),
          const SizedBox(height: AetherSpacing.md),
          FilledButton(
            onPressed: _loadingPreview ? null : _buildStrategyPreview,
            child: Text(_loadingPreview ? 'Building...' : 'Generate Strategy'),
          ),
        ],
      ),
    );
  }

  Widget _strategyPreviewCard(PlatformHomeModel home) {
    final preview = _preview!;
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Strategy Preview'),
          const SizedBox(height: AetherSpacing.sm),
          Text(
            preview.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(preview.summary),
          const SizedBox(height: AetherSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Predicted Probability',
                  value: '${(preview.probability * 100).toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: AetherSpacing.sm),
              Expanded(
                child: _MiniMetric(
                  label: 'Confidence',
                  value: '${(preview.confidence * 100).toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AetherSpacing.md),
          const Text('Rationale',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...preview.rationale.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $item'),
              )),
          const SizedBox(height: AetherSpacing.md),
          const Text('Safeguards',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...preview.safeguards.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $item'),
              )),
          if (preview.executionReady && preview.suggestedMarketId != null) ...[
            const SizedBox(height: AetherSpacing.md),
            FilledButton(
              onPressed: () {
                setState(() {
                  _selectedMarketId = preview.suggestedMarketId;
                });
              },
              child: const Text('Load Suggested Market'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _marketCard(NbaMarket market, {required bool selectable}) {
    final selected = market.id == _selectedMarketId;
    return InkWell(
      onTap: selectable
          ? () {
              setState(() {
                _selectedMarketId = market.id;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(AetherRadii.lg),
      child: _Surface(
        borderColor: selected ? AetherColors.accent : AetherColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AetherSpacing.sm,
              runSpacing: AetherSpacing.sm,
              children: [
                _pill(market.category, AetherColors.accentSoft),
                _pill(market.confidenceLabel, AetherColors.bgPanel),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            Text(
              market.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              market.matchup,
              style: const TextStyle(color: AetherColors.muted),
            ),
            const SizedBox(height: AetherSpacing.md),
            SizedBox(
                height: 120,
                child: MarketChart(points: market.probabilityPoints)),
            const SizedBox(height: AetherSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: market.yesLabel,
                    value:
                        '${(market.yesProbability * 100).toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: AetherSpacing.sm),
                Expanded(
                  child: _MiniMetric(
                    label: market.noLabel,
                    value:
                        '${(market.noProbability * 100).toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            Wrap(
              spacing: AetherSpacing.sm,
              runSpacing: AetherSpacing.sm,
              children: [
                _pill('Spread ${market.spreadBps.toStringAsFixed(0)} bps',
                    AetherColors.bgPanel),
                _pill('Depth ${_usd(market.depth)}', AetherColors.bgPanel),
                _pill('Liquidity ${market.liquidityScore.toStringAsFixed(1)}',
                    AetherColors.bgPanel),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            if (market.teamForm.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: _comparisonBlock(
                      market.teamForm['home_team']?.toString() ?? 'Home',
                      market.teamForm['home_record_last_5']?.toString() ?? '--',
                    ),
                  ),
                  const SizedBox(width: AetherSpacing.sm),
                  Expanded(
                    child: _comparisonBlock(
                      market.teamForm['away_team']?.toString() ?? 'Away',
                      market.teamForm['away_record_last_5']?.toString() ?? '--',
                    ),
                  ),
                ],
              ),
            if (market.latestNews.isNotEmpty) ...[
              const SizedBox(height: AetherSpacing.md),
              Text(
                'Latest News: ${market.latestNews.first.title}',
                style: const TextStyle(
                  color: AetherColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _predictionCard(PortfolioPosition position) {
    return _Surface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.marketTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick ${position.side} • ${position.size.toStringAsFixed(0)} shares',
                  style: const TextStyle(color: AetherColors.muted),
                ),
              ],
            ),
          ),
          _MiniMetric(
            label: 'PnL',
            value: _usd(position.pnl),
          ),
        ],
      ),
    );
  }

  Widget _predictionsSummary(List<PortfolioPosition> positions) {
    final exposure = positions.fold<double>(
      0,
      (sum, row) => sum + (row.size * row.markPrice),
    );
    final pnl = positions.fold<double>(0, (sum, row) => sum + row.pnl);
    return Row(
      children: [
        Expanded(
          child: _Surface(
            child: _MiniMetric(
              label: 'Open Exposure',
              value: _usd(exposure),
            ),
          ),
        ),
        const SizedBox(width: AetherSpacing.md),
        Expanded(
          child: _Surface(
            child: _MiniMetric(
              label: 'Current PnL',
              value: _usd(pnl),
            ),
          ),
        ),
      ],
    );
  }

  Widget _liveGameCard(NbaLiveGame game) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.md),
      child: _Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _pill(game.status, AetherColors.bgPanel),
                const Spacer(),
                Text(
                  '${(game.winProbabilityHome * 100).toStringAsFixed(0)}% ${game.homeTeam}',
                  style: const TextStyle(color: AetherColors.accent),
                ),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            Text(
              game.matchup,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${game.homeTeam} ${game.homeScore} - ${game.awayScore} ${game.awayTeam}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              game.headline,
              style: const TextStyle(color: AetherColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _agentCard(NbaAgent agent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.md),
      child: _Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  agent.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                _pill(agent.status.toUpperCase(), AetherColors.bgPanel),
              ],
            ),
            const SizedBox(height: 8),
            Text(agent.specialty,
                style: const TextStyle(color: AetherColors.muted)),
            const SizedBox(height: AetherSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Accuracy',
                    value:
                        '${(agent.historicalAccuracy * 100).toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: AetherSpacing.sm),
                Expanded(
                  child: _MiniMetric(
                    label: 'ROI',
                    value: '${agent.roi.toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: AetherSpacing.sm),
                Expanded(
                  child: _MiniMetric(
                    label: 'Markets',
                    value: agent.activeMarkets.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            Text(agent.summary),
            const SizedBox(height: 8),
            Text(
              agent.recommendation,
              style: const TextStyle(color: AetherColors.warning),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newsCard(NbaNewsItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.md),
      child: _Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _pill(item.tag, AetherColors.bgPanel),
                const Spacer(),
                Text(
                  item.source,
                  style: const TextStyle(color: AetherColors.muted),
                ),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(item.summary),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardCard(NbaLeaderboardEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.md),
      child: _Surface(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AetherColors.bgPanel,
              child: Text('#${entry.rank}'),
            ),
            const SizedBox(width: AetherSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${entry.predictions} predictions • ${entry.streak} streak',
                    style: const TextStyle(color: AetherColors.muted),
                  ),
                ],
              ),
            ),
            _MiniMetric(
              label: 'Accuracy',
              value: '${entry.accuracy.toStringAsFixed(1)}%',
            ),
            const SizedBox(width: AetherSpacing.sm),
            _MiniMetric(
              label: 'ROI',
              value: '${entry.roi.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonBlock(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AetherSpacing.md),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(AetherRadii.md),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _overviewChip(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AetherSpacing.md,
        vertical: AetherSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AetherColors.bgElevated,
        borderRadius: BorderRadius.circular(AetherRadii.lg),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AetherColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _panelTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }

  Future<void> _executePrediction(NbaMarket market) async {
    final apiClient = ref.read(apiClientProvider);
    final wallet = ref.read(walletSessionProvider);
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount to execute.')),
      );
      return;
    }

    setState(() {
      _executing = true;
    });
    try {
      await apiClient.placePrediction(
        marketId: market.id,
        side: _selectedSide,
        collateralAmount: amount,
        price: _selectedSide == 'YES'
            ? market.yesProbability
            : market.noProbability,
        walletAddress: wallet.address ?? 'demo-wallet',
      );
      ref.invalidate(platformHomeProvider);
      ref.invalidate(portfolioProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Prediction executed for ${market.title} in MVP settlement mode.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Execution failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _executing = false;
        });
      }
    }
  }

  Future<void> _buildStrategyPreview() async {
    setState(() {
      _loadingPreview = true;
    });
    try {
      final preview = await ref.read(apiClientProvider).previewStrategy(
            prompt: _promptController.text,
            dataSources: const ['stats', 'news', 'history'],
            riskLevel: _riskLevel,
            automationEnabled: _automationEnabled,
          );
      if (mounted) {
        setState(() {
          _preview = preview;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingPreview = false;
        });
      }
    }
  }

  NbaMarket _resolveSelectedMarket(PlatformHomeModel home) {
    if (home.markets.isEmpty) {
      throw StateError('No NBA markets available.');
    }
    final targetId =
        _selectedMarketId ?? home.featuredMarketId ?? home.markets.first.id;
    return home.markets.firstWhere(
      (market) => market.id == targetId,
      orElse: () => home.markets.first,
    );
  }

  String _title(NbaSection section) {
    switch (section) {
      case NbaSection.overview:
        return 'Overview';
      case NbaSection.liveGames:
        return 'Live Games';
      case NbaSection.markets:
        return 'Markets';
      case NbaSection.myPredictions:
        return 'My Predictions';
      case NbaSection.aiAgents:
        return 'AI Agents';
      case NbaSection.news:
        return 'News';
      case NbaSection.leaderboard:
        return 'Leaderboard';
      case NbaSection.strategyLab:
        return 'Strategy Lab';
    }
  }

  String _subtitle(NbaSection section) {
    switch (section) {
      case NbaSection.overview:
        return 'NBA prediction intelligence across games, player props, season events, and execution.';
      case NbaSection.liveGames:
        return 'Real-time score context and in-game probability movement.';
      case NbaSection.markets:
        return 'Focused NBA markets with clean probability, depth, and news context.';
      case NbaSection.myPredictions:
        return 'Track active positions, exposure, and current prediction performance.';
      case NbaSection.aiAgents:
        return 'Specialized agents for game, player, news, and custom strategy analysis.';
      case NbaSection.news:
        return 'A dedicated NBA news stream connected directly to market movement.';
      case NbaSection.leaderboard:
        return 'Rankings based on accuracy, ROI, and consistency.';
      case NbaSection.strategyLab:
        return 'Build prompt-driven NBA strategies with preview and execution hooks.';
    }
  }

  String _usd(double value) => '\$${value.toStringAsFixed(0)}';
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.background,
    this.borderColor,
  });

  final Widget child;
  final Gradient? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AetherSpacing.lg),
      decoration: BoxDecoration(
        gradient: background,
        color: background == null ? AetherColors.bgElevated : null,
        borderRadius: BorderRadius.circular(AetherRadii.lg),
        border: Border.all(color: borderColor ?? AetherColors.border),
      ),
      child: child,
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AetherSpacing.md),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(AetherRadii.md),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StaticChoice extends StatelessWidget {
  const _StaticChoice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
