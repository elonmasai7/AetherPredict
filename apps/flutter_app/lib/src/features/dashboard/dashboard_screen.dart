import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/market_chart.dart';

enum _SortMode { volume, confidence, probability, liquidity }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _category = 'All';
  bool _highConfidenceOnly = false;
  _SortMode _sortMode = _SortMode.volume;
  String? _selectedMarketId;
  double? _scenarioProbability;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(marketListProvider);
    ref.invalidate(agentListProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(sentimentFeedProvider);
    ref.invalidate(riskProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing live dashboard data...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketItems = ref.watch(marketListProvider);
    final agentItems = ref.watch(agentListProvider);
    final liveUpdate = ref.watch(marketUpdatesProvider);
    final notifications = ref.watch(notificationsProvider);
    final sentiment = ref.watch(sentimentFeedProvider);
    final risk = ref.watch(riskProvider);

    return AppScaffold(
      title: 'Command Center',
      child: marketItems.when(
        data: (markets) => agentItems.when(
          data: (agents) => _buildLoaded(
            context,
            markets: markets,
            agents: agents,
            liveUpdate: liveUpdate,
            notifications: notifications,
            sentiment: sentiment,
            risk: risk,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context, {
    required List<Market> markets,
    required List<AgentCardModel> agents,
    required AsyncValue<LiveMarketUpdate> liveUpdate,
    required AsyncValue<List<AppNotification>> notifications,
    required AsyncValue<SentimentFeed> sentiment,
    required AsyncValue<PortfolioRiskSnapshot> risk,
  }) {
    if (markets.isEmpty) {
      return const Center(child: Text('No markets available yet.'));
    }

    final allCategories = <String>{'All', ...markets.map((m) => m.category)}.toList();
    if (!allCategories.contains(_category)) {
      _category = 'All';
    }

    final filtered = markets.where((market) {
      final matchesCategory = _category == 'All' || market.category == _category;
      final matchesSearch = _searchQuery.isEmpty ||
          market.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          market.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesConfidence = !_highConfidenceOnly || market.aiConfidence >= 0.8;
      return matchesCategory && matchesSearch && matchesConfidence;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortMode) {
        case _SortMode.volume:
          return b.volume.compareTo(a.volume);
        case _SortMode.confidence:
          return b.aiConfidence.compareTo(a.aiConfidence);
        case _SortMode.probability:
          return b.yesProbability.compareTo(a.yesProbability);
        case _SortMode.liquidity:
          return b.liquidity.compareTo(a.liquidity);
      }
    });

    final selected = _resolveSelectedMarket(filtered, markets);
    final simulatedProb = (_scenarioProbability ?? selected.yesProbability).clamp(0.0, 1.0);
    final alphaEdge = ((selected.aiConfidence - simulatedProb) * 100).toStringAsFixed(1);
    final wide = MediaQuery.of(context).size.width >= 1260;
    final primaryWidth = wide ? 760.0 : double.infinity;
    final sideWidth = wide ? 360.0 : double.infinity;

    return ListView(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _metricCard('Visible Markets', '${filtered.length}/${markets.length}', 'After active filters', onTap: _refreshAll),
            _metricCard('Simulated YES', '${(simulatedProb * 100).round()}%', 'For ${selected.category}', onTap: () {
              setState(() => _scenarioProbability = selected.yesProbability);
            }),
            _metricCard(
              'Portfolio Risk',
              risk.maybeWhen(data: (value) => value.riskScore, orElse: () => 'Loading'),
              risk.maybeWhen(data: (value) => 'VaR95: \$${value.var95.toStringAsFixed(0)}', orElse: () => 'Waiting for risk model'),
            ),
            _metricCard(
              'Live Stream',
              liveUpdate.maybeWhen(data: (_) => 'Connected', orElse: () => 'Standby'),
              liveUpdate.maybeWhen(
                data: (value) => '${value.market} -> ${(value.yesProbability * 100).round()}% YES',
                orElse: () => 'Waiting for websocket ticks',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search markets or category',
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.trim()),
                ),
              ),
              DropdownButton<_SortMode>(
                value: _sortMode,
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: _SortMode.volume, child: Text('Sort: Volume')),
                  DropdownMenuItem(value: _SortMode.confidence, child: Text('Sort: AI Confidence')),
                  DropdownMenuItem(value: _SortMode.probability, child: Text('Sort: YES Probability')),
                  DropdownMenuItem(value: _SortMode.liquidity, child: Text('Sort: Liquidity')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sortMode = value);
                },
              ),
              FilterChip(
                selected: _highConfidenceOnly,
                label: const Text('AI Confidence >= 80%'),
                onSelected: (value) => setState(() => _highConfidenceOnly = value),
              ),
              ...allCategories.map(
                (value) => ChoiceChip(
                  selected: _category == value,
                  label: Text(value),
                  onSelected: (_) => setState(() => _category = value),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _category = 'All';
                    _highConfidenceOnly = false;
                    _sortMode = _SortMode.volume;
                  });
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: primaryWidth,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selected.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text('Category: ${selected.category}'),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => context.go('/markets'),
                          icon: const Icon(Icons.manage_search),
                          label: const Text('Explore'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            final sourceIndex = markets.indexWhere((item) => item.id == selected.id);
                            if (sourceIndex >= 0) {
                              ref.read(selectedMarketIndexProvider.notifier).state = sourceIndex;
                            }
                            context.go('/trade');
                          },
                          icon: const Icon(Icons.show_chart),
                          label: const Text('Trade'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 250, child: MarketChart(points: selected.points)),
                    const SizedBox(height: 12),
                    Text('Scenario Lab: move YES probability for stress testing', style: TextStyle(color: Colors.white.withValues(alpha: 0.78))),
                    Slider(
                      value: simulatedProb,
                      min: 0,
                      max: 1,
                      onChanged: (value) => setState(() => _scenarioProbability = value),
                    ),
                    Text(
                      'AI Confidence ${(selected.aiConfidence * 100).round()}% | Simulated YES ${(simulatedProb * 100).round()}% | Edge $alphaEdge pts',
                    ),
                    const SizedBox(height: 18),
                    const Text('Market Radar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...filtered.take(6).map(
                      (market) => Card(
                        color: _selectedMarketId == market.id ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.04),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              _selectedMarketId = market.id;
                              _scenarioProbability = market.yesProbability;
                            });
                          },
                          title: Text(market.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${market.category} | Vol \$${market.volume.toStringAsFixed(0)} | Liq \$${market.liquidity.toStringAsFixed(0)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${(market.yesProbability * 100).round()}% YES'),
                              Text('AI ${(market.aiConfidence * 100).round()}%', style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: sideWidth,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agent Command Grid', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    ...agents.map(
                      (agent) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(agent.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                Text(agent.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: (agent.pnl.abs() / 25000).clamp(0, 1).toDouble(),
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                            ),
                            const SizedBox(height: 6),
                            Text('PnL: \$${agent.pnl.toStringAsFixed(0)}'),
                            Text(agent.summary, style: TextStyle(color: Colors.white.withValues(alpha: 0.72))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => context.go('/agents'),
                      icon: const Icon(Icons.psychology_alt),
                      label: const Text('Open Agent Console'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: sideWidth,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Smart Alerts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    notifications.when(
                      data: (items) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...items.take(5).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    item.level.toUpperCase() == 'HIGH' ? Icons.warning_amber_rounded : Icons.notifications_active,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(item.message)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/notifications'),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('View All Alerts'),
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text(error.toString()),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: sideWidth,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Sentiment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    sentiment.when(
                      data: (item) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('Trend: ${item.trend}')),
                              Chip(label: Text('Score: ${item.sentimentScore.toStringAsFixed(2)}')),
                              Chip(label: Text('Shift: ${item.confidenceShift >= 0 ? '+' : ''}${item.confidenceShift}%')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...item.newsItems.take(3).map(
                            (news) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text('• ${news.headline} (${news.source})'),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => context.go('/copilot'),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Open AI Copilot'),
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text(error.toString()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Market _resolveSelectedMarket(List<Market> filtered, List<Market> fallback) {
    final source = filtered.isNotEmpty ? filtered : fallback;
    final selected = source.where((m) => m.id == _selectedMarketId).firstOrNull;
    final resolved = selected ?? source.first;
    if (_selectedMarketId != resolved.id) {
      _selectedMarketId = resolved.id;
    }
    return resolved;
  }

  Widget _metricCard(String label, String value, String detail, {VoidCallback? onTap}) {
    return SizedBox(
      width: 280,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.72))),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(detail, style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
