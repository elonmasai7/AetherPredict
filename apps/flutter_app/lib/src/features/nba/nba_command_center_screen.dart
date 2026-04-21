import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models.dart';
import '../../core/nba_models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../strategy_engine/strategy_engine_models.dart';
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
  final _agentPromptController = TextEditingController(
    text: 'Analyze the highest-conviction NBA market and explain the edge.',
  );
  final _strategyPromptController = TextEditingController(
    text:
        'Build an NBA prediction strategy using injuries, pace, and live movement.',
  );
  final List<String> _tickerMessages = [];
  final List<String> _terminalLogs = [];
  final Map<String, Future<List<NbaNewsItem>>> _newsRequests = {};
  final Map<int, Future<AiPredictionModel>> _aiRequests = {};

  Timer? _refreshTimer;
  int? _selectedMarketId;
  String _selectedSide = 'YES';
  double _confidenceLevel = 70;
  bool _executing = false;
  bool _loadingAiSuggestion = false;
  bool _runningAgent = false;
  bool _creatingStrategy = false;
  AiPredictionModel? _lastAgentResult;
  StrategyBuildResultModel? _lastStrategyResult;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      ref.invalidate(platformHomeProvider);
      ref.invalidate(nbaGamesProvider);
      final marketId = _selectedMarketId;
      if (marketId != null) {
        ref.invalidate(liquidityBookProvider(marketId));
        _aiRequests.remove(marketId);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _amountController.dispose();
    _agentPromptController.dispose();
    _strategyPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeValue = ref.watch(platformHomeProvider);
    final gamesValue = ref.watch(nbaGamesProvider);
    final query = ref.watch(searchQueryProvider).trim().toLowerCase();

    ref.listen<AsyncValue<LiveMarketUpdate>>(marketUpdatesProvider,
        (previous, next) {
      next.whenData((update) {
        _pushTicker(
          '${update.market} ${(update.yesProbability * 100).toStringAsFixed(1)}% AI ${(update.confidence * 100).toStringAsFixed(0)}%',
        );
        _pushLog(
          'probability update ${update.market} ${(update.yesProbability * 100).toStringAsFixed(1)}%',
        );
      });
    });

    ref.listen<AsyncValue<TxUpdate>>(txUpdatesProvider, (previous, next) {
      next.whenData((update) {
        _pushTicker('TX ${update.status.toUpperCase()} MKT ${update.marketId}');
        _pushLog('market execution ${update.marketId} ${update.status}');
      });
    });

    ref.listen<AsyncValue<Map<String, dynamic>>>(nbaGameUpdatesProvider,
        (previous, next) {
      next.whenData((payload) {
        final headline =
            payload['headline']?.toString() ?? payload['status']?.toString();
        if (headline != null && headline.isNotEmpty) {
          _pushTicker(headline);
        }
      });
    });

    return AppScaffold(
      title: _title(widget.section),
      subtitle: _subtitle(widget.section),
      headerBottom: homeValue.maybeWhen(
        data: (home) => _TickerBar(items: _derivedTicker(home)),
        orElse: () => const SizedBox.shrink(),
      ),
      sidebarFooter: homeValue.maybeWhen(
        data: (home) => _sidebarMetrics(home),
        orElse: () => const SizedBox.shrink(),
      ),
      child: homeValue.when(
        data: (home) {
          if (widget.section == NbaSection.myPredictions) {
            return _predictionsWorkspace();
          }
          if (widget.section == NbaSection.aiAgents) {
            return _aiAgentsWorkspace();
          }
          if (widget.section == NbaSection.strategyLab) {
            return _strategyLabWorkspace();
          }
          if (widget.section == NbaSection.news) {
            return _newsWorkspace();
          }
          if (widget.section == NbaSection.leaderboard) {
            return _leaderboardWorkspace();
          }
          final liveGames = gamesValue.maybeWhen(
            data: (games) => games,
            orElse: () => home.liveGames,
          );
          final filteredGames = _filterGames(liveGames, home.markets, query);
          final selectedMarket =
              _resolveSelectedMarket(home.markets, filteredGames);
          final selectedGame = _selectedGame(filteredGames, selectedMarket);
          final centerWidth = _centerWidth(context);

          return _marketWorkspace(
            home,
            filteredGames,
            selectedMarket,
            selectedGame,
            centerWidth,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _panel(
          title: 'SYSTEM',
          subtitle: 'Backend connection',
          child: Center(
            child: Text(
              '$error',
              style:
                  const TextStyle(fontSize: 12, color: AetherColors.critical),
            ),
          ),
        ),
      ),
    );
  }

  Widget _marketWorkspace(
    PlatformHomeModel home,
    List<NbaLiveGame> filteredGames,
    NbaMarket selectedMarket,
    NbaLiveGame? selectedGame,
    double centerWidth,
  ) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 88),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 280 + centerWidth + 360 + 16,
              height: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 280,
                    child: _watchlistPanel(filteredGames, home.markets),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: centerWidth,
                    child: _mainTerminal(home, selectedMarket, selectedGame),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 360,
                    child: _intelligenceStack(
                      home,
                      selectedMarket,
                      selectedGame,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _executionBar(selectedMarket),
        ),
      ],
    );
  }

  double _centerWidth(BuildContext context) {
    final total = MediaQuery.of(context).size.width;
    final available = total - 228 - 24 - 280 - 360 - 16;
    if (available < 720) return 720;
    return available;
  }

  Widget _sidebarMetrics(PlatformHomeModel home) {
    final aiSignals =
        home.agents.where((item) => item.confidence >= 0.7).length;
    final alerts =
        home.news.where((item) => item.urgency.toLowerCase() != 'low').length;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        border: Border.all(color: AetherColors.accentSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIVE METRICS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AetherColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          _sidebarMetricRow('Active Games', '${home.liveGames.length}'),
          _sidebarMetricRow('Open Markets', '${home.markets.length}'),
          _sidebarMetricRow('AI Signals', '$aiSignals'),
          _sidebarMetricRow('News Alerts', '$alerts'),
        ],
      ),
    );
  }

  Widget _sidebarMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _predictionsWorkspace() {
    final positionsValue = ref.watch(portfolioProvider);
    return _singlePanelLayout(
      title: 'MY PREDICTIONS',
      subtitle: 'Authenticated positions, PnL, and execution history',
      child: positionsValue.when(
        data: (positions) {
          if (positions.isEmpty) {
            return _emptyState('No prediction data available');
          }
          return ListView.separated(
            itemCount: positions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final position = positions[index];
              final positive = position.pnl >= 0;
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AetherColors.bg,
                  border: Border.all(color: AetherColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            position.marketTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${position.side} • size ${position.size.toStringAsFixed(2)} • avg ${position.avgPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AetherColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _usd(position.pnl),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: positive
                            ? AetherColors.success
                            : AetherColors.critical,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorText(error),
      ),
    );
  }

  Widget _aiAgentsWorkspace() {
    final agentsValue = ref.watch(agentListProvider);
    return _singlePanelLayout(
      title: 'AI AGENTS',
      subtitle: 'Live agents, run-agent action, and backend responses',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AetherColors.bg,
              border: Border.all(color: AetherColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _agentPromptController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Agent prompt',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: FilledButton(
                        onPressed: _runningAgent ? null : _runAgent,
                        child: Text(_runningAgent ? 'RUNNING' : 'RUN AGENT'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_lastAgentResult != null)
                      Expanded(
                        child: Text(
                          _lastAgentResult!.reasoning.join(' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AetherColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: agentsValue.when(
              data: (agents) {
                if (agents.isEmpty) {
                  return _emptyState('No agent data available');
                }
                return ListView.separated(
                  itemCount: agents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final agent = agents[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AetherColors.bg,
                        border: Border.all(color: AetherColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agent.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${agent.status} • ${agent.strategy}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AetherColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  agent.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(agent.confidence * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF43D4FF),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${agent.roi.toStringAsFixed(1)}% ROI',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AetherColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _errorText(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _strategyLabWorkspace() {
    final stateValue = ref.watch(strategyEngineStateProvider);
    return _singlePanelLayout(
      title: 'STRATEGY LAB',
      subtitle: 'Create strategies, inspect records, and execute Canon actions',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AetherColors.bg,
              border: Border.all(color: AetherColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _strategyPromptController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Strategy prompt',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: FilledButton(
                        onPressed: _creatingStrategy ? null : _createStrategy,
                        child: Text(
                            _creatingStrategy ? 'CREATING' : 'CREATE STRATEGY'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_lastStrategyResult != null)
                      Expanded(
                        child: Text(
                          _lastStrategyResult!.strategy.name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AetherColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: stateValue.when(
              data: (state) {
                if (state.strategies.isEmpty) {
                  return _emptyState('No strategy data available');
                }
                return ListView.separated(
                  itemCount: state.strategies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final strategy = state.strategies[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AetherColors.bg,
                        border: Border.all(color: AetherColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  strategy.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _badge(strategy.stage, AetherColors.accent),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strategy.prompt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${strategy.market} • ${(strategy.confidence * 100).toStringAsFixed(0)}% confidence',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AetherColors.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _errorText(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsWorkspace() {
    final newsValue = FutureBuilder<List<NbaNewsItem>>(
      future: ref.read(apiClientProvider).fetchNews(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) return _errorText(snapshot.error!);
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return _emptyState('No news data available');
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () => _openNews(item),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AetherColors.bg,
                  border: Border.all(color: AetherColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.summary,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.source} • ${_timeAgo(item.publishedAt)}',
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
        );
      },
    );
    return _singlePanelLayout(
      title: 'NEWS',
      subtitle: 'NBA news feed from backend integration',
      child: newsValue,
    );
  }

  Widget _leaderboardWorkspace() {
    final leaderboardValue = ref.watch(traderLeaderboardProvider);
    return _singlePanelLayout(
      title: 'LEADERBOARD',
      subtitle: 'Ranked users by PnL, ROI, and accuracy',
      child: leaderboardValue.when(
        data: (rows) {
          if (rows.isEmpty) {
            return _emptyState('No leaderboard data available');
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final row = rows[index];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AetherColors.bg,
                  border: Border.all(color: AetherColors.border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#${row.rank}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${row.lifetimeAccuracy.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF43D4FF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${row.roi.toStringAsFixed(1)} ROI',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AetherColors.warning,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorText(error),
      ),
    );
  }

  Widget _singlePanelLayout({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return _panel(
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AetherColors.muted),
      ),
    );
  }

  Widget _errorText(Object error) {
    return Center(
      child: Text(
        '$error',
        style: const TextStyle(fontSize: 11, color: AetherColors.critical),
      ),
    );
  }

  Widget _watchlistPanel(List<NbaLiveGame> games, List<NbaMarket> markets) {
    return _panel(
      title: 'LIVE WATCHLIST',
      subtitle: '${games.length} game markets',
      child: ListView.separated(
        itemCount: games.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final game = games[index];
          final market = _marketForGame(game, markets);
          if (market == null) {
            return const SizedBox.shrink();
          }
          final selected = market.id == _selectedMarketId;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedMarketId = market.id;
                _selectedSide = 'YES';
              });
              _pushLog('watchlist load ${market.matchup}');
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    selected ? AetherColors.bgPanel : AetherColors.bgElevated,
                border: Border.all(
                  color: selected ? AetherColors.accent : AetherColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_teamCode(game.teamA)} vs ${_teamCode(game.teamB)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _teamScoreCell(game.teamA, game.homeScore),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _teamScoreCell(game.teamB, game.awayScore),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _watchStat(
                          'PROB',
                          '${(market.yesProbability * 100).toStringAsFixed(0)}%',
                          color: market.yesProbability >= 0.5
                              ? AetherColors.success
                              : AetherColors.critical,
                        ),
                      ),
                      Expanded(
                        child: _watchStat(
                          'SPREAD',
                          market.spreadBps.toStringAsFixed(1),
                          color: AetherColors.warning,
                        ),
                      ),
                      Expanded(
                        child: _watchStat(
                          'AI',
                          '${(market.aiConfidence * 100).toStringAsFixed(0)}%',
                          color: const Color(0xFF43D4FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _gameClock(game),
                    style: const TextStyle(
                        fontSize: 10, color: AetherColors.muted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _teamScoreCell(String team, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AetherColors.bg,
        border: Border.all(color: AetherColors.border),
      ),
      child: Row(
        children: [
          _teamLogo(team),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _teamCode(team),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _watchStat(String label, String value, {required Color color}) {
    return Column(
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
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _mainTerminal(
    PlatformHomeModel home,
    NbaMarket market,
    NbaLiveGame? game,
  ) {
    final tape = _tradeTape(home, market);
    final movement = _marketMovement(market);
    return _panel(
      title: 'MAIN TERMINAL',
      subtitle: market.matchup,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AetherColors.bg,
              border: Border.all(color: AetherColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        market.matchup,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${game?.status ?? market.category} • VOL ${_usd(market.volume)} • LIQ ${_usd(market.liquidity)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AetherColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                _badge(market.confidenceLabel, AetherColors.accent),
              ],
            ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'WIN PROBABILITY',
                        style: TextStyle(
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
                      markerIndexes: _signalMarkerIndexes(market),
                      showGrid: true,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                        'AI ${(market.aiConfidence * 100).toStringAsFixed(0)}%',
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
          Row(
            children: [
              Expanded(
                child: _terminalMetric(
                    'SPREAD', market.spreadBps.toStringAsFixed(1)),
              ),
              const SizedBox(width: 6),
              Expanded(
                  child: _terminalMetric('LIQUIDITY', _usd(market.liquidity))),
              const SizedBox(width: 6),
              Expanded(child: _terminalMetric('VOLUME', _usd(market.volume))),
              const SizedBox(width: 6),
              Expanded(
                child: _terminalMetric(
                  'VOLATILITY',
                  _marketVolatility(market).toStringAsFixed(1),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE TRADE FEED',
                    style: TextStyle(
                      fontSize: 10,
                      color: AetherColors.accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.separated(
                      itemCount: tape.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final item = tape[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AetherColors.bgElevated,
                            border: Border.all(color: AetherColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.user} ${item.pick}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                _usd(item.amount),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AetherColors.warning,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _timeStamp(item.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AetherColors.muted,
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
          ),
        ],
      ),
    );
  }

  Widget _terminalMetric(String label, String value) {
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _intelligenceStack(
    PlatformHomeModel home,
    NbaMarket market,
    NbaLiveGame? game,
  ) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: _marketDepthPanel(market),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 3,
          child: _newsPanel(game),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 3,
          child: _aiSignalPanel(market),
        ),
      ],
    );
  }

  Widget _marketDepthPanel(NbaMarket market) {
    final liquidityValue = ref.watch(liquidityBookProvider(market.id));
    return _panel(
      title: 'MARKET DEPTH',
      subtitle: 'Bid ladder / ask ladder',
      child: liquidityValue.when(
        data: (book) => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      _terminalMetric('SPREAD', book.spread.toStringAsFixed(2)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _terminalMetric(
                      'SLIPPAGE', book.slippage.toStringAsFixed(2)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _depthHeader(),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                children: _depthRows(book, market),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(
          '$error',
          style: const TextStyle(fontSize: 11, color: AetherColors.critical),
        ),
      ),
    );
  }

  Widget _depthHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'YES BID',
            style: TextStyle(fontSize: 10, color: AetherColors.accent),
          ),
        ),
        Expanded(
          child: Text(
            'NO ASK',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AetherColors.warning),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            'HEAT',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, color: AetherColors.muted),
          ),
        ),
      ],
    );
  }

  List<Widget> _depthRows(LiquidityBookModel book, NbaMarket market) {
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
      final heat = ((yesPrice - noPrice).abs() * 100).clamp(6, 60).toDouble();
      rows.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedSide = yesPrice >= noPrice ? 'YES' : 'NO';
              _amountController.text =
                  (((bid['size'] as num?)?.toDouble() ?? 100) / 3)
                      .toStringAsFixed(0);
            });
            _pushLog('depth focus ${market.matchup} $_selectedSide');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${(yesPrice * 100).toStringAsFixed(1)} x ${bid['size'] ?? '--'}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${(noPrice * 100).toStringAsFixed(1)} x ${ask['size'] ?? '--'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: heat,
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

  Widget _newsPanel(NbaLiveGame? game) {
    final teamKey = game?.homeTeam ?? game?.teamA ?? 'NBA';
    return _panel(
      title: 'LIVE NEWS',
      subtitle: teamKey,
      child: FutureBuilder<List<NbaNewsItem>>(
        future: _teamNewsFuture(teamKey),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () async {
                  _pushLog('news open ${item.title}');
                  await _openNews(item);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AetherColors.bg,
                    border: Border.all(
                      color: item.urgency.toLowerCase() == 'high'
                          ? AetherColors.warning.withValues(alpha: 0.6)
                          : AetherColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _badge(
                            item.urgency.toUpperCase(),
                            item.urgency.toLowerCase() == 'high'
                                ? AetherColors.warning
                                : const Color(0xFF43D4FF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AetherColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.source} • ${_timeAgo(item.publishedAt)}',
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
          );
        },
      ),
    );
  }

  Widget _aiSignalPanel(NbaMarket market) {
    return _panel(
      title: 'AI SIGNALS',
      subtitle: 'Analyze game',
      child: FutureBuilder<AiPredictionModel>(
        future: _aiFuture(market.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ai = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _terminalMetric(
                      'SHIFT',
                      _marketMovement(market).toStringAsFixed(1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _terminalMetric(
                      'VOL ALERT',
                      _marketVolatility(market).toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.separated(
                  itemCount: ai.reasoning.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final reasoning = ai.reasoning[index];
                    return InkWell(
                      onTap: () {
                        _pushLog('ai reasoning ${market.matchup}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(reasoning)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AetherColors.bg,
                          border: Border.all(
                            color:
                                const Color(0xFF43D4FF).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          reasoning,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _badge(ai.predictedSide, const Color(0xFF43D4FF)),
                  const SizedBox(width: 6),
                  Text(
                    'Confidence ${(ai.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 10, color: AetherColors.muted),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _executionBar(NbaMarket market) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final price =
        _selectedSide == 'YES' ? market.yesProbability : market.noProbability;
    final payout = amount <= 0 || price <= 0 ? 0.0 : amount / price;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border.all(color: AetherColors.accentSoft),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: _executionSideButton(
              label: market.yesLabel,
              value: '${(market.yesProbability * 100).toStringAsFixed(0)}%',
              selected: _selectedSide == 'YES',
              positive: true,
              onTap: () => setState(() => _selectedSide = 'YES'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: _executionSideButton(
              label: market.noLabel,
              value: '${(market.noProbability * 100).toStringAsFixed(0)}%',
              selected: _selectedSide == 'NO',
              positive: false,
              onTap: () => setState(() => _selectedSide = 'NO'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Amount',
                prefixText: '\$',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: _terminalMetric(
                'CONF', '${_confidenceLevel.toStringAsFixed(0)}%'),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 130, child: _terminalMetric('PAYOUT', _usd(payout))),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
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
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: FilledButton(
              onPressed: _executing ? null : () => _predictNow(market),
              child: Text(_executing ? 'EXECUTING' : 'PREDICT NOW'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: OutlinedButton(
              onPressed:
                  _loadingAiSuggestion ? null : () => _useAiSuggestion(market),
              child: Text(_loadingAiSuggestion ? 'LOADING' : 'AI SUGGEST'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _executionSideButton({
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
          color: selected ? AetherColors.bgPanel : AetherColors.bg,
          border: Border.all(
            color: selected
                ? (positive ? AetherColors.success : AetherColors.critical)
                : AetherColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: positive ? AetherColors.success : AetherColors.critical,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AetherColors.muted),
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AetherColors.bg,
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
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
      ref.invalidate(nbaGamesProvider);
      ref.invalidate(liquidityBookProvider(market.id));
      _pushLog(
          'prediction sent ${market.matchup} $_selectedSide ${_usd(amount)}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction executed for ${market.matchup}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _executing = false);
      }
    }
  }

  Future<void> _useAiSuggestion(NbaMarket market) async {
    setState(() => _loadingAiSuggestion = true);
    try {
      final suggestion = await ref
          .read(apiClientProvider)
          .generatePrediction(marketId: market.id, amount: 100);
      if (!mounted) return;
      setState(() {
        _selectedSide = suggestion.predictedSide;
        _confidenceLevel = suggestion.confidence * 100;
        _amountController.text = suggestion.suggestedAmount.toStringAsFixed(0);
      });
      _pushLog('ai suggestion ${market.matchup} ${suggestion.predictedSide}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(suggestion.reasoning.join(' '))),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingAiSuggestion = false);
      }
    }
  }

  Future<void> _runAgent() async {
    setState(() => _runningAgent = true);
    try {
      final result = await ref.read(apiClientProvider).runCustomAgent(
            prompt: _agentPromptController.text,
            riskLevel: 'balanced',
            dataSources: const ['stats', 'news', 'history'],
            automationEnabled: false,
          );
      if (!mounted) return;
      setState(() => _lastAgentResult = result);
      _pushLog('agent run ${result.predictedSide}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.reasoning.join(' '))),
      );
    } finally {
      if (mounted) {
        setState(() => _runningAgent = false);
      }
    }
  }

  Future<void> _createStrategy() async {
    setState(() => _creatingStrategy = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .buildStrategyFromPrompt(_strategyPromptController.text);
      ref.invalidate(strategyEngineStateProvider);
      if (!mounted) return;
      setState(() => _lastStrategyResult = result);
      _pushLog('strategy created ${result.strategy.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.strategy.name)),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingStrategy = false);
      }
    }
  }

  Future<void> _openNews(NbaNewsItem item) async {
    if (item.url.isEmpty) return;
    await launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication);
  }

  Future<List<NbaNewsItem>> _teamNewsFuture(String team) {
    return _newsRequests.putIfAbsent(
      team,
      () => ref.read(apiClientProvider).fetchNews(team: team),
    );
  }

  Future<AiPredictionModel> _aiFuture(int marketId) {
    return _aiRequests.putIfAbsent(
      marketId,
      () => ref.read(apiClientProvider).analyzeGame(marketId: marketId),
    );
  }

  void _pushTicker(String message) {
    if (!mounted) return;
    setState(() {
      _tickerMessages.insert(0, message);
      if (_tickerMessages.length > 16) {
        _tickerMessages.removeLast();
      }
    });
  }

  void _pushLog(String message) {
    if (!mounted) return;
    final now = DateTime.now().toUtc();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _terminalLogs.insert(0, '[$stamp] $message');
      if (_terminalLogs.length > 10) {
        _terminalLogs.removeLast();
      }
    });
  }

  List<String> _derivedTicker(PlatformHomeModel home) {
    final seed = <String>[
      for (final item in home.activityFeed.take(4))
        '${item.user} ${item.pick} ${_usd(item.amount)}',
      for (final item in home.markets.take(4))
        '${item.yesLabel} ${_marketMovement(item) >= 0 ? '+' : ''}${_marketMovement(item).toStringAsFixed(1)}%',
      ..._tickerMessages,
    ];
    return seed.isEmpty ? ['market stream online'] : seed.take(20).toList();
  }

  List<NbaLiveGame> _filterGames(
    List<NbaLiveGame> games,
    List<NbaMarket> markets,
    String query,
  ) {
    var result = games;
    if (query.isNotEmpty) {
      result = games
          .where(
            (game) =>
                game.matchup.toLowerCase().contains(query) ||
                game.teamA.toLowerCase().contains(query) ||
                game.teamB.toLowerCase().contains(query) ||
                markets.any((market) =>
                    market.matchup.toLowerCase().contains(query) ||
                    market.title.toLowerCase().contains(query)),
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

  NbaMarket _resolveSelectedMarket(
      List<NbaMarket> markets, List<NbaLiveGame> games) {
    if (markets.isEmpty) {
      throw StateError('No markets available.');
    }
    if (_selectedMarketId != null) {
      return markets.firstWhere(
        (market) => market.id == _selectedMarketId,
        orElse: () => markets.first,
      );
    }
    for (final game in games) {
      final market = _marketForGame(game, markets);
      if (market != null) {
        _selectedMarketId = market.id;
        return market;
      }
    }
    _selectedMarketId = markets.first.id;
    return markets.first;
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

  List<NbaPredictionActivity> _tradeTape(
      PlatformHomeModel home, NbaMarket market) {
    final feed = [
      ...home.recentPredictions,
      ...home.activityFeed,
    ].where((item) {
      final hay = item.market.toLowerCase();
      return hay.contains(market.yesLabel.toLowerCase()) ||
          hay.contains(market.noLabel.toLowerCase()) ||
          hay.contains(market.matchup.toLowerCase());
    }).toList();
    return feed.isEmpty
        ? home.activityFeed.take(10).toList(growable: false)
        : feed.take(10).toList(growable: false);
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
    return markers.take(5).toList(growable: false);
  }

  String _gameClock(NbaLiveGame game) {
    if (game.status == 'Pre-game') {
      return _timeStamp(game.tipoffTime);
    }
    return '${game.status} • pace ${game.pace.toStringAsFixed(0)}';
  }

  Widget _teamLogo(String team) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        border: Border.all(color: AetherColors.accentSoft),
      ),
      child: Text(
        _teamCode(team),
        style: const TextStyle(
          fontSize: 8,
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
      final word = words.first;
      return word.substring(0, word.length < 3 ? word.length : 3).toUpperCase();
    }
    return words.map((part) => part[0]).take(3).join().toUpperCase();
  }

  String _timeStamp(DateTime value) {
    final utc = value.toUtc();
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _timeAgo(DateTime value) {
    final diff = DateTime.now().toUtc().difference(value.toUtc());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
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
        return 'Live sports prediction terminal.';
      case NbaSection.liveGames:
        return 'Game watchlist and market routing.';
      case NbaSection.markets:
        return 'Execution and intelligence workstation.';
      case NbaSection.myPredictions:
        return 'Prediction execution terminal.';
      case NbaSection.aiAgents:
        return 'AI market analysis stream.';
      case NbaSection.strategyLab:
        return 'Strategy intelligence terminal.';
      case NbaSection.news:
        return 'Breaking news and market impact.';
      case NbaSection.leaderboard:
        return 'High-density market performance view.';
    }
  }
}

class _TickerBar extends StatefulWidget {
  const _TickerBar({required this.items});

  final List<String> items;

  @override
  State<_TickerBar> createState() => _TickerBarState();
}

class _TickerBarState extends State<_TickerBar> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      final next = _controller.offset + 1.4;
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
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => Center(
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
