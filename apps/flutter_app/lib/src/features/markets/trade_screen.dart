import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

enum _CreationStage {
  defineEvent,
  defineOutcomes,
  configureLiquidity,
  defineResolution,
  walletAuthorization,
  chainPublication,
  marketLive,
}

class TradeScreen extends ConsumerStatefulWidget {
  const TradeScreen({super.key});

  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> {
  _CreationStage _stage = _CreationStage.defineEvent;
  ActionButtonState _actionState = ActionButtonState.idle;

  final TextEditingController _questionController = TextEditingController(
    text: 'Will BTC exceed \$120k by Dec 31, 2026?',
  );
  final TextEditingController _descriptionController = TextEditingController(
    text:
        'This market resolves YES if BTC/USD reference price on approved benchmark feeds is greater than \$120,000 at 23:59:59 UTC on Dec 31, 2026.',
  );
  final TextEditingController _expiryController =
      TextEditingController(text: '2026-12-31');
  final TextEditingController _oracleController =
      TextEditingController(text: 'HashKey Verified Oracle Mesh');
  final TextEditingController _resolutionRulesController =
      TextEditingController(
    text:
        'AI resolution engine aggregates signed evidence sources, publishes confidence, and opens a 24h juror dispute window before final settlement.',
  );

  String _category = 'Macro';
  double _yesSeed = 52;
  double _initialLiquidity = 150000;
  double _disputeWindowHours = 24;
  bool _thinMarketSupport = true;
  bool _autoAgentRebalance = true;

  String? _failure;
  Market? _createdMarket;

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    _expiryController.dispose();
    _oracleController.dispose();
    _resolutionRulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletSessionProvider);
    final noSeed = 100 - _yesSeed;

    return AppScaffold(
      title: 'Create Prediction',
      subtitle:
          'Publish new event-based prediction markets with AI resolution, on-chain settlement, and institutional controls.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1180;
          if (compact) {
            return ListView(
              children: [
                _stageRail(),
                const SizedBox(height: AetherSpacing.lg),
                _stagePanel(
                  walletConnected: wallet.connected,
                  noSeed: noSeed,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: _stageRail()),
              const SizedBox(width: AetherSpacing.lg),
              Expanded(
                child: _stagePanel(
                  walletConnected: wallet.connected,
                  noSeed: noSeed,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stageRail() {
    final steps = _steps();
    return EnterprisePanel(
      title: 'Market Creation Stages',
      subtitle:
          'Every market must pass forecasting, resolution, and settlement controls.',
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
                  style:
                      const TextStyle(color: AetherColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stagePanel({
    required bool walletConnected,
    required double noSeed,
  }) {
    return EnterprisePanel(
      title: _steps()[_stage.index].title,
      subtitle: _steps()[_stage.index].description,
      trailing: Wrap(
        spacing: AetherSpacing.sm,
        children: [
          StatusBadge(label: 'Stage ${_stage.index + 1}/7'),
          StatusBadge(
            label: walletConnected ? 'Wallet ready' : 'Wallet offline',
            color:
                walletConnected ? AetherColors.success : AetherColors.warning,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stageBody(walletConnected: walletConnected, noSeed: noSeed),
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
                label: _stage == _CreationStage.marketLive
                    ? 'Create Another Market'
                    : 'Continue',
                state: _effectiveActionState(walletConnected),
                retryLabel: 'Retry Step',
                onPressed: () => _advance(walletConnected: walletConnected),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageBody({
    required bool walletConnected,
    required double noSeed,
  }) {
    return switch (_stage) {
      _CreationStage.defineEvent => _defineEvent(),
      _CreationStage.defineOutcomes => _defineOutcomes(noSeed),
      _CreationStage.configureLiquidity => _configureLiquidity(),
      _CreationStage.defineResolution => _defineResolution(),
      _CreationStage.walletAuthorization =>
        _walletAuthorization(walletConnected),
      _CreationStage.chainPublication => _chainPublication(),
      _CreationStage.marketLive => _marketLive(),
    };
  }

  Widget _defineEvent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _questionController,
          decoration: const InputDecoration(labelText: 'Event question'),
        ),
        const SizedBox(height: AetherSpacing.sm),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Market specification',
            hintText:
                'Define explicit YES/NO resolution conditions and evidence policy.',
          ),
        ),
        const SizedBox(height: AetherSpacing.sm),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Macro', child: Text('Macro')),
                  DropdownMenuItem(value: 'DeFi', child: Text('DeFi')),
                  DropdownMenuItem(
                      value: 'Regulation', child: Text('Regulation')),
                  DropdownMenuItem(value: 'Protocol', child: Text('Protocol')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _category = value);
                },
              ),
            ),
            const SizedBox(width: AetherSpacing.sm),
            Expanded(
              child: TextField(
                controller: _expiryController,
                decoration:
                    const InputDecoration(labelText: 'Expiry (YYYY-MM-DD)'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _defineOutcomes(double noSeed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Initial YES forecast confidence ${_yesSeed.toStringAsFixed(0)}%'),
        Slider(
          min: 5,
          max: 95,
          divisions: 90,
          value: _yesSeed,
          label: '${_yesSeed.toStringAsFixed(0)}%',
          onChanged: (value) => setState(() => _yesSeed = value),
        ),
        const SizedBox(height: AetherSpacing.sm),
        _infoCard(
          label: 'YES Seed Probability',
          value: '${_yesSeed.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: AetherSpacing.sm),
        _infoCard(
          label: 'NO Seed Probability',
          value: '${noSeed.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: AetherSpacing.sm),
        const Text(
          'Seed probabilities initialize discovery and are updated by autonomous agents and live participant consensus.',
          style: TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _configureLiquidity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Initial event liquidity ${formatUsd(_initialLiquidity)}'),
        Slider(
          min: 25000,
          max: 1500000,
          divisions: 59,
          value: _initialLiquidity,
          label: formatUsd(_initialLiquidity),
          onChanged: (value) => setState(() => _initialLiquidity = value),
        ),
        const SizedBox(height: AetherSpacing.sm),
        SwitchListTile(
          value: _thinMarketSupport,
          onChanged: (value) => setState(() => _thinMarketSupport = value),
          title: const Text('Enable thin market support'),
          subtitle: const Text(
              'Allows smart liquidity agents to intervene when depth confidence drops.'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: _autoAgentRebalance,
          onChanged: (value) => setState(() => _autoAgentRebalance = value),
          title: const Text('Enable autonomous rebalancing'),
          subtitle: const Text(
              'AI agents optimize YES/NO pool balance and implied odds spread.'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _defineResolution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _oracleController,
          decoration: const InputDecoration(labelText: 'Resolution source'),
        ),
        const SizedBox(height: AetherSpacing.sm),
        Text('Dispute window ${_disputeWindowHours.toStringAsFixed(0)} hours'),
        Slider(
          min: 6,
          max: 96,
          divisions: 15,
          value: _disputeWindowHours,
          label: '${_disputeWindowHours.toStringAsFixed(0)}h',
          onChanged: (value) => setState(() => _disputeWindowHours = value),
        ),
        const SizedBox(height: AetherSpacing.sm),
        TextField(
          controller: _resolutionRulesController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'AI resolution policy'),
        ),
      ],
    );
  }

  Widget _walletAuthorization(bool walletConnected) {
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
          'On continue, market creation intent is validated, signed, and prepared for on-chain publication on HashKey Chain.',
          style: TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _chainPublication() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        LinearProgressIndicator(minHeight: 8),
        SizedBox(height: AetherSpacing.sm),
        Text(
          'Publishing market creation transaction to chain and waiting for final confirmation.',
          style: TextStyle(color: AetherColors.muted),
        ),
      ],
    );
  }

  Widget _marketLive() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusBadge(
          label: 'Prediction market published',
          color: AetherColors.success,
        ),
        const SizedBox(height: AetherSpacing.sm),
        Text(_createdMarket?.title ?? _questionController.text.trim()),
        const SizedBox(height: AetherSpacing.sm),
        Text(
          'Market ID ${_createdMarket?.id ?? 'pending'} • Liquidity ${formatUsd(_initialLiquidity)} • Resolution window ${_disputeWindowHours.toStringAsFixed(0)}h',
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
      _StageDescriptor(
          'Define Event', 'Write the event question and resolution criteria.'),
      _StageDescriptor('Define Outcomes',
          'Set YES/NO seed probabilities and confidence posture.'),
      _StageDescriptor('Configure Liquidity',
          'Allocate event liquidity and thin-market protections.'),
      _StageDescriptor('Define Resolution',
          'Set evidence sources, dispute window, and finality policy.'),
      _StageDescriptor(
          'Wallet Authorization', 'Authorize market publication intent.'),
      _StageDescriptor('Chain Publication',
          'Publish creation transaction on HashKey Chain.'),
      _StageDescriptor(
          'Market Live', 'Activate market for open forecast positions.'),
    ];
  }

  ActionButtonState _effectiveActionState(bool walletConnected) {
    if (_actionState == ActionButtonState.loading ||
        _actionState == ActionButtonState.failure ||
        _actionState == ActionButtonState.success) {
      return _actionState;
    }

    if (_stage == _CreationStage.walletAuthorization && !walletConnected) {
      return ActionButtonState.disabled;
    }

    return ActionButtonState.idle;
  }

  Future<void> _advance({required bool walletConnected}) async {
    if (_actionState == ActionButtonState.loading) return;

    if (_actionState == ActionButtonState.failure) {
      setState(() {
        _failure = null;
        _actionState = ActionButtonState.idle;
        _stage = _CreationStage.walletAuthorization;
      });
      return;
    }

    if (_stage == _CreationStage.marketLive) {
      setState(() {
        _stage = _CreationStage.defineEvent;
        _actionState = ActionButtonState.idle;
        _failure = null;
        _createdMarket = null;
      });
      return;
    }

    if (_stage == _CreationStage.walletAuthorization) {
      if (!walletConnected) {
        setState(() {
          _failure = 'Connect wallet before publishing prediction market.';
          _actionState = ActionButtonState.failure;
        });
        return;
      }

      if (_questionController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty) {
        setState(() {
          _failure = 'Event question and market specification are required.';
          _actionState = ActionButtonState.failure;
        });
        return;
      }

      setState(() {
        _failure = null;
        _actionState = ActionButtonState.loading;
      });

      try {
        final market = await _createMarketRecord();
        if (!mounted) return;

        setState(() {
          _createdMarket = market;
          _stage = _CreationStage.chainPublication;
        });

        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        setState(() {
          _actionState = ActionButtonState.success;
          _stage = _CreationStage.marketLive;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _actionState = ActionButtonState.failure;
          _failure = 'Market publication failed: $error';
          _stage = _CreationStage.walletAuthorization;
        });
      }
      return;
    }

    setState(() {
      _failure = null;
      _actionState = ActionButtonState.idle;
      _stage = _CreationStage.values[_stage.index + 1];
    });
  }

  Future<Market> _createMarketRecord() async {
    final wallet = ref.read(walletSessionProvider);
    final payload = {
      'title': _questionController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _category,
      'oracle_source': _oracleController.text.trim(),
      'expiry_at': '${_expiryController.text.trim()}T00:00:00Z',
      'resolution_rules': _resolutionRulesController.text.trim(),
      'collateral_token': 'USDC',
      'liquidity_amount': _initialLiquidity,
      'wallet_address': wallet.address,
    };
    final market = await ref.read(apiClientProvider).createMarket(payload);
    ref.invalidate(marketListProvider);
    return market;
  }

  void _back() {
    if (_stage.index == 0) return;
    setState(() {
      _actionState = ActionButtonState.idle;
      _failure = null;
      _stage = _CreationStage.values[_stage.index - 1];
    });
  }
}

class _StageDescriptor {
  const _StageDescriptor(this.title, this.description);

  final String title;
  final String description;
}
