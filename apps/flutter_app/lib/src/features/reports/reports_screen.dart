import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _startController = TextEditingController(text: '2026-04-01');
  final _endController = TextEditingController(text: '2026-04-08');
  final _accountController = TextEditingController(text: 'Primary Desk');

  String _reportType = 'Forecast Performance Statement';
  String _format = 'CSV';
  ActionButtonState _generateState = ActionButtonState.idle;
  String? _statusMessage;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports',
      subtitle:
          'Regulatory, audit, and forecast intelligence reporting workflows with generation tracking.',
      child: ListView(
        children: [
          EnterprisePanel(
            title: 'Generate Report',
            subtitle: 'Configure scope, format, and forecast account.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 920;
                return Column(
                  children: [
                    if (compact) ...[
                      TextField(
                        controller: _startController,
                        decoration: const InputDecoration(
                          labelText: 'Start Date (YYYY-MM-DD)',
                        ),
                      ),
                      const SizedBox(height: AetherSpacing.sm),
                      TextField(
                        controller: _endController,
                        decoration: const InputDecoration(
                          labelText: 'End Date (YYYY-MM-DD)',
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startController,
                              decoration: const InputDecoration(
                                labelText: 'Start Date (YYYY-MM-DD)',
                              ),
                            ),
                          ),
                          const SizedBox(width: AetherSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _endController,
                              decoration: const InputDecoration(
                                labelText: 'End Date (YYYY-MM-DD)',
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AetherSpacing.sm),
                    if (compact) ...[
                      TextField(
                        controller: _accountController,
                        decoration: const InputDecoration(
                          labelText: 'Account / Desk',
                        ),
                      ),
                      const SizedBox(height: AetherSpacing.sm),
                      DropdownButtonFormField<String>(
                        value: _reportType,
                        decoration:
                            const InputDecoration(labelText: 'Report Type'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Forecast Performance Statement',
                            child: Text('Forecast Performance Statement'),
                          ),
                          DropdownMenuItem(
                            value: 'Forecast Transaction History',
                            child: Text('Forecast Transaction History'),
                          ),
                          DropdownMenuItem(
                            value: 'Risk Intelligence Summary',
                            child: Text('Risk Intelligence Summary'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _reportType = value);
                        },
                      ),
                      const SizedBox(height: AetherSpacing.sm),
                      DropdownButtonFormField<String>(
                        value: _format,
                        decoration: const InputDecoration(labelText: 'Format'),
                        items: const [
                          DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                          DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _format = value);
                        },
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _accountController,
                              decoration: const InputDecoration(
                                labelText: 'Account / Desk',
                              ),
                            ),
                          ),
                          const SizedBox(width: AetherSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _reportType,
                              decoration: const InputDecoration(
                                labelText: 'Report Type',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Forecast Performance Statement',
                                  child: Text('Forecast Performance Statement'),
                                ),
                                DropdownMenuItem(
                                  value: 'Forecast Transaction History',
                                  child: Text('Forecast Transaction History'),
                                ),
                                DropdownMenuItem(
                                  value: 'Risk Intelligence Summary',
                                  child: Text('Risk Intelligence Summary'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _reportType = value);
                              },
                            ),
                          ),
                          const SizedBox(width: AetherSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _format,
                              decoration:
                                  const InputDecoration(labelText: 'Format'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'CSV', child: Text('CSV')),
                                DropdownMenuItem(
                                    value: 'PDF', child: Text('PDF')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _format = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: AetherSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _generateState == ActionButtonState.failure
                                ? AetherColors.critical
                                : _generateState == ActionButtonState.success
                                    ? AetherColors.success
                                    : AetherColors.muted,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AetherSpacing.md),
                    if (compact) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ActionStateButton(
                          label: 'Generate Report',
                          state: _generateState,
                          retryLabel: 'Retry Generation',
                          onPressed: _generate,
                        ),
                      ),
                      const SizedBox(height: AetherSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _generateState == ActionButtonState.loading
                              ? null
                              : () => setState(() {
                                    _statusMessage =
                                        'Template saved for recurring schedule.';
                                  }),
                          icon: const Icon(Icons.schedule),
                          label: const Text('Save Schedule'),
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          ActionStateButton(
                            label: 'Generate Report',
                            state: _generateState,
                            retryLabel: 'Retry Generation',
                            onPressed: _generate,
                          ),
                          const SizedBox(width: AetherSpacing.sm),
                          OutlinedButton.icon(
                            onPressed:
                                _generateState == ActionButtonState.loading
                                    ? null
                                    : () => setState(() {
                                          _statusMessage =
                                              'Template saved for recurring schedule.';
                                        }),
                            icon: const Icon(Icons.schedule),
                            label: const Text('Save Schedule'),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AetherSpacing.lg),
          EnterpriseDataTable<_ReportJob>(
            title: 'Report Job Queue',
            subtitle:
                'Generation, delivery, and audit state for each forecast report run.',
            rows: _jobs(),
            rowId: (row) => row.id,
            searchHint: 'Search report job id or account',
            filters: [
              EnterpriseTableFilter(
                label: 'Completed',
                predicate: (row) => row.status == 'Completed',
              ),
              EnterpriseTableFilter(
                label: 'Failed',
                predicate: (row) => row.status == 'Failed',
              ),
            ],
            columns: [
              EnterpriseTableColumn(
                label: 'Job ID',
                width: 120,
                cell: (row) => row.id,
                sortValue: (row) => row.id,
              ),
              EnterpriseTableColumn(
                label: 'Generated At',
                width: 180,
                cell: (row) => row.generatedAt,
                sortValue: (row) => row.generatedAt,
              ),
              EnterpriseTableColumn(
                label: 'Type',
                width: 180,
                cell: (row) => row.type,
                sortValue: (row) => row.type,
              ),
              EnterpriseTableColumn(
                label: 'Format',
                width: 80,
                cell: (row) => row.format,
                sortValue: (row) => row.format,
              ),
              EnterpriseTableColumn(
                label: 'Status',
                width: 100,
                cell: (row) => row.status,
                sortValue: (row) => row.status,
              ),
              EnterpriseTableColumn(
                label: 'Account',
                width: 140,
                cell: (row) => row.account,
                sortValue: (row) => row.account,
              ),
            ],
            expandedBuilder: (row) => Row(
              children: [
                StatusBadge(
                  label: row.status,
                  color: row.status == 'Completed'
                      ? AetherColors.success
                      : row.status == 'Failed'
                          ? AetherColors.critical
                          : AetherColors.warning,
                ),
                const SizedBox(width: AetherSpacing.sm),
                Text(
                  'Delivered to ${row.destination}',
                  style: const TextStyle(color: AetherColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    if (_generateState == ActionButtonState.loading) return;

    if (_generateState == ActionButtonState.failure) {
      setState(() {
        _generateState = ActionButtonState.idle;
        _statusMessage = null;
      });
      return;
    }

    setState(() {
      _generateState = ActionButtonState.loading;
      _statusMessage = 'Submitting forecast report job...';
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final badRange =
        _startController.text.trim().compareTo(_endController.text.trim()) > 0;
    if (badRange) {
      setState(() {
        _generateState = ActionButtonState.failure;
        _statusMessage =
            'Invalid date range. Start date must be before end date.';
      });
      return;
    }

    setState(() {
      _generateState = ActionButtonState.success;
      _statusMessage = 'Forecast report generated and queued for delivery.';
    });
  }

  List<_ReportJob> _jobs() {
    return const [
      _ReportJob(
        id: 'RP-9412',
        generatedAt: '2026-04-08T14:10:00Z',
        type: 'Forecast Performance Statement',
        format: 'PDF',
        status: 'Completed',
        account: 'Primary Desk',
        destination: 'secure-vault://reports/2026-04-08',
      ),
      _ReportJob(
        id: 'RP-9408',
        generatedAt: '2026-04-08T13:42:00Z',
        type: 'Forecast Transaction History',
        format: 'CSV',
        status: 'Completed',
        account: 'Primary Desk',
        destination: 'secure-vault://reports/2026-04-08',
      ),
      _ReportJob(
        id: 'RP-9391',
        generatedAt: '2026-04-08T12:22:00Z',
        type: 'Risk Intelligence Summary',
        format: 'PDF',
        status: 'Pending',
        account: 'Risk Desk',
        destination: 'secure-vault://reports/risk',
      ),
      _ReportJob(
        id: 'RP-9380',
        generatedAt: '2026-04-08T10:01:00Z',
        type: 'Forecast Transaction History',
        format: 'CSV',
        status: 'Failed',
        account: 'Treasury',
        destination: 'secure-vault://reports/treasury',
      ),
    ];
  }
}

class _ReportJob {
  const _ReportJob({
    required this.id,
    required this.generatedAt,
    required this.type,
    required this.format,
    required this.status,
    required this.account,
    required this.destination,
  });

  final String id;
  final String generatedAt;
  final String type;
  final String format;
  final String status;
  final String account;
  final String destination;
}
