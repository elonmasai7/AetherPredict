import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class OperationsConsoleScreen extends StatelessWidget {
  const OperationsConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Operations',
      subtitle:
          'Institutional operations center for forecast reliability, resolution governance, and protocol auditability.',
      child: DefaultTabController(
        length: 7,
        child: Column(
          children: [
            EnterprisePanel(
              child: Row(
                children: const [
                  Expanded(
                    child: StatusBadge(
                      label: 'System Status: Operational',
                      color: AetherColors.success,
                    ),
                  ),
                  SizedBox(width: AetherSpacing.sm),
                  Expanded(
                    child: StatusBadge(
                      label: 'Open Incidents: 1',
                      color: AetherColors.warning,
                    ),
                  ),
                  SizedBox(width: AetherSpacing.sm),
                  Expanded(
                    child: StatusBadge(
                      label: 'Critical Alerts: 0',
                      color: AetherColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AetherSpacing.md),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'System Status'),
                Tab(text: 'Incident Logs'),
                Tab(text: 'AI Model Health'),
                Tab(text: 'Forecast Audit Trail'),
                Tab(text: 'Dispute Queue'),
                Tab(text: 'Wallet Activity'),
                Tab(text: 'Protocol Treasury'),
              ],
            ),
            const SizedBox(height: AetherSpacing.md),
            const Expanded(
              child: TabBarView(
                children: [
                  _SystemStatusTab(),
                  _IncidentLogTab(),
                  _ModelHealthTab(),
                  _TradeAuditTab(),
                  _DisputeQueueTab(),
                  _WalletActivityTab(),
                  _TreasuryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemStatusTab extends StatelessWidget {
  const _SystemStatusTab();

  @override
  Widget build(BuildContext context) {
    return EnterpriseDataTable<_SystemStatusRow>(
      title: 'System Status Grid',
      subtitle: 'Live service uptime, latency, and current health state.',
      rows: const [
        _SystemStatusRow('API Gateway', '99.99%', '142 ms', 'Healthy'),
        _SystemStatusRow('Oracle Mesh', '99.97%', '186 ms', 'Healthy'),
        _SystemStatusRow('Resolution Engine', '99.92%', '302 ms', 'Watch'),
        _SystemStatusRow('WebSocket Streams', '99.96%', '88 ms', 'Healthy'),
        _SystemStatusRow('Risk Engine', '99.94%', '214 ms', 'Healthy'),
      ],
      rowId: (row) => row.service,
      searchHint: 'Search service',
      filters: [
        EnterpriseTableFilter(
          label: 'Watch',
          predicate: (row) => row.status == 'Watch',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Service',
          width: 220,
          cell: (row) => row.service,
          sortValue: (row) => row.service,
        ),
        EnterpriseTableColumn(
          label: 'Uptime',
          width: 110,
          numeric: true,
          cell: (row) => row.uptime,
          sortValue: (row) => row.uptime,
        ),
        EnterpriseTableColumn(
          label: 'Latency',
          width: 110,
          numeric: true,
          cell: (row) => row.latency,
          sortValue: (row) => row.latency,
        ),
        EnterpriseTableColumn(
          label: 'Status',
          width: 100,
          cell: (row) => row.status,
          sortValue: (row) => row.status,
        ),
      ],
    );
  }
}

class _IncidentLogTab extends StatelessWidget {
  const _IncidentLogTab();

  @override
  Widget build(BuildContext context) {
    return EnterpriseDataTable<_IncidentRow>(
      title: 'Incident Logs',
      subtitle: 'Incident lifecycle tracking with SLA ownership.',
      rows: const [
        _IncidentRow('INC-8821', '2026-04-08T11:10:00Z', 'Oracle drift alert',
            'Open', 'Ops'),
        _IncidentRow('INC-8819', '2026-04-08T09:45:00Z',
            'Resolution settlement delay', 'Resolved', 'Protocol'),
        _IncidentRow('INC-8812', '2026-04-07T21:20:00Z',
            'Risk engine retry spike', 'Resolved', 'Risk'),
      ],
      rowId: (row) => row.id,
      searchHint: 'Search incident id or summary',
      filters: [
        EnterpriseTableFilter(
          label: 'Open',
          predicate: (row) => row.status == 'Open',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Incident ID',
          width: 120,
          cell: (row) => row.id,
          sortValue: (row) => row.id,
        ),
        EnterpriseTableColumn(
          label: 'Opened At',
          width: 180,
          cell: (row) => row.openedAt,
          sortValue: (row) => row.openedAt,
        ),
        EnterpriseTableColumn(
          label: 'Summary',
          width: 290,
          cell: (row) => row.summary,
          sortValue: (row) => row.summary,
        ),
        EnterpriseTableColumn(
          label: 'Status',
          width: 100,
          cell: (row) => row.status,
          sortValue: (row) => row.status,
        ),
        EnterpriseTableColumn(
          label: 'Owner',
          width: 100,
          cell: (row) => row.owner,
          sortValue: (row) => row.owner,
        ),
      ],
    );
  }
}

class _ModelHealthTab extends StatelessWidget {
  const _ModelHealthTab();

  @override
  Widget build(BuildContext context) {
    return EnterpriseDataTable<_ModelHealthRow>(
      title: 'AI Model Health',
      subtitle: 'Inference quality, drift, and pipeline reliability telemetry.',
      rows: const [
        _ModelHealthRow('prediction-core-v4', '0.89', '0.04', 'Healthy'),
        _ModelHealthRow('sentiment-aggregator-v2', '0.82', '0.07', 'Watch'),
        _ModelHealthRow('risk-scoring-v3', '0.91', '0.03', 'Healthy'),
      ],
      rowId: (row) => row.model,
      searchHint: 'Search model id',
      filters: [
        EnterpriseTableFilter(
          label: 'Watch',
          predicate: (row) => row.status == 'Watch',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Model',
          width: 230,
          cell: (row) => row.model,
          sortValue: (row) => row.model,
        ),
        EnterpriseTableColumn(
          label: 'Accuracy',
          width: 100,
          numeric: true,
          cell: (row) => row.accuracy,
          sortValue: (row) => row.accuracy,
        ),
        EnterpriseTableColumn(
          label: 'Drift',
          width: 100,
          numeric: true,
          cell: (row) => row.drift,
          sortValue: (row) => row.drift,
        ),
        EnterpriseTableColumn(
          label: 'Status',
          width: 100,
          cell: (row) => row.status,
          sortValue: (row) => row.status,
        ),
      ],
    );
  }
}

class _TradeAuditTab extends StatelessWidget {
  const _TradeAuditTab();

  @override
  Widget build(BuildContext context) {
    return EnterpriseDataTable<_TradeAuditRow>(
      title: 'Forecast Audit Trail',
      subtitle: 'Position execution and settlement chain-of-custody records.',
      rows: const [
        _TradeAuditRow('FC-7129', 'BTC > 120k', 'Settled', '0x91ac...44f2'),
        _TradeAuditRow('FC-7126', 'ETH ETF volume', 'Settled', '0x84ba...91cc'),
        _TradeAuditRow('FC-7111', 'SOL APR', 'Pending', '0x12fa...21ac'),
      ],
      rowId: (row) => row.id,
      searchHint: 'Search forecast id or market',
      filters: [
        EnterpriseTableFilter(
          label: 'Pending',
          predicate: (row) => row.status == 'Pending',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Forecast ID',
          width: 100,
          cell: (row) => row.id,
          sortValue: (row) => row.id,
        ),
        EnterpriseTableColumn(
          label: 'Market',
          width: 280,
          cell: (row) => row.market,
          sortValue: (row) => row.market,
        ),
        EnterpriseTableColumn(
          label: 'Status',
          width: 100,
          cell: (row) => row.status,
          sortValue: (row) => row.status,
        ),
        EnterpriseTableColumn(
          label: 'Tx Hash',
          width: 180,
          cell: (row) => row.hash,
          sortValue: (row) => row.hash,
        ),
      ],
    );
  }
}

class _DisputeQueueTab extends StatelessWidget {
  const _DisputeQueueTab();

  @override
  Widget build(BuildContext context) {
    return EnterpriseDataTable<_DisputeRow>(
      title: 'Dispute Queue',
      subtitle: 'Open dispute investigations and evidence completeness.',
      rows: const [
        _DisputeRow('DSP-330', 'BTC > 120k', 'Evidence Review', 'High'),
        _DisputeRow('DSP-321', 'HashKey TVL', 'Juror Voting', 'Medium'),
        _DisputeRow('DSP-317', 'ETH ETF volume', 'Resolved', 'Low'),
      ],
      rowId: (row) => row.id,
      searchHint: 'Search dispute id or market',
      filters: [
        EnterpriseTableFilter(
          label: 'High Priority',
          predicate: (row) => row.priority == 'High',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Dispute ID',
          width: 120,
          cell: (row) => row.id,
          sortValue: (row) => row.id,
        ),
        EnterpriseTableColumn(
          label: 'Market',
          width: 260,
          cell: (row) => row.market,
          sortValue: (row) => row.market,
        ),
        EnterpriseTableColumn(
          label: 'Stage',
          width: 140,
          cell: (row) => row.stage,
          sortValue: (row) => row.stage,
        ),
        EnterpriseTableColumn(
          label: 'Priority',
          width: 100,
          cell: (row) => row.priority,
          sortValue: (row) => row.priority,
        ),
      ],
    );
  }
}

class _WalletActivityTab extends StatelessWidget {
  const _WalletActivityTab();

  @override
  Widget build(BuildContext context) {
    return EnterpriseDataTable<_WalletActivityRow>(
      title: 'Wallet Activity',
      subtitle: 'Address-level settlement telemetry and risk posture flags.',
      rows: const [
        _WalletActivityRow('0x1f...a11d', 'Deposit', '\$200,000', 'Normal'),
        _WalletActivityRow('0x8a...02bc', 'Withdrawal', '\$48,000', 'Review'),
        _WalletActivityRow(
            '0xc1...ef54', 'Forecast Settlement', '\$120,000', 'Normal'),
      ],
      rowId: (row) => row.address,
      searchHint: 'Search wallet address',
      filters: [
        EnterpriseTableFilter(
          label: 'Review Required',
          predicate: (row) => row.flag == 'Review',
        ),
      ],
      columns: [
        EnterpriseTableColumn(
          label: 'Address',
          width: 200,
          cell: (row) => row.address,
          sortValue: (row) => row.address,
        ),
        EnterpriseTableColumn(
          label: 'Action',
          width: 140,
          cell: (row) => row.action,
          sortValue: (row) => row.action,
        ),
        EnterpriseTableColumn(
          label: 'Amount',
          width: 120,
          numeric: true,
          cell: (row) => row.amount,
          sortValue: (row) => row.amount,
        ),
        EnterpriseTableColumn(
          label: 'Flag',
          width: 100,
          cell: (row) => row.flag,
          sortValue: (row) => row.flag,
        ),
      ],
    );
  }
}

class _TreasuryTab extends StatelessWidget {
  const _TreasuryTab();

  @override
  Widget build(BuildContext context) {
    return EnterpriseDataTable<_TreasuryRow>(
      title: 'Protocol Treasury',
      subtitle: 'Treasury allocations, liabilities, and liquidity runway.',
      rows: const [
        _TreasuryRow('USDC Reserves', '\$4,200,000', 'Core Liquidity'),
        _TreasuryRow('Insurance Buffer', '\$1,150,000', 'Risk Offset'),
        _TreasuryRow(
            'Event Liquidity Inventory', '\$2,480,000', 'Forecast Support'),
        _TreasuryRow('Protocol Fees (30D)', '\$380,000', 'Revenue'),
      ],
      rowId: (row) => row.bucket,
      searchHint: 'Search treasury bucket',
      columns: [
        EnterpriseTableColumn(
          label: 'Bucket',
          width: 250,
          cell: (row) => row.bucket,
          sortValue: (row) => row.bucket,
        ),
        EnterpriseTableColumn(
          label: 'Value',
          width: 160,
          numeric: true,
          cell: (row) => row.value,
          sortValue: (row) => row.value,
        ),
        EnterpriseTableColumn(
          label: 'Purpose',
          width: 220,
          cell: (row) => row.purpose,
          sortValue: (row) => row.purpose,
        ),
      ],
    );
  }
}

class _SystemStatusRow {
  const _SystemStatusRow(this.service, this.uptime, this.latency, this.status);

  final String service;
  final String uptime;
  final String latency;
  final String status;
}

class _IncidentRow {
  const _IncidentRow(
      this.id, this.openedAt, this.summary, this.status, this.owner);

  final String id;
  final String openedAt;
  final String summary;
  final String status;
  final String owner;
}

class _ModelHealthRow {
  const _ModelHealthRow(this.model, this.accuracy, this.drift, this.status);

  final String model;
  final String accuracy;
  final String drift;
  final String status;
}

class _TradeAuditRow {
  const _TradeAuditRow(this.id, this.market, this.status, this.hash);

  final String id;
  final String market;
  final String status;
  final String hash;
}

class _DisputeRow {
  const _DisputeRow(this.id, this.market, this.stage, this.priority);

  final String id;
  final String market;
  final String stage;
  final String priority;
}

class _WalletActivityRow {
  const _WalletActivityRow(this.address, this.action, this.amount, this.flag);

  final String address;
  final String action;
  final String amount;
  final String flag;
}

class _TreasuryRow {
  const _TreasuryRow(this.bucket, this.value, this.purpose);

  final String bucket;
  final String value;
  final String purpose;
}
