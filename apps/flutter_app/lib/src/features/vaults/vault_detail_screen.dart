import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/market_chart.dart';

class VaultDetailScreen extends ConsumerStatefulWidget {
  const VaultDetailScreen({super.key});

  @override
  ConsumerState<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends ConsumerState<VaultDetailScreen> {
  final TextEditingController _amountController = TextEditingController(text: '2500');
  String? _statusMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(GoRouterState.of(context).uri.queryParameters['id'] ?? '') ?? 0;
    if (id == 0) {
      return const AppScaffold(title: 'Vault Detail', child: Center(child: Text('Vault not found')));
    }

    final vault = ref.watch(vaultDetailProvider(id));
    final trades = ref.watch(vaultTradesProvider(id));
    final performance = ref.watch(vaultPerformanceProvider(id));
    final wallet = ref.watch(walletSessionProvider);

    return AppScaffold(
      title: 'Vault Detail',
      child: vault.when(
        data: (item) => LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1200;
            final panel = _actionPanel(item, wallet);
            if (compact) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _overview(item),
                    const SizedBox(height: 16),
                    _performance(performance),
                    const SizedBox(height: 16),
                    _allocation(item),
                    const SizedBox(height: 16),
                    _history(trades),
                    const SizedBox(height: 16),
                    panel,
                  ],
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _overview(item),
                        const SizedBox(height: 16),
                        _performance(performance),
                        const SizedBox(height: 16),
                        _allocation(item),
                        const SizedBox(height: 16),
                        _history(trades),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(width: 360, child: panel),
              ],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Widget _overview(VaultModel vault) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vault.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(vault.strategyDescription, style: const TextStyle(color: AetherColors.muted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _badge('${vault.managerType} Manager'),
                  const SizedBox(height: 6),
                  _badge(vault.autoExecuteEnabled ? 'Auto-Execute On' : 'Auto-Execute Off'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _stat('AUM', '\$${vault.totalAum.toStringAsFixed(0)}'),
              _stat('Subscribers', vault.activeSubscribers.toString()),
              _stat('ROI 30D', '${(vault.roi30d * 100).toStringAsFixed(1)}%'),
              _stat('Win Rate', '${(vault.winRate * 100).toStringAsFixed(1)}%'),
              _stat('Volatility', '${(vault.volatility * 100).toStringAsFixed(1)}%'),
              _stat('Confidence', '${(vault.aiConfidenceScore * 100).toStringAsFixed(0)}%'),
              _stat('Risk Profile', vault.riskProfile),
              _stat('Collateral Decimals', vault.collateralTokenDecimals.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performance(AsyncValue<List<VaultPerformancePoint>> performance) {
    return performance.when(
      data: (items) {
        final points = _normalizedPoints(items.map((e) => e.navPerShare).toList());
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Performance Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SizedBox(height: 220, child: MarketChart(points: points)),
            ],
          ),
        );
      },
      loading: () => const GlassCard(child: Center(child: CircularProgressIndicator())),
      error: (error, _) => GlassCard(child: Text(error.toString())),
    );
  }

  Widget _allocation(VaultModel vault) {
    final allocation = vault.currentAllocation;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Asset Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (allocation.isEmpty)
            const Text('No allocation targets configured yet.', style: TextStyle(color: AetherColors.muted))
          else
            Column(
              children: [
                for (final entry in allocation.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('Market #${entry.key}')),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (entry.value as num).toDouble().clamp(0, 1),
                            backgroundColor: AetherColors.bgPanel,
                            color: AetherColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${((entry.value as num) * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _history(AsyncValue<List<VaultTrade>> trades) {
    return trades.when(
      data: (items) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trade History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No vault trades executed yet.', style: TextStyle(color: AetherColors.muted))
            else
              Column(
                children: [
                  for (final trade in items.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text('Market ${trade.marketId} • ${trade.side}')),
                          Expanded(child: Text('${(trade.allocation * 100).toStringAsFixed(1)}%')),
                          Expanded(child: Text('Conf ${(trade.confidence * 100).toStringAsFixed(0)}%')),
                          Expanded(child: Text(trade.status)),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            if (items.isNotEmpty)
              Text('Latest AI rationale: ${items.first.reasoning}', style: const TextStyle(color: AetherColors.muted)),
          ],
        ),
      ),
      loading: () => const GlassCard(child: Center(child: CircularProgressIndicator())),
      error: (error, _) => GlassCard(child: Text(error.toString())),
    );
  }

  Widget _actionPanel(VaultModel vault, WalletSessionState wallet) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deposit / Withdraw', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Amount'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: wallet.connected ? () => _executeVaultAction(vault.id, wallet.address ?? '', true) : null,
                  child: const Text('Deposit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: wallet.connected ? () => _executeVaultAction(vault.id, wallet.address ?? '', false) : null,
                  child: const Text('Withdraw'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!wallet.connected)
            const Text('Connect a wallet to deposit or withdraw.', style: TextStyle(color: AetherColors.muted)),
          if (_statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(_statusMessage!, style: const TextStyle(color: AetherColors.muted)),
          ],
        ],
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AetherColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AetherColors.bgPanel,
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AetherColors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<double> _normalizedPoints(List<double> values) {
    if (values.isEmpty) return [0.5, 0.52, 0.51, 0.53];
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs();
    if (range < 0.000001) {
      return values.map((_) => 0.5).toList();
    }
    return values.map((value) => ((value - minValue) / range).clamp(0.05, 0.95)).toList();
  }

  Future<void> _executeVaultAction(int vaultId, String walletAddress, bool deposit) async {
    final api = ref.read(apiClientProvider);
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() => _statusMessage = 'Enter a valid amount.');
      return;
    }

    try {
      if (deposit) {
        await api.depositVault(vaultId: vaultId, walletAddress: walletAddress, amount: amount);
        setState(() => _statusMessage = 'Deposit submitted.');
      } else {
        await api.withdrawVault(vaultId: vaultId, walletAddress: walletAddress, amount: amount);
        setState(() => _statusMessage = 'Withdrawal submitted.');
      }
      ref.invalidate(vaultDetailProvider(vaultId));
      ref.invalidate(vaultTradesProvider(vaultId));
      ref.invalidate(vaultPerformanceProvider(vaultId));
    } catch (error) {
      setState(() => _statusMessage = 'Vault action failed: $error');
    }
  }
}
