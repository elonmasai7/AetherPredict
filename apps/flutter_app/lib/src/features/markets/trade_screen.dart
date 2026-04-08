import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

enum _TradeStage {
  marketSelect,
  configureOrder,
  riskPreview,
  walletConfirm,
  chainPending,
  settlementReceipt,
}

class TradeScreen extends ConsumerStatefulWidget {
  const TradeScreen({super.key});

  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> {
  _TradeStage _stage = _TradeStage.marketSelect;
  ActionButtonState _actionState = ActionButtonState.idle;

  int _marketIndex = 0;
  String _side = 'YES';
  double _collateral = 5000;
  double _slippageBps = 35;
  String? _failure;
  String? _receipt;

  @override
  Widget build(BuildContext context) {
    final marketsValue = ref.watch(marketListProvider);
    final wallet = ref.watch(walletSessionProvider);

    return AppScaffold(
      title: 'Trading Workflow',
      subtitle: 'Controlled execution path with pre-trade risk and post-trade settlement controls.',
      child: marketsValue.when(
        data: (markets) {
          if (markets.isEmpty) {
            return const EmptyStateCard(
              icon: Icons.timeline,
              title: 'No tradable markets available',
              message:
                  'Market listing is empty. Create or ingest markets before launching execution workflows.',
            );
          }

          _marketIndex = _marketIndex.clamp(0, markets.length - 1).toInt();
          final market = markets[_marketIndex];
          final impliedPrice =
              _side == 'YES' ? market.yesProbability : 1 - market.yesProbability;
          final estimatedContracts = _collateral / max(impliedPrice, 0.01);
          final estimatedFee = _collateral * (_slippageBps / 10000);

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1180;
              if (compact) {
                return ListView(
                  children: [
                    _stageRail(),
                    const SizedBox(height: AetherSpacing.lg),
                    _stagePanel(
                      market: market,
                      walletConnected: wallet.connected,
                      estimatedContracts: estimatedContracts,
                      impliedPrice: impliedPrice,
                      estimatedFee: estimatedFee,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 320, child: _stageRail()),
                  const SizedBox(width: AetherSpacing.lg),
                  Expanded(
                    child: _stagePanel(
                      market: market,
                      walletConnected: wallet.connected,
                      estimatedContracts: estimatedContracts,
                      impliedPrice: impliedPrice,
                      estimatedFee: estimatedFee,
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EnterprisePanel(
          title: 'Unable to initialize trading workflow',
          child: Text(
            error.toString(),
            style: const TextStyle(color: AetherColors.critical),
          ),
        ),
      ),
    );
  }

  Widget _stageRail() {
    final steps = _steps();
    return EnterprisePanel(
      title: 'Execution Stages',
      subtitle: 'Every order must pass all controls before settlement.',
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _stageTile(
              index: i,
              title: steps[i].title,
              description: steps[i].description,
              active: i == _stage.index,
              completed: i < _stage.index,
            ),
          if (_failure != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: AetherSpacing.sm),
                child: Text(
                  _failure!,
                  style: const TextStyle(color: AetherColors.critical),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stageTile({
    required int index,
    required String title,
    required String description,
    required bool active,
    required bool completed,
  }) {
    final color = completed
        ? AetherColors.success
        : active
            ? AetherColors.accent
            : AetherColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AetherSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: AetherSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? AetherColors.text : AetherColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: AetherColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stagePanel({
    required Market market,
    required bool walletConnected,
    required double impliedPrice,
    required double estimatedContracts,
    required double estimatedFee,
  }) {
    return EnterprisePanel(
      title: _steps()[_stage.index].title,
      subtitle: _steps()[_stage.index].description,
      trailing: Wrap(
        spacing: AetherSpacing.sm,
        children: [
          StatusBadge(label: 'Stage ${_stage.index + 1}/6'),
          StatusBadge(
            label: walletConnected ? 'Wallet ready' : 'Wallet offline',
            color: walletConnected ? AetherColors.success : AetherColors.warning,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stageBody(
            market: market,
            walletConnected: walletConnected,
            impliedPrice: impliedPrice,
            estimatedContracts: estimatedContracts,
            estimatedFee: estimatedFee,
          ),
          const SizedBox(height: AetherSpacing.lg),
          Row(
            children: [
              OutlinedButton(
                onPressed: _stage.index == 0 ||
                        _actionState == ActionButtonState.loading
                    ? null
                    : _back,
                child: const Text('Back'),
              ),
              const SizedBox(width: AetherSpacing.sm),
              ActionStateButton(
                label: _stage == _TradeStage.settlementReceipt
                    ? 'Start New Trade'
                    : 'Continue',
                state: _effectiveActionState(walletConnected),
                retryLabel: 'Retry Step',
                onPressed: () => _advance(
                  walletConnected: walletConnected,
                  market: market,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageBody({
    required Market market,
    required bool walletConnected,
    required double impliedPrice,
    required double estimatedContracts,
    required double estimatedFee,
  }) {
    return switch (_stage) {
      _TradeStage.marketSelect => _marketSelection(market),
      _TradeStage.configureOrder => _configureOrder(market),
      _TradeStage.riskPreview => _riskPreview(estimatedContracts, estimatedFee),
      _TradeStage.walletConfirm => _walletConfirm(walletConnected),
      _TradeStage.chainPending => _chainPending(),
      _TradeStage.settlementReceipt => _settlementReceipt(impliedPrice),
    };
  }

  Widget _marketSelection(Market market) {
    final markets = ref.read(marketListProvider).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: _marketIndex,
          decoration: const InputDecoration(labelText: 'Market'),
          items: [
            for (var i = 0; i < markets.length; i++)
              DropdownMenuItem<int>(
                value: i,
                child: Text(markets[i].title),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _marketIndex = value;
              _actionState = ActionButtonState.idle;
            });
          },
        ),
        const SizedBox(height: AetherSpacing.md),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                label: 'Category',
                value: market.category,
              ),
            ),
            const SizedBox(width: AetherSpacing.sm),
            Expanded(
              child: _infoCard(
                label: 'AI Confidence',
                value: '${(market.aiConfidence * 100).toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _configureOrder(Market market) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AetherSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Buy YES'),
              selected: _side == 'YES',
              onSelected: (_) => setState(() => _side = 'YES'),
            ),
            ChoiceChip(
              label: const Text('Buy NO'),
              selected: _side == 'NO',
              onSelected: (_) => setState(() => _side = 'NO'),
            ),
          ],
        ),
        const SizedBox(height: AetherSpacing.md),
        Text('Collateral: ${formatUsd(_collateral)}'),
        Slider(
          min: 250,
          max: 25000,
          divisions: 99,
          value: _collateral,
          label: formatUsd(_collateral),
          onChanged: (value) => setState(() => _collateral = value),
        ),
        const SizedBox(height: AetherSpacing.sm),
        Text('Slippage tolerance: ${_slippageBps.toStringAsFixed(0)} bps'),
        Slider(
          min: 5,
          max: 120,
          divisions: 23,
          value: _slippageBps,
          label: '${_slippageBps.toStringAsFixed(0)} bps',
          onChanged: (value) => setState(() => _slippageBps = value),
        ),
        const SizedBox(height: AetherSpacing.sm),
        Text(
          'Target market: ${market.title}',
          style: const TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _riskPreview(double estimatedContracts, double estimatedFee) {
    final leverageFlag = _collateral > 15000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(
          label: 'Estimated contracts',
          value: estimatedContracts.toStringAsFixed(0),
        ),
        const SizedBox(height: AetherSpacing.sm),
        _infoCard(
          label: 'Estimated fees',
          value: formatUsd(estimatedFee, fractionDigits: 2),
        ),
        const SizedBox(height: AetherSpacing.sm),
        _infoCard(
          label: 'Risk classification',
          value: leverageFlag ? 'Heightened' : 'Standard',
          accent: leverageFlag ? AetherColors.warning : AetherColors.success,
        ),
        const SizedBox(height: AetherSpacing.sm),
        const Text(
          'Risk checks include portfolio concentration, slippage stress, and exposure caps before wallet confirmation.',
          style: TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _walletConfirm(bool walletConnected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(
          label: walletConnected
              ? 'Wallet signature available'
              : 'Wallet connection required',
          color: walletConnected ? AetherColors.success : AetherColors.warning,
        ),
        const SizedBox(height: AetherSpacing.sm),
        const Text(
          'On continue, the wallet receives a sign request. Rejections and chain reverts are captured as retryable failures.',
          style: TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _chainPending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        LinearProgressIndicator(minHeight: 8),
        SizedBox(height: AetherSpacing.sm),
        Text(
          'Transaction broadcasted to chain. Waiting for confirmation and settlement receipt.',
          style: TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _settlementReceipt(double impliedPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(label: 'Settlement successful', color: AetherColors.success),
        const SizedBox(height: AetherSpacing.sm),
        Text(_receipt ?? 'No receipt generated'),
        const SizedBox(height: AetherSpacing.sm),
        Text(
          'Executed side $_side at ${(impliedPrice * 100).toStringAsFixed(2)}c with ${_slippageBps.toStringAsFixed(0)} bps slippage guard.',
          style: const TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String label,
    required String value,
    Color? accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(AetherRadii.md),
        border: Border.all(color: AetherColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AetherColors.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: accent ?? AetherColors.text,
            ),
          ),
        ],
      ),
    );
  }

  List<_StageDescriptor> _steps() {
    return const [
      _StageDescriptor('Market Select', 'Choose an active market tape.'),
      _StageDescriptor('Configure Order', 'Set side, collateral, and slippage.'),
      _StageDescriptor('Risk Preview', 'Validate exposure and fee impacts.'),
      _StageDescriptor('Wallet Confirm', 'Request signature and confirm intent.'),
      _StageDescriptor('Chain Pending', 'Await network settlement confirmation.'),
      _StageDescriptor('Settlement Receipt', 'Finalize ticket and log outcome.'),
    ];
  }

  ActionButtonState _effectiveActionState(bool walletConnected) {
    if (_actionState == ActionButtonState.loading ||
        _actionState == ActionButtonState.failure ||
        _actionState == ActionButtonState.success) {
      return _actionState;
    }

    if (_stage == _TradeStage.walletConfirm && !walletConnected) {
      return ActionButtonState.disabled;
    }

    return ActionButtonState.idle;
  }

  Future<void> _advance({
    required bool walletConnected,
    required Market market,
  }) async {
    if (_actionState == ActionButtonState.loading) return;

    if (_actionState == ActionButtonState.failure) {
      setState(() {
        _failure = null;
        _actionState = ActionButtonState.idle;
        _stage = _TradeStage.walletConfirm;
      });
      return;
    }

    if (_stage == _TradeStage.settlementReceipt) {
      setState(() {
        _stage = _TradeStage.marketSelect;
        _actionState = ActionButtonState.idle;
        _failure = null;
        _receipt = null;
      });
      return;
    }

    if (_stage == _TradeStage.walletConfirm) {
      if (!walletConnected) {
        setState(() {
          _failure = 'Connect wallet before signature request.';
          _actionState = ActionButtonState.failure;
        });
        return;
      }

      setState(() {
        _failure = null;
        _actionState = ActionButtonState.loading;
      });

      await Future<void>.delayed(const Duration(seconds: 1));
      setState(() {
        _stage = _TradeStage.chainPending;
      });

      await Future<void>.delayed(const Duration(seconds: 2));
      final random = Random();
      final success = random.nextInt(100) > 18;

      if (!mounted) return;

      if (success) {
        setState(() {
          _actionState = ActionButtonState.success;
          _stage = _TradeStage.settlementReceipt;
          _receipt =
              'Ticket TR-${DateTime.now().millisecondsSinceEpoch % 100000} settled on ${market.id} at ${DateTime.now().toUtc().toIso8601String()}';
        });
      } else {
        setState(() {
          _actionState = ActionButtonState.failure;
          _failure = 'Chain confirmation timed out. Retry wallet confirmation.';
          _stage = _TradeStage.walletConfirm;
        });
      }
      return;
    }

    setState(() {
      _failure = null;
      _actionState = ActionButtonState.idle;
      _stage = _TradeStage.values[_stage.index + 1];
    });
  }

  void _back() {
    if (_stage.index == 0) return;
    setState(() {
      _actionState = ActionButtonState.idle;
      _failure = null;
      _stage = _TradeStage.values[_stage.index - 1];
    });
  }
}

class _StageDescriptor {
  const _StageDescriptor(this.title, this.description);

  final String title;
  final String description;
}
