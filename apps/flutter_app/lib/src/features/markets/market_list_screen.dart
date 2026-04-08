import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/trading_view_chart.dart';

class MarketListScreen extends ConsumerStatefulWidget {
  const MarketListScreen({super.key});

  @override
  ConsumerState<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends ConsumerState<MarketListScreen> {
  String timeframe = '15m';
  String? _createStatus;
  int? _createMarketId;
  String? _createTxHash;
  final Map<int, TxUpdate> _marketTxUpdates = {};
  final ValueNotifier<TxUpdate?> _createTxNotifier = ValueNotifier(null);
  late final ProviderSubscription<AsyncValue<TxUpdate>> _txSubscription;

  @override
  void initState() {
    super.initState();
    _txSubscription = ref.listenManual<AsyncValue<TxUpdate>>(txUpdatesProvider, (previous, next) {
      next.whenData((update) {
        if (!mounted) return;
        setState(() {
          _marketTxUpdates[update.marketId] = update;
        });
        if (_createMarketId == update.marketId) {
          _createTxNotifier.value = update;
        }
        if (update.status.toLowerCase() == 'confirmed') {
          ref.invalidate(marketListProvider);
        }
      });
    });
  }

  @override
  void dispose() {
    _txSubscription.close();
    _createTxNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketItems = ref.watch(marketListProvider);
    final wallet = ref.watch(walletSessionProvider);
    return AppScaffold(
      title: 'Markets',
      child: marketItems.when(
        data: (items) => ListView(
          children: [
            GlassCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create and list new prediction markets directly on HashKey Chain.',
                      style: TextStyle(color: AetherColors.muted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: wallet.connected ? () => _openCreateMarketDialog(context) : null,
                    child: const Text('Create Market'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tf in const ['1m', '5m', '15m', '1h', '4h', '1D'])
                    ChoiceChip(
                      label: Text(tf),
                      selected: timeframe == tf,
                      onSelected: (_) => setState(() => timeframe = tf),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final market = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    ref.read(selectedMarketIndexProvider.notifier).state =
                        index;
                    context.go('/markets/detail');
                  },
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          market.category,
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                        const SizedBox(height: 8),
                        Text(market.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'AI ${(market.aiConfidence * 100).toStringAsFixed(0)}% • Vol \$${market.volume.toStringAsFixed(0)}',
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                        if (int.tryParse(market.id) != null &&
                            _marketTxUpdates[int.parse(market.id)] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AetherColors.bgPanel,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AetherColors.border),
                                  ),
                                  child: Text(
                                    'On-chain: ${_marketTxUpdates[int.parse(market.id)]!.status}',
                                    style: const TextStyle(color: AetherColors.muted),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      _openExplorer('/tx/${_marketTxUpdates[int.parse(market.id)]!.txHash}'),
                                  child: const Text('Explorer'),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        TradingViewChart(
                          symbol: _marketSymbol(market.title),
                          timeframe: timeframe,
                          height: 280,
                          overlayProbability: market.yesProbability,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                                '${(market.yesProbability * 100).round()}% YES',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(selectedMarketIndexProvider.notifier)
                                    .state = index;
                                context.go('/markets/detail');
                              },
                              child: const Text('Open Market'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                ref
                                    .read(selectedMarketIndexProvider.notifier)
                                    .state = index;
                                context.go('/markets/detail');
                              },
                              child: const Text('Trade'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  String _marketSymbol(String title) {
    final upper = title.toUpperCase();
    if (upper.contains('BTC')) return 'BTC/USD';
    if (upper.contains('ETH')) return 'ETH/USD';
    if (upper.contains('SOL')) return 'SOL/USD';
    if (upper.contains('HASHKEY')) return 'HSK/USD';
    return 'BTC/USD';
  }

  Widget _buildCreateConfirmation() {
    return ValueListenableBuilder<TxUpdate?>(
      valueListenable: _createTxNotifier,
      builder: (context, update, _) {
        final hasTx = _createTxHash != null && _createTxHash!.isNotEmpty;
        final status = update?.status ?? _createStatus;
        if (!hasTx && status == null) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AetherColors.bgPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AetherColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Market Confirmation',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (status != null)
                Text(status, style: const TextStyle(color: AetherColors.muted)),
              if (_createTxHash != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tx: ${_createTxHash!.substring(0, 12)}...',
                        style: const TextStyle(color: AetherColors.muted),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openExplorer('/tx/${_createTxHash!}'),
                      child: const Text('View on Explorer'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openExplorer(String path) async {
    final uri = Uri.parse('${AppConfig.explorerBaseUrl}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openCreateMarketDialog(BuildContext context) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final category = TextEditingController(text: 'Crypto');
    final oracle = TextEditingController(text: 'HashKey Oracle');
    final expiry = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toIso8601String());
    final rules = TextEditingController(text: 'Resolve YES if condition met at expiry.');
    final collateral = TextEditingController(text: 'USDC');
    final liquidity = TextEditingController(text: '0');

    try {
      _createStatus = null;
      _createMarketId = null;
      _createTxHash = null;
      _createTxNotifier.value = null;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Create Market'),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                        const SizedBox(height: 8),
                        TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
                        const SizedBox(height: 8),
                        TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
                        const SizedBox(height: 8),
                        TextField(controller: oracle, decoration: const InputDecoration(labelText: 'Oracle Source')),
                        const SizedBox(height: 8),
                        TextField(controller: expiry, decoration: const InputDecoration(labelText: 'Expiry (ISO8601)')),
                        const SizedBox(height: 8),
                        TextField(controller: rules, decoration: const InputDecoration(labelText: 'Resolution Rules')),
                        const SizedBox(height: 8),
                        TextField(controller: collateral, decoration: const InputDecoration(labelText: 'Collateral Token')),
                        const SizedBox(height: 8),
                        TextField(controller: liquidity, decoration: const InputDecoration(labelText: 'Initial Liquidity')),
                        const SizedBox(height: 12),
                        _buildCreateConfirmation(),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () async {
                      try {
                        setDialogState(() => _createStatus = 'Building on-chain transaction...');
                        final wallet = ref.read(walletSessionProvider);
                        final api = ref.read(apiClientProvider);
                        final walletService = ref.read(walletServiceProvider);
                        if (!wallet.connected || wallet.address == null) {
                          throw StateError('Connect wallet first.');
                        }
                        final chainId = await walletService.currentChainId();
                        if (chainId != 133) {
                          await walletService.switchChain(133);
                        }
                        final market = await api.createMarket({
                          'title': title.text,
                          'description': description.text,
                          'category': category.text,
                          'oracle_source': oracle.text,
                          'expiry_at': expiry.text,
                          'resolution_rules': rules.text,
                          'collateral_token': collateral.text,
                          'liquidity_amount': double.tryParse(liquidity.text) ?? 0,
                          'wallet_address': wallet.address,
                        });
                        _createMarketId = int.tryParse(market.id);
                        final tx = await api.buildCreateMarketTx({
                          'wallet_address': wallet.address,
                          'title': title.text,
                          'description': description.text,
                          'oracle_source': oracle.text,
                          'expiry': DateTime.parse(expiry.text).millisecondsSinceEpoch ~/ 1000,
                          'creation_fee_wei': 0,
                        });
                        final chainTxId = await api.createMarketChainTx(int.parse(market.id), wallet.address!);
                        final txHash = await walletService.sendTransaction({
                          'from': wallet.address,
                          'to': tx['to'],
                          'data': tx['data'],
                          'value': tx['value'],
                          if (tx['gas'] != null) 'gas': tx['gas'],
                          if (tx['gasPrice'] != null) 'gasPrice': tx['gasPrice'],
                          if (tx['nonce'] != null) 'nonce': tx['nonce'],
                          'chainId': tx['chainId'],
                        });
                        await api.submitChainTx(chainTxId, txHash, wallet.address!);
                        _createTxHash = txHash;
                        final update = TxUpdate(
                          tradeId: null,
                          txId: chainTxId,
                          marketId: int.parse(market.id),
                          status: 'pending_confirmation',
                          txHash: txHash,
                        );
                        setState(() {
                          _marketTxUpdates[int.parse(market.id)] = update;
                        });
                        _createTxNotifier.value = update;
                        setDialogState(() => _createStatus = 'Transaction submitted to HashKey Chain.');
                      } catch (error) {
                        setDialogState(() => _createStatus = error.toString());
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      title.dispose();
      description.dispose();
      category.dispose();
      oracle.dispose();
      expiry.dispose();
      rules.dispose();
      collateral.dispose();
      liquidity.dispose();
    }
  }
}
