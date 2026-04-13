import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';
import 'copy_settings_dialog.dart';

class CopyTradingScreen extends ConsumerStatefulWidget {
  const CopyTradingScreen({super.key});

  @override
  ConsumerState<CopyTradingScreen> createState() => _CopyTradingScreenState();
}

class _CopyTradingScreenState extends ConsumerState<CopyTradingScreen> {
  final _sourceIdController = TextEditingController();
  ActionButtonState _followState = ActionButtonState.idle;
  String? _followError;
  String _risk = 'medium';
  double _allocation = 0.2;
  double _maxLoss = 0.12;

  @override
  void dispose() {
    _sourceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(copyPortfolioProvider);
    final relationships = ref.watch(copyRelationshipsProvider);
    final trades = ref.watch(copiedTradesProvider);

    ref.listen(copyUpdatesProvider, (_, next) {
      next.whenData((_) {
        ref.invalidate(copyPortfolioProvider);
        ref.invalidate(copyRelationshipsProvider);
        ref.invalidate(copiedTradesProvider);
      });
    });

    return AppScaffold(
      title: 'Copy Forecasts',
      subtitle:
          'Follower allocation controls, copied forecast telemetry, and risk limits.',
      child: ListView(
        children: [
          summary.when(
            data: (item) => KpiStrip(
              items: [
                KpiStripItem(
                  label: 'Copied Forecasters',
                  value: item.copiedTraders.toString(),
                ),
                KpiStripItem(
                  label: 'Live Copied Forecasts',
                  value: item.liveCopiedPositions.toString(),
                ),
                KpiStripItem(
                  label: 'Copied Forecast ROI',
                  value: '${(item.copiedRoi * 100).toStringAsFixed(2)}%',
                ),
                KpiStripItem(
                  label: 'Active Alerts',
                  value: item.activeAlerts.toString(),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _errorPanel(error.toString()),
          ),
          const SizedBox(height: AetherSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1220;
              if (compact) {
                return Column(
                  children: [
                    _followPanel(),
                    const SizedBox(height: AetherSpacing.lg),
                    _relationshipsTable(relationships),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 360, child: _followPanel()),
                  const SizedBox(width: AetherSpacing.lg),
                  Expanded(child: _relationshipsTable(relationships)),
                ],
              );
            },
          ),
          const SizedBox(height: AetherSpacing.lg),
          _copiedTradesTable(trades),
        ],
      ),
    );
  }

  Widget _followPanel() {
    return EnterprisePanel(
      title: 'Follow Forecast Workflow',
      subtitle:
          'Configure copied forecast allocation and risk controls before activation.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _sourceIdController,
            decoration:
                const InputDecoration(labelText: 'Source Forecaster ID'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AetherSpacing.md),
          Text('Allocation ${(100 * _allocation).toStringAsFixed(0)}%'),
          Slider(
            min: 0.05,
            max: 0.75,
            divisions: 14,
            value: _allocation,
            label: '${(100 * _allocation).toStringAsFixed(0)}%',
            onChanged: (value) => setState(() => _allocation = value),
          ),
          const SizedBox(height: AetherSpacing.sm),
          Text('Max loss ${(100 * _maxLoss).toStringAsFixed(0)}%'),
          Slider(
            min: 0.03,
            max: 0.4,
            divisions: 37,
            value: _maxLoss,
            label: '${(100 * _maxLoss).toStringAsFixed(0)}%',
            onChanged: (value) => setState(() => _maxLoss = value),
          ),
          const SizedBox(height: AetherSpacing.sm),
          DropdownButtonFormField<String>(
            value: _risk,
            decoration: const InputDecoration(labelText: 'Risk profile'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'high', child: Text('High')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _risk = value);
            },
          ),
          if (_followError != null) ...[
            const SizedBox(height: AetherSpacing.sm),
            Text(_followError!,
                style: const TextStyle(color: AetherColors.critical)),
          ],
          const SizedBox(height: AetherSpacing.md),
          ActionStateButton(
            label: 'Activate Copy Forecast',
            state: _followState,
            onPressed: _submitFollow,
            retryLabel: 'Retry Activation',
          ),
        ],
      ),
    );
  }

  Widget _relationshipsTable(
      AsyncValue<List<CopyRelationshipModel>> relationships) {
    return relationships.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.people_outline,
            title: 'No active copy forecast relationships',
            message:
                'Use the workflow panel to follow a forecaster and begin synchronized forecast execution.',
          );
        }

        return EnterpriseDataTable<CopyRelationshipModel>(
          title: 'Active Copy Relationships',
          subtitle: 'Follower exposure limits and source forecaster routing.',
          rows: items,
          rowId: (row) => row.id.toString(),
          searchHint: 'Search source ID or risk profile',
          filters: [
            EnterpriseTableFilter(
              label: 'High Allocation',
              predicate: (row) => row.allocationPct >= 0.3,
            ),
            EnterpriseTableFilter(
              label: 'Low Risk',
              predicate: (row) => row.riskLevel.toLowerCase() == 'low',
            ),
          ],
          columns: [
            EnterpriseTableColumn(
              label: 'Source Forecaster',
              width: 140,
              cell: (row) => '#${row.sourceUserId}',
              sortValue: (row) => row.sourceUserId,
            ),
            EnterpriseTableColumn(
              label: 'Status',
              width: 110,
              cell: (row) => row.status,
              sortValue: (row) => row.status,
            ),
            EnterpriseTableColumn(
              label: 'Allocation',
              width: 100,
              numeric: true,
              cell: (row) => '${(row.allocationPct * 100).toStringAsFixed(1)}%',
              sortValue: (row) => row.allocationPct,
            ),
            EnterpriseTableColumn(
              label: 'Max Loss',
              width: 100,
              numeric: true,
              cell: (row) => '${(row.maxLossPct * 100).toStringAsFixed(1)}%',
              sortValue: (row) => row.maxLossPct,
            ),
            EnterpriseTableColumn(
              label: 'Risk',
              width: 90,
              cell: (row) => row.riskLevel,
              sortValue: (row) => row.riskLevel,
            ),
            EnterpriseTableColumn(
              label: 'Auto-stop',
              width: 95,
              numeric: true,
              cell: (row) =>
                  '${(row.autoStopThreshold * 100).toStringAsFixed(1)}%',
              sortValue: (row) => row.autoStopThreshold,
            ),
          ],
          expandedBuilder: (row) => Text(
            'Allowed event markets: ${row.allowedMarketIds.join(', ')} • Commission ${row.traderCommissionBps} bps',
            style: const TextStyle(color: AetherColors.muted),
          ),
          actionsBuilder: (row) => [
            IconButton(
              tooltip: 'Edit settings',
              onPressed: () => _openSettings(row),
              icon: const Icon(Icons.tune, size: 18),
            ),
            IconButton(
              tooltip: 'Stop following',
              onPressed: () => _stopFollowing(row.id),
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _errorPanel(error.toString()),
    );
  }

  Widget _copiedTradesTable(AsyncValue<List<CopiedTradeModel>> trades) {
    return trades.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.timeline_outlined,
            title: 'No copied forecast executions',
            message:
                'Execution records appear after followed forecasters trigger eligible positions.',
          );
        }

        return EnterpriseDataTable<CopiedTradeModel>(
          title: 'Copied Forecast Log',
          subtitle:
              'Relationship-level copied forecast outcomes and lifecycle states.',
          rows: items,
          rowId: (row) => row.id.toString(),
          searchHint: 'Search market, source position, or status',
          filters: [
            EnterpriseTableFilter(
              label: 'Completed',
              predicate: (row) =>
                  row.status.toLowerCase().contains('completed'),
            ),
            EnterpriseTableFilter(
              label: 'Failed',
              predicate: (row) => row.status.toLowerCase().contains('fail'),
            ),
          ],
          columns: [
            EnterpriseTableColumn(
              label: 'Copied Forecast ID',
              width: 120,
              cell: (row) => '#${row.id}',
              sortValue: (row) => row.id,
            ),
            EnterpriseTableColumn(
              label: 'Relationship',
              width: 100,
              cell: (row) => row.relationshipId.toString(),
              sortValue: (row) => row.relationshipId,
            ),
            EnterpriseTableColumn(
              label: 'Source Position',
              width: 100,
              cell: (row) => row.sourceTradeId.toString(),
              sortValue: (row) => row.sourceTradeId,
            ),
            EnterpriseTableColumn(
              label: 'Market',
              width: 80,
              cell: (row) => row.marketId.toString(),
              sortValue: (row) => row.marketId,
            ),
            EnterpriseTableColumn(
              label: 'Allocation',
              width: 90,
              numeric: true,
              cell: (row) =>
                  '${(row.copiedAllocation * 100).toStringAsFixed(1)}%',
              sortValue: (row) => row.copiedAllocation,
            ),
            EnterpriseTableColumn(
              label: 'Amount',
              width: 100,
              numeric: true,
              cell: (row) => formatUsd(row.copiedAmount),
              sortValue: (row) => row.copiedAmount,
            ),
            EnterpriseTableColumn(
              label: 'Status',
              width: 110,
              cell: (row) => row.status,
              sortValue: (row) => row.status,
            ),
          ],
          expandedBuilder: (row) => Text(
            'Created ${row.createdAt}${row.reason == null ? '' : ' • Reason: ${row.reason}'}',
            style: const TextStyle(color: AetherColors.muted),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _errorPanel(error.toString()),
    );
  }

  Widget _errorPanel(String message) {
    return EnterprisePanel(
      title: 'Unable to load copy forecasts data',
      child:
          Text(message, style: const TextStyle(color: AetherColors.critical)),
    );
  }

  Future<void> _submitFollow() async {
    if (_followState == ActionButtonState.loading) return;

    if (_followState == ActionButtonState.failure) {
      setState(() {
        _followError = null;
        _followState = ActionButtonState.idle;
      });
      return;
    }

    final sourceId = int.tryParse(_sourceIdController.text.trim());
    if (sourceId == null) {
      setState(() {
        _followError = 'Enter a numeric source forecaster ID.';
        _followState = ActionButtonState.failure;
      });
      return;
    }

    setState(() {
      _followError = null;
      _followState = ActionButtonState.loading;
    });

    try {
      final payload = {
        'source_user_id': sourceId,
        'source_type': 'trader',
        'allocation_pct': _allocation,
        'max_loss_pct': _maxLoss,
        'risk_level': _risk,
        'auto_stop_threshold': _maxLoss,
        'max_follower_exposure': 200000,
        'allowed_market_ids': <int>[],
      };
      await ref.read(apiClientProvider).followTrader(payload);
      ref.invalidate(copyRelationshipsProvider);
      ref.invalidate(copyPortfolioProvider);
      if (!mounted) return;
      setState(() {
        _followState = ActionButtonState.success;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copy forecast relationship activated.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _followState = ActionButtonState.failure;
        _followError = error.toString();
      });
    }
  }

  Future<void> _openSettings(CopyRelationshipModel relation) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CopySettingsDialog(
        title: 'Copy Settings',
        initialAllocation: relation.allocationPct,
        initialMaxLoss: relation.maxLossPct,
        initialAutoStop: relation.autoStopThreshold,
        initialRisk: relation.riskLevel,
      ),
    );

    if (result == null) return;
    await ref.read(apiClientProvider).updateCopySettings(relation.id, result);
    ref.invalidate(copyRelationshipsProvider);
  }

  Future<void> _stopFollowing(int relationshipId) async {
    await ref.read(apiClientProvider).stopCopying(relationshipId);
    ref.invalidate(copyRelationshipsProvider);
    ref.invalidate(copyPortfolioProvider);
  }
}
