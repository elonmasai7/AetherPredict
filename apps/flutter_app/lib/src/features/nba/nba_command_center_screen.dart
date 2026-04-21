import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
  strategyLab,
  news,
  leaderboard,
}

class NbaCommandCenterScreen extends ConsumerStatefulWidget {
  const NbaCommandCenterScreen({super.key, required this.section});

  final NbaSection section;

  @override
  ConsumerState<NbaCommandCenterScreen> createState() =>
      _NbaCommandCenterScreenState();
}

class _NbaCommandCenterScreenState
    extends ConsumerState<NbaCommandCenterScreen> {
  final _amountController = TextEditingController(text: '100');
  final _strategyController = TextEditingController(
    text: 'Predict Lakers vs Warriors using last 5 games and injuries',
  );
  final List<String> _localLogs = [];

  Timer? _refreshTimer;
  int? _selectedMarketId;
  String _selectedSide = 'YES';
  double _confidenceLevel = 70;
  final bool _automationEnabled = false;
  final String _riskLevel = 'balanced';
  bool _executing = false;
  bool _loadingAi = false;
  bool _loadingStrategy = false;
  bool _drawerExpanded = true;
  int _drawerTabIndex = 0;
  AiPredictionModel? _aiSuggestion;
  StrategyPreviewModel? _strategyPreview;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      ref.invalidate(platformHomeProvider);
      if (_selectedMarketId != null) {
        ref.invalidate(liquidityBookProvider(_selectedMarketId!));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _amountController.dispose();
    _strategyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeValue = ref.watch(platformHomeProvider);
    final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

    return AppScaffold(
      title: _title(widget.section),
      subtitle: _subtitle(widget.section),
      headerBottom: homeValue.maybeWhen(
        data: (home) => _TerminalTickerBar(items: _tickerItems(home)),
        orElse: () => const SizedBox.shrink(),
      ),
      sidebarFooter: homeValue.maybeWhen(
        data: (home) => _sidebarMetricsPanel(home),
        orElse: () => const SizedBox.shrink(),
      ),
      child: homeValue.when(
        data: (home) {
          final filteredGames =
              _filterGames(home.liveGames, home.markets, searchQuery);
          final selectedMarket = _selectedMarket(home, filteredGames);
          final selectedGame = _selectedGame(filteredGames, selectedMarket);
          final newsFeed = _newsFeed(home, selectedMarket, selectedGame);
          final terminalLogs = _buildTerminalLogs(home, selectedMarket);

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1400;
              if (compact) {
                return _compactLayout(
                  home,
                  filteredGames,
                  selectedMarket,
                  selectedGame,
                  newsFeed,
                  terminalLogs,
                );
              }

              return Column(
                children: [
                  _topStatsStrip(home, selectedMarket, selectedGame),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 292,
                                      child: _liveGameBoard(
                                        filteredGames,
                                        home.markets,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _probabilityTerminal(
                                        home,
                                        selectedMarket,
                                        selectedGame,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: _newsEventPanel(
                                        newsFeed,
                                        selectedMarket,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 4,
                                      child: _executionPanel(
                                        home,
                                        selectedMarket,
                                        selectedGame,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _intelligenceDrawer(home, selectedMarket),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _terminalLogBar(terminalLogs),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _terminalPanel(
          title: 'SYSTEM STATUS',
          subtitle: 'Workspace unavailable',
          child: Text(
            'Unable to load platform data: $error',
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Widget _compactLayout(
    PlatformHomeModel home,
    List<NbaLiveGame> games,
    NbaMarket market,
    NbaLiveGame? selectedGame,
    List<_FeedEntry> newsFeed,
    List<String> terminalLogs,
  ) {
    return ListView(
      children: [
        _topStatsStrip(home, market, selectedGame),
        const SizedBox(height: 8),
        SizedBox(height: 300, child: _liveGameBoard(games, home.markets)),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: _probabilityTerminal(home, market, selectedGame),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 300, child: _newsEventPanel(newsFeed, market)),
        const SizedBox(height: 8),
        _executionPanel(home, market, selectedGame),
        const SizedBox(height: 8),
        _intelligenceDrawer(home, market, compact: true),
        const SizedBox(height: 8),
        _terminalLogBar(terminalLogs),
      ],
    );
  }

  Widget _sidebarMetricsPanel(PlatformHomeModel home) {
    final aiSignals =
        home.agents.where((agent) => agent.confidence >= 0.7).length;
    final alertCount =
        home.news.where((item) => item.urgency.toLowerCase() != 'low').length;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        border: Border.all(color: AetherColors.accentSoft),
        borderRadius: BorderRadius.circular(AetherRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIVE METRICS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.9,
              color: AetherColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _sidebarMetricRow('Active Games', '${home.liveGames.length}'),
          _sidebarMetricRow('Open Markets', '${home.markets.length}'),
          _sidebarMetricRow('AI Signals', '$aiSignals'),
          _sidebarMetricRow('News Alerts', '$alertCount'),
        ],
      ),
    );
  }

  Widget _sidebarMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AetherColors.muted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AetherColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topStatsStrip(
    PlatformHomeModel home,
    NbaMarket market,
    NbaLiveGame? game,
  ) {
    final volatility = _marketVolatility(market);
    final momentum = _marketMovement(market);
    final liveCount =
        home.liveGames.where((item) => item.status != 'Pre-game').length;

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: _metricBlock(
                'TOTAL VOLUME',
                _usd(home.markets.fold(
                  0,
                  (sum, item) => sum + item.volume,
                ))),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _metricBlock(
              'OPEN INTEREST',
              '${home.overview.openPredictions}',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _metricBlock(
              'AVG SPREAD',
              '${_avgSpread(home.markets).toStringAsFixed(1)} bps',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _metricBlock(
                'ACTIVE MARKETS', '${home.overview.activeMarkets}'),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _metricBlock(
              'AI ACCURACY',
              '${(home.overview.modelAccuracy * 100).toStringAsFixed(1)}%',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _metricBlock(
              'LIVE FLOW',
              '$liveCount live • ${momentum >= 0 ? '+' : ''}${momentum.toStringAsFixed(1)}%',
              valueColor:
                  momentum >= 0 ? AetherColors.success : AetherColors.critical,
              footer:
                  'VOL ${volatility.toStringAsFixed(1)} • ${game?.status ?? market.category}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBlock(
    String label,
    String value, {
    Color? valueColor,
    String? footer,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border.all(color: AetherColors.accentSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AetherColors.accent,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AetherColors.text,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 2),
            Text(
              footer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AetherColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _liveGameBoard(List<NbaLiveGame> games, List<NbaMarket> markets) {
    return _terminalPanel(
      title: 'LIVE GAMES',
      subtitle: '${games.length} tracked matchups',
      child: games.isEmpty
          ? const Center(
              child: Text(
                'No live NBA games match the current search.',
                style: TextStyle(fontSize: 12, color: AetherColors.muted),
              ),
            )
          : ListView.separated(
              itemCount: games.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final game = games[index];
                final market = _marketForGame(game, markets);
                final selected =
                    market != null && market.id == _selectedMarketId;
                final liveClock = _gameClock(game);
                final probability =
                    market?.yesProbability ?? game.winProbabilityHome;
                final scoreGap = game.homeScore - game.awayScore;

                return InkWell(
                  onTap: market == null
                      ? null
                      : () {
                          setState(() {
                            _selectedMarketId = market.id;
                            _selectedSide = 'YES';
                          });
                          _appendLocalLog('watchlist focus ${market.matchup}');
                        },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AetherColors.bgPanel
                          : AetherColors.bgElevated,
                      border: Border.all(
                        color: selected
                            ? AetherColors.accent
                            : AetherColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        _gameTeamRow(
                          label: game.teamA,
                          score: game.homeScore,
                          highlight: scoreGap >= 0,
                        ),
                        const SizedBox(height: 4),
                        _gameTeamRow(
                          label: game.teamB,
                          score: game.awayScore,
                          highlight: scoreGap < 0,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                liveClock,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AetherColors.muted,
                                ),
                              ),
                            ),
                            Text(
                              'Win ${(probability * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: probability >= 0.5
                                    ? AetherColors.success
                                    : AetherColors.critical,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Spr ${(market?.spreadBps ?? 0).toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AetherColors.warning,
                                ),
                              ),
                            ),
                            Text(
                              'AI ${(((market?.aiConfidence ?? 0) * 100)).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF43D4FF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _gameTeamRow({
    required String label,
    required int score,
    required bool highlight,
  }) {
    return Row(
      children: [
        _teamLogo(label),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _teamCode(label),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? AetherColors.text : AetherColors.muted,
            ),
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: highlight ? AetherColors.text : AetherColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _probabilityTerminal(
    PlatformHomeModel home,
    NbaMarket market,
    NbaLiveGame? game,
  ) {
    final movement = _marketMovement(market);
    final volatility = _marketVolatility(market);
    final markers = _signalMarkerIndexes(market);
    final tape = _predictionTape(home, market);

    return _terminalPanel(
      title: 'PROBABILITY TERMINAL',
      subtitle: '${market.matchup} • ${game?.status ?? market.category}',
      headerTrailing: _terminalBadge(
        market.confidenceLabel,
        color: AetherColors.accent,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _microMetric(
                  'SPREAD',
                  '${market.spreadBps.toStringAsFixed(1)} bps',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _microMetric('LIQ', _usd(market.liquidity)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _microMetric(
                  'CONF',
                  '${(market.aiConfidence * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _microMetric(
                  'VOL',
                  volatility.toStringAsFixed(1),
                  valueColor: volatility >= 4
                      ? AetherColors.warning
                      : AetherColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AetherColors.bg,
                border: Border.all(color: AetherColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${market.yesLabel} WIN PROBABILITY',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AetherColors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(market.yesProbability * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: movement >= 0
                              ? AetherColors.success
                              : AetherColors.critical,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: MarketChart(
                      points: market.probabilityPoints,
                      lineColor: const Color(0xFF43D4FF),
                      bandColor: const Color(0xFF43D4FF),
                      markerIndexes: markers,
                      showGrid: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Momentum ${movement >= 0 ? '+' : ''}${movement.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: movement >= 0
                                ? AetherColors.success
                                : AetherColors.critical,
                          ),
                        ),
                      ),
                      Text(
                        'AI band ${(market.aiConfidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AetherColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIVE PREDICTION TAPE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AetherColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tape.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final entry = tape[index];
                      return Container(
                        width: 164,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AetherColors.bg,
                          border: Border.all(color: AetherColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.user,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.pick} • ${_usd(entry.amount)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AetherColors.muted,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              entry.market,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AetherColors.accent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsEventPanel(List<_FeedEntry> feed, NbaMarket market) {
    return _terminalPanel(
      title: 'LIVE SPORTS NEWS',
      subtitle: 'Breaking headlines, alerts, and event flow',
      child: ListView.separated(
        itemCount: feed.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final entry = feed[index];
          return InkWell(
            onTap: entry.newsItem != null
                ? () {
                    _appendLocalLog('news drilldown ${entry.title}');
                    _openNews(entry.newsItem!);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AetherColors.bgElevated,
                border: Border.all(
                  color: _feedColor(entry.type).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      '[${entry.label}]',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _feedColor(entry.type),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.detail,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AetherColors.muted,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.timeLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AetherColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _executionPanel(
    PlatformHomeModel home,
    NbaMarket market,
    NbaLiveGame? game,
  ) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final price =
        _selectedSide == 'YES' ? market.yesProbability : market.noProbability;
    final expectedPayout = amount <= 0 || price <= 0 ? 0.0 : amount / price;
    final liquidityBook = ref.watch(liquidityBookProvider(market.id));

    return _terminalPanel(
      title: 'MARKET EXECUTION',
      subtitle: '${market.yesLabel} vs ${market.noLabel}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _actionTile(
                  label: market.yesLabel,
                  selected: _selectedSide == 'YES',
                  value: '${(market.yesProbability * 100).toStringAsFixed(0)}%',
                  positive: true,
                  onTap: () => setState(() => _selectedSide = 'YES'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _actionTile(
                  label: market.noLabel,
                  selected: _selectedSide == 'NO',
                  value: '${(market.noProbability * 100).toStringAsFixed(0)}%',
                  positive: false,
                  onTap: () => setState(() => _selectedSide = 'NO'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AetherColors.bg,
                    border: Border.all(color: AetherColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONFIDENCE',
                        style: TextStyle(
                          fontSize: 10,
                          color: AetherColors.accent,
                        ),
                      ),
                      Text(
                        '${_confidenceLevel.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: _confidenceLevel,
              min: 50,
              max: 95,
              activeColor: const Color(0xFF43D4FF),
              inactiveColor: AetherColors.border,
              onChanged: (value) => setState(() => _confidenceLevel = value),
            ),
          ),
          Row(
            children: [
              Expanded(
                  child: _microMetric(
                      'PROB', '${(price * 100).toStringAsFixed(1)}%')),
              const SizedBox(width: 4),
              Expanded(child: _microMetric('PAYOUT', _usd(expectedPayout))),
              const SizedBox(width: 4),
              Expanded(
                child: liquidityBook.maybeWhen(
                  data: (book) => _microMetric(
                    'SLIP',
                    '${book.spread.toStringAsFixed(2)}%',
                    valueColor: book.spread >= 0.05
                        ? AetherColors.warning
                        : AetherColors.text,
                  ),
                  orElse: () => _microMetric('SLIP', '--'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: liquidityBook.when(
              data: (book) => Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AetherColors.bg,
                  border: Border.all(color: AetherColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXECUTION DEPTH',
                      style: TextStyle(
                        fontSize: 10,
                        color: AetherColors.accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView(
                        children: [
                          _bookHeader(),
                          const SizedBox(height: 2),
                          ..._bookRows(book, market),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                '$error',
                style:
                    const TextStyle(fontSize: 11, color: AetherColors.critical),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _executing ? null : () => _predictNow(market),
                  child: Text(_executing ? 'EXECUTING' : 'PREDICT NOW'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: _loadingAi ? null : () => _useAiSuggestion(market),
                  child: Text(_loadingAi ? 'LOADING AI' : 'AI SUGGESTION'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loadingStrategy ? null : _runStrategyPreview,
                  child: Text(_loadingStrategy ? 'RUNNING' : 'AUTO STRATEGY'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AetherColors.bg,
                    border: Border.all(color: AetherColors.border),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _strategyPreview?.summary ??
                          _aiSuggestion?.reasoning.join(' ') ??
                          (game?.headline ?? market.aiInsight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AetherColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'YES BID',
            style: TextStyle(fontSize: 11, color: AetherColors.accent),
          ),
        ),
        Expanded(
          child: Text(
            'NO ASK',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AetherColors.warning),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            'HEAT',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 11, color: AetherColors.muted),
          ),
        ),
      ],
    );
  }

  List<Widget> _bookRows(LiquidityBookModel book, NbaMarket market) {
    final length = book.bids.length < book.asks.length
        ? book.bids.length
        : book.asks.length;
    final rows = <Widget>[];
    for (var i = 0; i < length; i++) {
      final bid = book.bids[i];
      final ask = book.asks[i];
      final yesPrice =
          (bid['yes_price'] as num?)?.toDouble() ?? market.yesProbability;
      final noPrice =
          (ask['no_price'] as num?)?.toDouble() ?? market.noProbability;
      final imbalance = ((yesPrice - noPrice).abs() * 100).clamp(4, 100);
      rows.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedSide = yesPrice >= noPrice ? 'YES' : 'NO';
              _amountController.text =
                  (((bid['size'] as num?)?.toDouble() ?? 100) / 4)
                      .toStringAsFixed(0);
            });
            _appendLocalLog(
              'depth focus ${_selectedSide == 'YES' ? market.yesLabel : market.noLabel}',
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${(yesPrice * 100).toStringAsFixed(1)}% x ${(bid['size'] ?? '--')}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${(noPrice * 100).toStringAsFixed(1)}% x ${(ask['size'] ?? '--')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: imbalance.toDouble(),
                      height: 6,
                      decoration: BoxDecoration(
                        color: yesPrice >= noPrice
                            ? AetherColors.success
                            : AetherColors.critical,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return rows;
  }

  Widget _actionTile({
    required String label,
    required String value,
    required bool selected,
    required bool positive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AetherColors.bgPanel : AetherColors.bgElevated,
          border: Border.all(
            color: selected
                ? (positive ? AetherColors.success : AetherColors.critical)
                : AetherColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: positive ? AetherColors.success : AetherColors.critical,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intelligenceDrawer(
    PlatformHomeModel home,
    NbaMarket market, {
    bool compact = false,
  }) {
    final width = compact ? double.infinity : (_drawerExpanded ? 288.0 : 40.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      decoration: BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border.all(color: AetherColors.accentSoft),
      ),
      child: compact || _drawerExpanded
          ? Column(
              children: [
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AetherColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'INTELLIGENCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AetherColors.accent,
                        ),
                      ),
                      const Spacer(),
                      if (!compact)
                        IconButton(
                          onPressed: () {
                            setState(() => _drawerExpanded = false);
                          },
                          icon: const Icon(Icons.chevron_right, size: 16),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: Row(
                    children: List.generate(_drawerTabs.length, (index) {
                      final selected = _drawerTabIndex == index;
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _drawerTabIndex = index),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AetherColors.bgPanel
                                  : AetherColors.bgElevated,
                              border: Border(
                                bottom: BorderSide(
                                  color: selected
                                      ? AetherColors.accent
                                      : AetherColors.border,
                                  width: 1.2,
                                ),
                              ),
                            ),
                            child: Text(
                              _drawerTabs[index],
                              style: TextStyle(
                                fontSize: 9,
                                color: selected
                                    ? AetherColors.text
                                    : AetherColors.muted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _drawerContent(home, market),
                  ),
                ),
              ],
            )
          : Center(
              child: IconButton(
                onPressed: () => setState(() => _drawerExpanded = true),
                icon: const Icon(Icons.chevron_left, size: 18),
              ),
            ),
    );
  }

  Widget _drawerContent(PlatformHomeModel home, NbaMarket market) {
    switch (_drawerTabIndex) {
      case 0:
        return _aiSignalsPanel(home, market);
      case 1:
        return _playerStatsPanel(market);
      case 2:
        return _teamTrendsPanel(market);
      case 3:
        return _injuryAlertsPanel(home, market);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _aiSignalsPanel(PlatformHomeModel home, NbaMarket market) {
    final items = <Widget>[
      _drawerTile(
        title: 'Model Confidence Shift',
        value: '${(_marketMovement(market)).toStringAsFixed(1)} pts',
        detail: market.aiInsight,
        color: _marketMovement(market) >= 0
            ? AetherColors.success
            : AetherColors.critical,
      ),
      ...home.agents.take(4).map(
            (agent) => _drawerTile(
              title: agent.name,
              value: '${(agent.confidence * 100).toStringAsFixed(0)}%',
              detail: agent.recommendation,
              color: agent.confidence >= 0.7
                  ? const Color(0xFF43D4FF)
                  : AetherColors.warning,
              onTap: () {
                _appendLocalLog('ai signal ${agent.name}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(agent.summary)),
                );
              },
            ),
          ),
    ];
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, index) => items[index],
    );
  }

  Widget _playerStatsPanel(NbaMarket market) {
    final entries = market.playerContext.entries.toList(growable: false);
    if (entries.isEmpty) {
      return Center(
        child: Text(
          market.aiInsight,
          style: const TextStyle(fontSize: 11, color: AetherColors.muted),
        ),
      );
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _drawerTile(
          title: _labelize(entry.key),
          value: '${entry.value}',
          detail: 'Player context linked to ${market.matchup}',
          color: const Color(0xFF43D4FF),
        );
      },
    );
  }

  Widget _teamTrendsPanel(NbaMarket market) {
    final entries = market.teamForm.entries.toList(growable: false);
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final positive = entry.value is num && (entry.value as num) >= 0;
        return _drawerTile(
          title: _labelize(entry.key),
          value: '${entry.value}',
          detail: 'Team trend monitor',
          color: positive ? AetherColors.success : AetherColors.warning,
        );
      },
    );
  }

  Widget _injuryAlertsPanel(PlatformHomeModel home, NbaMarket market) {
    final items = home.news
        .where(
          (item) =>
              item.team == null ||
              market.matchup.toLowerCase().contains(item.team!.toLowerCase()),
        )
        .take(6)
        .toList(growable: false);

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = items[index];
        return _drawerTile(
          title: item.title,
          value: item.urgency.toUpperCase(),
          detail: item.summary,
          color: item.urgency.toLowerCase() == 'high'
              ? AetherColors.warning
              : AetherColors.text,
          onTap: () => _openNews(item),
        );
      },
    );
  }

  Widget _drawerTile({
    required String title,
    required String value,
    required String detail,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AetherColors.bg,
          border: Border.all(color: color.withValues(alpha: 0.65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AetherColors.muted,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _terminalLogBar(List<String> logs) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border.all(color: AetherColors.accentSoft),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Center(
          child: Text(
            logs[index],
            style: const TextStyle(
              fontSize: 10,
              color: AetherColors.muted,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _microMetric(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AetherColors.accent,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AetherColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminalPanel({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? headerTrailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border.all(color: AetherColors.accentSoft),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AetherColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (headerTrailing != null) headerTrailing,
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _terminalBadge(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AetherColors.bg,
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Future<void> _predictNow(NbaMarket market) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;
    setState(() => _executing = true);
    try {
      final wallet = ref.read(walletSessionProvider);
      await ref.read(apiClientProvider).placePrediction(
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
      ref.invalidate(liquidityBookProvider(market.id));
      _appendLocalLog(
        'market executed ${market.matchup} $_selectedSide ${_usd(amount)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction executed for ${market.title}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _executing = false);
      }
    }
  }

  Future<void> _useAiSuggestion(NbaMarket market) async {
    setState(() => _loadingAi = true);
    try {
      final ai = await ref
          .read(apiClientProvider)
          .generatePrediction(marketId: market.id, amount: 100);
      if (!mounted) return;
      setState(() {
        _aiSuggestion = ai;
        _selectedSide = ai.predictedSide;
        _confidenceLevel = ai.confidence * 100;
        _amountController.text = ai.suggestedAmount.toStringAsFixed(0);
        _drawerTabIndex = 0;
        _drawerExpanded = true;
      });
      _appendLocalLog('ai signal triggered ${market.matchup}');
    } finally {
      if (mounted) {
        setState(() => _loadingAi = false);
      }
    }
  }

  Future<void> _runStrategyPreview() async {
    setState(() => _loadingStrategy = true);
    try {
      final preview = await ref.read(apiClientProvider).previewStrategy(
            prompt: _strategyController.text,
            dataSources: const ['stats', 'news', 'history'],
            riskLevel: _riskLevel,
            automationEnabled: _automationEnabled,
          );
      if (!mounted) return;
      setState(() {
        _strategyPreview = preview;
        _drawerExpanded = true;
        _drawerTabIndex = 0;
      });
      _appendLocalLog('auto strategy refreshed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(preview.summary)),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingStrategy = false);
      }
    }
  }

  Future<void> _openNews(NbaNewsItem item) async {
    if (item.url.isEmpty) return;
    await launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication);
  }

  void _appendLocalLog(String message) {
    final now = DateTime.now().toUtc();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _localLogs.insert(0, '[$stamp] $message');
      if (_localLogs.length > 8) {
        _localLogs.removeLast();
      }
    });
  }

  List<NbaLiveGame> _filterGames(
    List<NbaLiveGame> games,
    List<NbaMarket> markets,
    String query,
  ) {
    List<NbaLiveGame> result = games;
    if (query.isNotEmpty) {
      result = games
          .where(
            (game) =>
                game.matchup.toLowerCase().contains(query) ||
                game.teamA.toLowerCase().contains(query) ||
                game.teamB.toLowerCase().contains(query) ||
                markets.any(
                  (market) =>
                      market.title.toLowerCase().contains(query) &&
                      market.matchup
                          .toLowerCase()
                          .contains(game.matchup.toLowerCase().split(' ')[0]),
                ),
          )
          .toList();
    }
    result.sort((a, b) {
      final aLive = a.status == 'Pre-game' ? 1 : 0;
      final bLive = b.status == 'Pre-game' ? 1 : 0;
      return aLive.compareTo(bLive);
    });
    return result;
  }

  NbaMarket _selectedMarket(PlatformHomeModel home, List<NbaLiveGame> games) {
    if (home.markets.isEmpty) {
      throw StateError('No markets available.');
    }
    if (_selectedMarketId != null) {
      return home.markets.firstWhere(
        (market) => market.id == _selectedMarketId,
        orElse: () => home.markets.first,
      );
    }
    for (final game in games) {
      final match = _marketForGame(game, home.markets);
      if (match != null) {
        _selectedMarketId = match.id;
        return match;
      }
    }
    _selectedMarketId = home.markets.first.id;
    return home.markets.first;
  }

  NbaLiveGame? _selectedGame(List<NbaLiveGame> games, NbaMarket market) {
    for (final game in games) {
      if (_matchesGameMarket(game, market)) {
        return game;
      }
    }
    return null;
  }

  NbaMarket? _marketForGame(NbaLiveGame game, List<NbaMarket> markets) {
    for (final market in markets) {
      if (_matchesGameMarket(game, market) &&
          market.marketType == 'game_outcome') {
        return market;
      }
    }
    return null;
  }

  bool _matchesGameMarket(NbaLiveGame game, NbaMarket market) {
    final matchup = market.matchup.toLowerCase();
    return matchup.contains(game.teamA.toLowerCase().split(' ').last) &&
        matchup.contains(game.teamB.toLowerCase().split(' ').last);
  }

  List<String> _tickerItems(PlatformHomeModel home) {
    final items = <String>[];
    for (final market in home.markets.take(6)) {
      final move = _marketMovement(market);
      items.add(
        '${market.yesLabel} ${move >= 0 ? '+' : ''}${move.toStringAsFixed(1)}%',
      );
    }
    for (final item in home.news.take(4)) {
      items.add('${item.source}: ${item.title}');
    }
    return items.isEmpty ? ['No live flow available'] : items;
  }

  List<_FeedEntry> _newsFeed(
    PlatformHomeModel home,
    NbaMarket market,
    NbaLiveGame? game,
  ) {
    final items = <_FeedEntry>[];
    for (final item in market.latestNews) {
      items.add(
        _FeedEntry(
          type: item.urgency.toLowerCase() == 'high'
              ? _FeedType.alert
              : _FeedType.news,
          label: item.urgency.toLowerCase() == 'high' ? 'ALERT' : 'NEWS',
          title: item.title,
          detail: item.summary,
          timeLabel: _timeAgo(item.publishedAt),
          newsItem: item,
        ),
      );
    }
    if (_marketMovement(market).abs() >= 2) {
      items.add(
        _FeedEntry(
          type: _FeedType.signal,
          label: 'SIGNAL',
          title:
              '${market.yesLabel} probability ${_marketMovement(market) >= 0 ? 'up' : 'down'} ${_marketMovement(market).abs().toStringAsFixed(1)} pts',
          detail: market.aiInsight,
          timeLabel: game == null ? market.category : game.status,
        ),
      );
    }
    for (final activity in home.activityFeed.take(4)) {
      items.add(
        _FeedEntry(
          type: _FeedType.signal,
          label: 'FLOW',
          title: '${activity.user} predicted ${activity.pick}',
          detail: '${activity.market} • ${_usd(activity.amount)}',
          timeLabel: 'live',
        ),
      );
    }
    if (items.isEmpty) {
      for (final item in home.news.take(6)) {
        items.add(
          _FeedEntry(
            type: _FeedType.news,
            label: 'NEWS',
            title: item.title,
            detail: item.summary,
            timeLabel: _timeAgo(item.publishedAt),
            newsItem: item,
          ),
        );
      }
    }
    return items.take(10).toList(growable: false);
  }

  List<NbaPredictionActivity> _predictionTape(
    PlatformHomeModel home,
    NbaMarket market,
  ) {
    final tape = home.recentPredictions
        .where((item) =>
            item.market == market.matchup || item.market == market.title)
        .toList();
    if (tape.isNotEmpty) {
      return tape.take(6).toList(growable: false);
    }
    return home.activityFeed.take(6).toList(growable: false);
  }

  List<String> _buildTerminalLogs(PlatformHomeModel home, NbaMarket market) {
    final logs = <String>[
      ..._localLogs,
      '[${_timeStamp(home.generatedAt)}] probability update ${(market.yesProbability * 100).toStringAsFixed(1)}%',
    ];
    if (home.news.isNotEmpty) {
      logs.add(
        '[${_timeStamp(home.news.first.publishedAt)}] news alert ingested ${home.news.first.title}',
      );
    }
    if (home.agents.isNotEmpty) {
      logs.add(
        '[${_timeStamp(home.generatedAt)}] ai signal ${home.agents.first.name} ${(home.agents.first.confidence * 100).toStringAsFixed(0)}%',
      );
    }
    return logs.take(8).toList(growable: false);
  }

  double _avgSpread(List<NbaMarket> markets) {
    if (markets.isEmpty) return 0;
    return markets.fold<double>(0, (sum, item) => sum + item.spreadBps) /
        markets.length;
  }

  double _marketMovement(NbaMarket market) {
    if (market.probabilityPoints.length < 2) return 0;
    return (market.probabilityPoints.last - market.probabilityPoints.first) *
        100;
  }

  double _marketVolatility(NbaMarket market) {
    if (market.probabilityPoints.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < market.probabilityPoints.length; i++) {
      total +=
          (market.probabilityPoints[i] - market.probabilityPoints[i - 1]).abs();
    }
    return total * 100;
  }

  List<int> _signalMarkerIndexes(NbaMarket market) {
    final markers = <int>[];
    for (var i = 1; i < market.probabilityPoints.length; i++) {
      final delta =
          (market.probabilityPoints[i] - market.probabilityPoints[i - 1]).abs();
      if (delta >= 0.04) {
        markers.add(i);
      }
    }
    return markers.take(4).toList(growable: false);
  }

  String _gameClock(NbaLiveGame game) {
    final status = game.status.trim();
    if (status == 'Pre-game') {
      return _formatGameTime(game);
    }
    if (status.contains('Q')) {
      return status;
    }
    return '${game.status} • pace ${game.pace.toStringAsFixed(0)}';
  }

  String _formatGameTime(NbaLiveGame game) {
    final hour = game.tipoffTime.hour.toString().padLeft(2, '0');
    final minute = game.tipoffTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute UTC';
  }

  Widget _teamLogo(String team) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AetherColors.bg,
        border: Border.all(color: AetherColors.accentSoft),
      ),
      child: Text(
        _teamCode(team),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AetherColors.accent,
        ),
      ),
    );
  }

  String _teamCode(String team) {
    final words = team
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length.clamp(0, 3))
          .toUpperCase();
    }
    return words.map((word) => word[0]).take(3).join().toUpperCase();
  }

  String _labelize(String key) {
    return key.replaceAll('_', ' ').split(' ').map((part) {
      if (part.isEmpty) return part;
      return '${part[0].toUpperCase()}${part.substring(1)}';
    }).join(' ');
  }

  String _timeAgo(DateTime value) {
    final diff = DateTime.now().toUtc().difference(value.toUtc());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _timeStamp(DateTime value) {
    final utc = value.toUtc();
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Color _feedColor(_FeedType type) {
    switch (type) {
      case _FeedType.news:
        return AetherColors.text;
      case _FeedType.alert:
        return AetherColors.warning;
      case _FeedType.signal:
        return const Color(0xFF43D4FF);
    }
  }

  String _usd(double value) => '\$${value.toStringAsFixed(0)}';

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
      case NbaSection.strategyLab:
        return 'Strategy Lab';
      case NbaSection.news:
        return 'News';
      case NbaSection.leaderboard:
        return 'Leaderboard';
    }
  }

  String _subtitle(NbaSection section) {
    switch (section) {
      case NbaSection.overview:
        return 'Bloomberg-style NBA prediction intelligence.';
      case NbaSection.liveGames:
        return 'Live score and market-monitoring workstation.';
      case NbaSection.markets:
        return 'Terminal-grade NBA prediction market execution.';
      case NbaSection.myPredictions:
        return 'Open positions, flow, and execution monitoring.';
      case NbaSection.aiAgents:
        return 'Dense AI signal and market reasoning console.';
      case NbaSection.strategyLab:
        return 'Prompt-driven prediction automation terminal.';
      case NbaSection.news:
        return 'Breaking sports news linked directly to probability flow.';
      case NbaSection.leaderboard:
        return 'Institutional ranking and signal-performance tracking.';
    }
  }
}

class _TerminalTickerBar extends StatefulWidget {
  const _TerminalTickerBar({required this.items});

  final List<String> items;

  @override
  State<_TerminalTickerBar> createState() => _TerminalTickerBarState();
}

class _TerminalTickerBarState extends State<_TerminalTickerBar> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      final next = _controller.offset + 1.6;
      if (next >= max) {
        _controller.jumpTo(0);
      } else {
        _controller.jumpTo(next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.items, ...widget.items];
    return Container(
      height: 24,
      decoration: const BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border(bottom: BorderSide(color: AetherColors.accentSoft)),
      ),
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) => Center(
          child: Text(
            items[index],
            style: const TextStyle(
              fontSize: 10,
              color: AetherColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedEntry {
  const _FeedEntry({
    required this.type,
    required this.label,
    required this.title,
    required this.detail,
    required this.timeLabel,
    this.newsItem,
  });

  final _FeedType type;
  final String label;
  final String title;
  final String detail;
  final String timeLabel;
  final NbaNewsItem? newsItem;
}

enum _FeedType { news, alert, signal }

const List<String> _drawerTabs = [
  'AI SIGNALS',
  'PLAYER STATS',
  'TEAM TRENDS',
  'INJURY ALERTS',
];
