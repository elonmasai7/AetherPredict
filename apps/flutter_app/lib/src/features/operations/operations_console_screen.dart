import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class OperationsConsoleScreen extends ConsumerWidget {
  const OperationsConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictFlowHealth = ref.watch(predictFlowHealthProvider);
    final predictFlowMarkets = ref.watch(predictFlowMarketsProvider);
    final predictFlowDashboard = ref.watch(predictFlowDashboardProvider);

    final openPositions = predictFlowDashboard.maybeWhen(
      data: (dashboard) => dashboard.positions.length,
      orElse: () => 0,
    );
    final marketCount = predictFlowMarkets.maybeWhen(
      data: (markets) => markets.length,
      orElse: () => 0,
    );
    final incidents = predictFlowHealth.maybeWhen(
      data: (health) => health.status.toLowerCase() == 'ok' ? 0 : 1,
      orElse: () => 1,
    );

    return AppScaffold(
      title: 'Operations',
      subtitle:
          'Institutional operations center for forecast reliability, resolution governance, and protocol auditability.',
      child: DefaultTabController(
        length: 7,
        child: Column(
          children: [
            const _PredictFlowStatusPanel(),
            const SizedBox(height: AetherSpacing.md),
            EnterprisePanel(
              child: Row(
                children: [
                  Expanded(
                    child: StatusBadge(
                      label: predictFlowHealth.maybeWhen(
                        data: (health) => 'System Status: ${health.status == 'ok' ? 'Operational' : 'Watch'}',
                        orElse: () => 'System Status: Syncing',
                      ),
                      color: predictFlowHealth.maybeWhen(
                        data: (health) =>
                            health.status == 'ok' ? AetherColors.success : AetherColors.warning,
                        orElse: () => AetherColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: AetherSpacing.sm),
                  Expanded(
                    child: StatusBadge(
                      label: 'Open Incidents: $incidents',
                      color: incidents == 0
                          ? AetherColors.success
                          : AetherColors.warning,
                    ),
                  ),
                  const SizedBox(width: AetherSpacing.sm),
                  Expanded(
                    child: StatusBadge(
                      label:
                          'PredictFlow Markets: ${marketCount > 0 ? marketCount : '--'} · Positions: ${openPositions > 0 ? openPositions : '--'}',
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

class _PredictFlowStatusPanel extends ConsumerWidget {
  const _PredictFlowStatusPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthValue = ref.watch(predictFlowHealthProvider);
    final marketsValue = ref.watch(predictFlowMarketsProvider);
    final online = healthValue.maybeWhen(
      data: (health) => health.status == 'ok',
      orElse: () => false,
    );
    final message = healthValue.when(
      data: (health) =>
          '${health.service} online with ${health.markets} tracked markets from the Dart companion engine.',
      loading: () => 'Connecting to PredictFlow Dart engine...',
      error: (_, __) =>
          'PredictFlow Dart engine offline. Start it with: cd predictflow && dart run bin/server.dart',
    );
    final marketHint = marketsValue.maybeWhen(
      data: (markets) => markets.isEmpty
          ? 'No PredictFlow markets returned yet.'
          : 'Top local market: ${markets.first.title}',
      orElse: () => 'Waiting for PredictFlow market snapshots.',
    );
        return EnterprisePanel(
          title: 'PredictFlow Dart',
          subtitle:
              'Companion Dart prediction engine replacing the old TypeScript service layer.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: AetherColors.muted),
                    ),
                  ),
                  const SizedBox(width: AetherSpacing.sm),
                  StatusBadge(
                    label: online ? 'Online' : 'Offline',
                    color: online ? AetherColors.success : AetherColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: AetherSpacing.sm),
              Text(
                marketHint,
                style: const TextStyle(color: AetherColors.muted),
              ),
            ],
          ),
        );
  }
}

class _SystemStatusTab extends ConsumerWidget {
  const _SystemStatusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthValue = ref.watch(predictFlowHealthProvider);
    final marketsValue = ref.watch(predictFlowMarketsProvider);
    final rows = <_SystemStatusRow>[
      const _SystemStatusRow('API Gateway', '99.99%', '142 ms', 'Healthy'),
      const _SystemStatusRow('Oracle Mesh', '99.97%', '186 ms', 'Healthy'),
      const _SystemStatusRow('Resolution Engine', '99.92%', '302 ms', 'Watch'),
      const _SystemStatusRow('WebSocket Streams', '99.96%', '88 ms', 'Healthy'),
      const _SystemStatusRow('Risk Engine', '99.94%', '214 ms', 'Healthy'),
    ];
    healthValue.whenData((health) {
      rows.add(
        _SystemStatusRow(
          'PredictFlow Dart',
          '${health.markets} mkts',
          'Local HTTP',
          health.status == 'ok' ? 'Linked' : 'Watch',
        ),
      );
    });
    marketsValue.whenData((markets) {
      if (markets.isNotEmpty) {
        rows.add(
          _SystemStatusRow(
            'PredictFlow Local Book',
            '\$${markets.first.liquidityUsd.toStringAsFixed(0)}',
            '\$${markets.first.volume24h.toStringAsFixed(0)} 24h',
            markets.first.resolved ? 'Resolved' : 'Healthy',
          ),
        );
      }
    });
    return EnterpriseDataTable<_SystemStatusRow>(
      title: 'System Status Grid',
      subtitle: 'Live service uptime, latency, and current health state.',
      rows: rows,
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

class _WalletActivityTab extends ConsumerWidget {
  const _WalletActivityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardValue = ref.watch(predictFlowDashboardProvider);
    final rows = dashboardValue.maybeWhen(
      data: (dashboard) => dashboard.positions
          .map(
            (position) => _WalletActivityRow(
              dashboard.wallet,
              '${position.outcome} position',
              '${position.shares.toStringAsFixed(1)} sh',
              position.unrealizedPnl >= 0 ? 'Normal' : 'Review',
            ),
          )
          .toList(),
      orElse: () => const <_WalletActivityRow>[],
    );
    return EnterpriseDataTable<_WalletActivityRow>(
      title: 'Wallet Activity',
      subtitle:
          'PredictFlow wallet activity derived from the local Dart engine portfolio.',
      rows: rows,
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
