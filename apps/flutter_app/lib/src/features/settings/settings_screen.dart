import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deskAlerts = true;
  bool _riskEscalations = true;
  bool _pushNotifications = true;
  bool _autoHedge = true;
  bool _require2fa = true;
  String _timezone = 'UTC';
  ActionButtonState _saveState = ActionButtonState.idle;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      subtitle:
          'Workspace, security, and forecasting preferences for institutional prediction operations.',
      child: ListView(
        children: [
          EnterprisePanel(
            title: 'Workspace Preferences',
            subtitle: 'Regional and forecasting behavior defaults.',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _timezone,
                  decoration: const InputDecoration(labelText: 'Timezone'),
                  items: const [
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                    DropdownMenuItem(
                        value: 'America/New_York',
                        child: Text('America/New_York')),
                    DropdownMenuItem(
                        value: 'Asia/Singapore', child: Text('Asia/Singapore')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _timezone = value);
                  },
                ),
                const SizedBox(height: AetherSpacing.sm),
                SwitchListTile(
                  value: _autoHedge,
                  onChanged: (value) => setState(() => _autoHedge = value),
                  title: const Text('Enable auto-hedge recommendations'),
                  subtitle: const Text(
                      'Automatically stage hedge suggestions in Risk Intelligence and position workflows.'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          EnterprisePanel(
            title: 'Notifications',
            subtitle: 'Desk alert routing and escalation preferences.',
            child: Column(
              children: [
                SwitchListTile(
                  value: _deskAlerts,
                  onChanged: (value) => setState(() => _deskAlerts = value),
                  title: const Text('Forecast desk alerts'),
                  subtitle: const Text(
                      'Position opens, closes, and settlement updates.'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _riskEscalations,
                  onChanged: (value) =>
                      setState(() => _riskEscalations = value),
                  title: const Text('Risk escalation alerts'),
                  subtitle: const Text(
                      'Notify when confidence volatility or risk limits approach breach thresholds.'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                  title: const Text('Push notifications'),
                  subtitle: const Text(
                      'Mobile push notifications for critical incidents.'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          EnterprisePanel(
            title: 'Security & Access',
            subtitle: 'Hardening controls for wallet and account access.',
            child: Column(
              children: [
                SwitchListTile(
                  value: _require2fa,
                  onChanged: (value) => setState(() => _require2fa = value),
                  title: const Text('Require 2FA for privileged actions'),
                  subtitle: const Text(
                      'Applies to withdrawals, vault allocations, and critical settings changes.'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AetherSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Rotate API Keys'),
                      ),
                    ),
                    const SizedBox(width: AetherSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.history),
                        label: const Text('Access Logs'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          EnterprisePanel(
            title: 'PredictFlow Dart Integration',
            subtitle:
                'Companion local engine endpoint for the Dart replacement of the old predictflow service.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base URL: ${AppConfig.predictFlowBaseUrl}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AetherSpacing.sm),
                const Text(
                  'Run the local engine with `cd predictflow && dart run bin/server.dart` if you want operations health checks and local engine workflows to connect.',
                  style: TextStyle(color: AetherColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          Row(
            children: [
              ActionStateButton(
                label: 'Save Settings',
                state: _saveState,
                onPressed: _save,
              ),
              const SizedBox(width: AetherSpacing.sm),
              OutlinedButton(
                onPressed: _saveState == ActionButtonState.loading
                    ? null
                    : () {
                        setState(() {
                          _deskAlerts = true;
                          _riskEscalations = true;
                          _pushNotifications = true;
                          _autoHedge = true;
                          _require2fa = true;
                          _timezone = 'UTC';
                        });
                      },
                child: const Text('Reset Defaults'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saveState == ActionButtonState.loading) return;

    setState(() {
      _saveState = ActionButtonState.loading;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _saveState = ActionButtonState.success;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _saveState = ActionButtonState.idle;
    });
  }
}
