import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

enum _SubscriptionStage {
  chooseVault,
  reviewPerformance,
  setAllocation,
  walletSign,
  subscribed,
}

class VaultMarketplaceScreen extends ConsumerWidget {
  const VaultMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultsValue = ref.watch(vaultProvider);

    return AppScaffold(
      title: 'Vaults',
      subtitle: 'Managed strategy vaults with transparent risk and performance controls.',
      child: vaultsValue.when(
        data: (vaults) {
          final totalAum = vaults.fold<double>(0, (sum, item) => sum + item.totalAum);
          final avgRoi30d = vaults.isEmpty
              ? 0
              : vaults.map((item) => item.roi30d).reduce((a, b) => a + b) /
                  vaults.length;
          final avgWinRate = vaults.isEmpty
              ? 0
              : vaults.map((item) => item.winRate).reduce((a, b) => a + b) /
                  vaults.length;

          return ListView(
            children: [
              KpiStrip(
                items: [
                  KpiStripItem(label: 'Active Vaults', value: vaults.length.toString()),
                  KpiStripItem(label: 'Total AUM', value: formatUsd(totalAum)),
                  KpiStripItem(
                    label: 'Average ROI 30D',
                    value: '${(avgRoi30d * 100).toStringAsFixed(2)}%',
                  ),
                  KpiStripItem(
                    label: 'Average Win Rate',
                    value: '${(avgWinRate * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.lg),
              if (vaults.isEmpty)
                const EmptyStateCard(
                  icon: Icons.account_balance_outlined,
                  title: 'No vault strategies available',
                  message:
                      'There are currently no vaults published. Retry after strategy deployment windows.',
                )
              else
                EnterpriseDataTable<VaultModel>(
                  title: 'Vault Directory',
                  subtitle: 'Compare strategy outcomes, manager model, and risk posture.',
                  rows: vaults,
                  rowId: (row) => row.id.toString(),
                  searchHint: 'Search vault title, manager type, or risk profile',
                  filters: [
                    EnterpriseTableFilter(
                      label: 'AI Managed',
                      predicate: (row) => row.managerType.toLowerCase() == 'ai',
                    ),
                    EnterpriseTableFilter(
                      label: 'Low Risk',
                      predicate: (row) => row.riskProfile.toLowerCase().contains('low'),
                    ),
                    EnterpriseTableFilter(
                      label: 'High Subscribers',
                      predicate: (row) => row.activeSubscribers >= 500,
                    ),
                  ],
                  columns: [
                    EnterpriseTableColumn(
                      label: 'Vault',
                      width: 260,
                      cell: (row) => row.title,
                      sortValue: (row) => row.title,
                    ),
                    EnterpriseTableColumn(
                      label: 'Manager',
                      width: 100,
                      cell: (row) => row.managerType,
                      sortValue: (row) => row.managerType,
                    ),
                    EnterpriseTableColumn(
                      label: 'Risk',
                      width: 110,
                      cell: (row) => row.riskProfile,
                      sortValue: (row) => row.riskProfile,
                    ),
                    EnterpriseTableColumn(
                      label: 'ROI 30D',
                      width: 95,
                      numeric: true,
                      cell: (row) => '${(row.roi30d * 100).toStringAsFixed(1)}%',
                      sortValue: (row) => row.roi30d,
                    ),
                    EnterpriseTableColumn(
                      label: 'Win Rate',
                      width: 95,
                      numeric: true,
                      cell: (row) => '${(row.winRate * 100).toStringAsFixed(1)}%',
                      sortValue: (row) => row.winRate,
                    ),
                    EnterpriseTableColumn(
                      label: 'Volatility',
                      width: 95,
                      numeric: true,
                      cell: (row) => '${(row.volatility * 100).toStringAsFixed(1)}%',
                      sortValue: (row) => row.volatility,
                    ),
                    EnterpriseTableColumn(
                      label: 'AUM',
                      width: 120,
                      numeric: true,
                      cell: (row) => formatUsd(row.totalAum),
                      sortValue: (row) => row.totalAum,
                    ),
                  ],
                  expandedBuilder: (row) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AetherSpacing.sm,
                        runSpacing: AetherSpacing.sm,
                        children: [
                          StatusBadge(label: '${row.activeSubscribers} subscribers'),
                          StatusBadge(
                            label: row.status,
                            color: row.status.toLowerCase() == 'active'
                                ? AetherColors.success
                                : AetherColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AetherSpacing.sm),
                      Text(row.strategyDescription),
                      const SizedBox(height: AetherSpacing.sm),
                      Text(
                        'Target markets: ${row.targetMarkets.take(4).join(', ')}',
                        style: const TextStyle(color: AetherColors.muted),
                      ),
                    ],
                  ),
                  actionsBuilder: (row) => [
                    IconButton(
                      tooltip: 'Open details',
                      onPressed: () => _openSubscribeDialog(context, row),
                      icon: const Icon(Icons.open_in_new, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Subscribe',
                      onPressed: () => _openSubscribeDialog(context, row),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    ),
                  ],
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to load vault directory',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Future<void> _openSubscribeDialog(BuildContext context, VaultModel vault) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _VaultSubscribeDialog(vault: vault),
    );
  }
}

class _VaultSubscribeDialog extends StatefulWidget {
  const _VaultSubscribeDialog({required this.vault});

  final VaultModel vault;

  @override
  State<_VaultSubscribeDialog> createState() => _VaultSubscribeDialogState();
}

class _VaultSubscribeDialogState extends State<_VaultSubscribeDialog> {
  _SubscriptionStage _stage = _SubscriptionStage.chooseVault;
  ActionButtonState _state = ActionButtonState.idle;
  double _allocation = 15000;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: EnterprisePanel(
          title: 'Vault Subscription Workflow',
          subtitle: widget.vault.title,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stageLine(),
              const SizedBox(height: AetherSpacing.lg),
              _body(),
              if (_error != null) ...[
                const SizedBox(height: AetherSpacing.sm),
                Text(_error!, style: const TextStyle(color: AetherColors.critical)),
              ],
              const SizedBox(height: AetherSpacing.lg),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _stage.index == 0 ? null : _back,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: AetherSpacing.sm),
                  ActionStateButton(
                    label: _stage == _SubscriptionStage.subscribed
                        ? 'Done'
                        : 'Continue',
                    state: _state,
                    onPressed: _next,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stageLine() {
    const labels = [
      'Choose',
      'Review',
      'Allocate',
      'Sign',
      'Subscribed',
    ];

    return Wrap(
      spacing: AetherSpacing.sm,
      runSpacing: AetherSpacing.sm,
      children: [
        for (var i = 0; i < labels.length; i++)
          StatusBadge(
            label: labels[i],
            color: i < _stage.index
                ? AetherColors.success
                : i == _stage.index
                    ? AetherColors.accent
                    : AetherColors.muted,
          ),
      ],
    );
  }

  Widget _body() {
    return switch (_stage) {
      _SubscriptionStage.chooseVault => _bodyChoose(),
      _SubscriptionStage.reviewPerformance => _bodyReview(),
      _SubscriptionStage.setAllocation => _bodyAllocation(),
      _SubscriptionStage.walletSign => _bodySign(),
      _SubscriptionStage.subscribed => _bodySubscribed(),
    };
  }

  Widget _bodyChoose() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.vault.strategyDescription),
        const SizedBox(height: AetherSpacing.sm),
        Text(
          'Manager ${widget.vault.managerType} • Risk ${widget.vault.riskProfile}',
          style: const TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _bodyReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricRow('ROI 7D', '${(widget.vault.roi7d * 100).toStringAsFixed(2)}%'),
        _metricRow('ROI 30D', '${(widget.vault.roi30d * 100).toStringAsFixed(2)}%'),
        _metricRow('Win Rate', '${(widget.vault.winRate * 100).toStringAsFixed(2)}%'),
        _metricRow('Volatility', '${(widget.vault.volatility * 100).toStringAsFixed(2)}%'),
      ],
    );
  }

  Widget _bodyAllocation() {
    final estShares = _allocation / max(widget.vault.aiConfidenceScore, 0.1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allocation: ${formatUsd(_allocation)}'),
        Slider(
          min: 1000,
          max: 200000,
          divisions: 199,
          value: _allocation,
          label: formatUsd(_allocation),
          onChanged: (value) => setState(() => _allocation = value),
        ),
        const SizedBox(height: AetherSpacing.sm),
        Text(
          'Estimated vault shares ${estShares.toStringAsFixed(2)} (modeled).',
          style: const TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _bodySign() {
    return const Text(
      'Subscription intent is prepared. Continue to simulate wallet signature and on-chain confirmation.',
    );
  }

  Widget _bodySubscribed() {
    return Text(
      'Subscription confirmed for ${widget.vault.title}. Allocation ${formatUsd(_allocation)} is now active.',
      style: const TextStyle(color: AetherColors.success),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AetherColors.muted))),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _next() async {
    if (_state == ActionButtonState.loading) return;

    if (_stage == _SubscriptionStage.subscribed) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (_stage == _SubscriptionStage.walletSign) {
      setState(() {
        _state = ActionButtonState.loading;
        _error = null;
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _state = ActionButtonState.success;
        _stage = _SubscriptionStage.subscribed;
      });
      return;
    }

    setState(() {
      _state = ActionButtonState.idle;
      _error = null;
      _stage = _SubscriptionStage.values[_stage.index + 1];
    });
  }

  void _back() {
    if (_stage.index == 0) return;
    setState(() {
      _state = ActionButtonState.idle;
      _error = null;
      _stage = _SubscriptionStage.values[_stage.index - 1];
    });
  }
}
