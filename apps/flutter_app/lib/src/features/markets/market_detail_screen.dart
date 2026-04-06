import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/market_depth_panel.dart';
import '../../widgets/news_signal_panel.dart';
import '../../widgets/trading_view_chart.dart';

class MarketDetailScreen extends ConsumerStatefulWidget {
  const MarketDetailScreen({super.key});

  @override
  ConsumerState<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen> {
  bool autoHedge = true;
  bool insurance = false;
  double size = 1500;
  String timeframe = '15m';
  String? tradeStatus;
  String? tradeError;
  int? pendingTradeId;
  String? pendingTxHash;

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(selectedMarketProvider);
    final copilot = ref.watch(copilotProvider);
    final sentiment = ref.watch(sentimentFeedProvider);
    final comments = ref.watch(discussionProvider);
    final wallet = ref.watch(walletSessionProvider);

    ref.listen(txUpdatesProvider, (previous, next) {
      next.whenData((update) {
        if (pendingTradeId == update.tradeId) {
          setState(() {
            tradeStatus = update.status.toLowerCase();
            pendingTxHash = update.txHash;
          });
        }
      });
    });

    return AppScaffold(
      title: 'Market Detail',
      child: market.when(
        data: (item) => LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1200;
            if (compact) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _mainContent(item, sentiment, comments, compact: true),
                    const SizedBox(height: 16),
                    _tradePanel(item, copilot, wallet),
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child:
                        _mainContent(item, sentiment, comments, compact: false),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    child: _tradePanel(item, copilot, wallet),
                  ),
                ),
              ],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Widget _mainContent(
    Market item,
    AsyncValue<SentimentFeed> sentiment,
    AsyncValue<List<DiscussionComment>> comments, {
    required bool compact,
  }) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'Category: ${item.category} • Oracle: ${item.oracleSource}',
                          style: const TextStyle(color: AetherColors.muted),
                        ),
                      ],
                    ),
                  ),
                  _countdownChip(),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final tf in const ['1m', '5m', '15m', '1h', '4h', '1D'])
                    ChoiceChip(
                      label: Text(tf),
                      selected: timeframe == tf,
                      onSelected: (_) => setState(() => timeframe = tf),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (compact)
                Column(
                  children: [
                    TradingViewChart(
                      symbol: _marketSymbol(item.title),
                      timeframe: timeframe,
                      height: 300,
                      overlayProbability: item.yesProbability,
                    ),
                    const SizedBox(height: 12),
                    MarketDepthPanel(symbol: _marketSymbol(item.title).split('/').first),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TradingViewChart(
                        symbol: _marketSymbol(item.title),
                        timeframe: timeframe,
                        height: 360,
                        overlayProbability: item.yesProbability,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 330, child: MarketDepthPanel(symbol: _marketSymbol(item.title).split('/').first)),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _explainabilityPanel(item, sentiment),
        const SizedBox(height: 16),
        sentiment.when(
          data: (feed) => NewsSignalPanel(feed: feed),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => GlassCard(
            child: Text(error.toString(),
                style: const TextStyle(color: AetherColors.muted)),
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activity Timeline / Audit Trail',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'No audit events have been recorded for this market yet.',
                style: TextStyle(color: AetherColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        comments.when(
          data: (items) => GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discussion Thread',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ...items.take(4).map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${c.author}: ${c.content}'),
                      ),
                    ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(error.toString()),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Dispute Section',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 10),
              Text('No open disputes are recorded for this market right now.'),
              SizedBox(height: 8),
              Text(
                  'Claims and evidence submissions are recorded in immutable audit logs.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tradePanel(Market item, AsyncValue<CopilotRecommendation> copilot, WalletSessionState wallet) {
    final yesPrice = item.yesProbability;
    final noPrice = 1 - item.yesProbability;
    final estPnl = (size * (yesPrice - 0.55));

    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trading Console',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: wallet.connected ? () => _executeTrade(item, 'YES') : null,
                      child: Text(
                          'Buy YES ${(yesPrice * 100).toStringAsFixed(1)}%'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: wallet.connected ? () => _executeTrade(item, 'NO') : null,
                      child:
                          Text('Buy NO ${(noPrice * 100).toStringAsFixed(1)}%'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!wallet.connected)
                const Text(
                  'Connect a wallet to execute live trades.',
                  style: TextStyle(color: AetherColors.muted),
                ),
              if (tradeStatus != null) ...[
                const SizedBox(height: 12),
                _tradeStatusCard(),
              ],
              Text('Position Size: \$${size.toStringAsFixed(0)}'),
              Slider(
                  value: size,
                  min: 100,
                  max: 10000,
                  onChanged: (v) => setState(() => size = v)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto Hedge'),
                value: autoHedge,
                onChanged: (v) => setState(() => autoHedge = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Insurance Cover'),
                value: insurance,
                onChanged: (v) => setState(() => insurance = v),
              ),
              const SizedBox(height: 6),
              Text(
                'Estimated PnL: ${estPnl >= 0 ? '+' : ''}\$${estPnl.toStringAsFixed(0)}',
                style: TextStyle(
                    color: estPnl >= 0
                        ? AetherColors.success
                        : AetherColors.critical),
              ),
              const Text('Slippage Preview: 0.42%',
                  style: TextStyle(color: AetherColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        copilot.when(
          data: (advice) => GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Recommendation',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${advice.action} • ${advice.confidence}% confidence'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                    value: advice.confidence / 100, minHeight: 8),
                const SizedBox(height: 10),
                Text('Risk: ${advice.risk}',
                    style: const TextStyle(color: AetherColors.warning)),
                const SizedBox(height: 8),
                Text(advice.reasoning),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(error.toString()),
        ),
      ],
    );
  }

  Widget _explainabilityPanel(
      Market item, AsyncValue<SentimentFeed> sentiment) {
    return GlassCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: AetherColors.muted,
        iconColor: AetherColors.text,
        title: const Text('AI Explainability Panel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        subtitle: const Text(
            'Transparent contributors, evidence, and reasoning chain'),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _infoTile('Confidence',
                      '${(item.aiConfidence * 100).toStringAsFixed(0)}%')),
              const SizedBox(width: 8),
              Expanded(child: _infoTile('Historical Accuracy', '79.4%')),
              const SizedBox(width: 8),
              Expanded(
                child: _infoTile(
                  'Sentiment Score',
                  sentiment.maybeWhen(
                      data: (s) => s.sentimentScore.toStringAsFixed(2),
                      orElse: () => '--'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Contributors',
              style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 8),
          const Text('+ ETF inflows +18%',
              style: TextStyle(color: AetherColors.success)),
          const Text('+ volume momentum +12%',
              style: TextStyle(color: AetherColors.success)),
          const Text('- regulatory uncertainty -5%',
              style: TextStyle(color: AetherColors.warning)),
          const SizedBox(height: 10),
          const Text('Evidence Sources',
              style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 6),
          const Text(
              '• HashKey oracle mesh\n• ETF desk flow feed\n• On-chain volume monitor'),
          const SizedBox(height: 10),
          const Text('Reasoning Chain',
              style: TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 6),
          const Text(
              'Momentum remains constructive while volatility is elevated. Recommendation keeps directional exposure with protective hedging enabled.'),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _tradeStatusCard() {
    final status = tradeStatus ?? 'idle';
    final message = switch (status) {
      'awaiting_wallet_signature' => 'Awaiting signature in wallet.',
      'signing_rejected' => 'Signature rejected in wallet.',
      'broadcasting' => 'Broadcasting transaction to HashKey Chain.',
      'pending_confirmation' => 'Transaction submitted. Awaiting confirmation.',
      'confirmed' => 'Trade confirmed on-chain.',
      'failed' => tradeError ?? 'Trade failed.',
      'reverted' => 'Transaction reverted on-chain.',
      _ => 'Preparing trade.',
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trade Status: $status',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: AetherColors.muted)),
          if (pendingTxHash != null) ...[
            const SizedBox(height: 6),
            Text('Tx Hash: $pendingTxHash',
                style: numericStyle(context, size: 12)),
          ],
        ],
      ),
    );
  }

  Future<void> _executeTrade(Market item, String side) async {
    setState(() {
      tradeStatus = 'awaiting_wallet_signature';
      tradeError = null;
      pendingTxHash = null;
    });
    try {
      final wallet = ref.read(walletSessionProvider);
      final api = ref.read(apiClientProvider);
      final walletService = ref.read(walletServiceProvider);
      if (!wallet.connected || wallet.address == null) {
        throw StateError('Wallet is not connected.');
      }
      final chainId = await walletService.currentChainId();
      if (chainId != 133) {
        await walletService.switchChain(133);
      }
      final prepared = await api.prepareTrade(
        marketId: item.id,
        side: side,
        collateralAmount: size,
        walletAddress: wallet.address!,
      );
      setState(() {
        pendingTradeId = prepared.tradeId;
        tradeStatus = 'broadcasting';
      });
      final txHash = await walletService.sendTransaction({
        'from': wallet.address,
        'to': prepared.tx['to'],
        'data': prepared.tx['data'],
        'value': prepared.tx['value'],
        if (prepared.tx['gas'] != null) 'gas': prepared.tx['gas'],
        if (prepared.tx['gasPrice'] != null) 'gasPrice': prepared.tx['gasPrice'],
        if (prepared.tx['nonce'] != null) 'nonce': prepared.tx['nonce'],
        'chainId': prepared.tx['chainId'],
      });
      setState(() {
        tradeStatus = 'pending_confirmation';
        pendingTxHash = txHash;
      });
      await api.submitTradeHash(tradeId: prepared.tradeId, txHash: txHash, walletAddress: wallet.address);
    } catch (error) {
      final message = error.toString();
      setState(() {
        tradeStatus = message.contains('USER_REJECTED') || message.contains('rejected')
            ? 'signing_rejected'
            : 'failed';
        tradeError = message;
      });
    }
  }

  Widget _infoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(8),
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

  Widget _countdownChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AetherColors.border),
      ),
      child: const Text('Expiry: 269d 14h',
          style: TextStyle(fontWeight: FontWeight.w600)),
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
}
