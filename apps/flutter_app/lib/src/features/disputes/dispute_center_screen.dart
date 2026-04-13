import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class DisputeCenterScreen extends ConsumerStatefulWidget {
  const DisputeCenterScreen({super.key});

  @override
  ConsumerState<DisputeCenterScreen> createState() =>
      _DisputeCenterScreenState();
}

class _DisputeCenterScreenState extends ConsumerState<DisputeCenterScreen> {
  String? status;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletSessionProvider);
    final disputes = ref.watch(disputeHistoryProvider);
    return AppScaffold(
      title: 'Disputes',
      subtitle:
          'Submit evidence-backed outcome challenges during juror dispute windows and track on-chain status.',
      child: ListView(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Submit Outcome Dispute',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text(
                  'Disputes are executed on-chain during the resolution window and require a wallet signature.',
                  style: TextStyle(color: AetherColors.muted),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: wallet.connected
                      ? () => _openDisputeDialog(context)
                      : null,
                  child: const Text('Open Dispute Case'),
                ),
                if (!wallet.connected)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Connect a wallet to dispute a market.',
                        style: TextStyle(color: AetherColors.muted)),
                  ),
                if (status != null) ...[
                  const SizedBox(height: 12),
                  Text(status!,
                      style: const TextStyle(color: AetherColors.muted)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dispute History',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                disputes.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No disputes recorded yet.',
                            style: TextStyle(color: AetherColors.muted)),
                      );
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Market')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Evidence')),
                          DataColumn(label: Text('Tx')),
                          DataColumn(label: Text('Chain')),
                          DataColumn(label: Text('Created')),
                        ],
                        rows: [
                          for (final item in items)
                            DataRow(cells: [
                              DataCell(Text('#${item.marketId}')),
                              DataCell(Text(item.status)),
                              DataCell(_evidenceCell(item.evidenceUrl)),
                              DataCell(_txCell(item.txHash)),
                              DataCell(Text(item.chainStatus ?? 'pending')),
                              DataCell(Text(item.createdAt)),
                            ]),
                        ],
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(error.toString()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDisputeDialog(BuildContext context) async {
    final marketId = TextEditingController();
    final evidence = TextEditingController();
    final stake = TextEditingController(text: '0.01');
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Open Dispute'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: marketId,
                      decoration:
                          const InputDecoration(labelText: 'Market ID')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: evidence,
                      decoration:
                          const InputDecoration(labelText: 'Evidence URI')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: stake,
                      decoration:
                          const InputDecoration(labelText: 'Stake (ETH)')),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  try {
                    final wallet = ref.read(walletSessionProvider);
                    final api = ref.read(apiClientProvider);
                    final walletService = ref.read(walletServiceProvider);
                    if (!wallet.connected || wallet.address == null) {
                      throw StateError('Connect wallet first.');
                    }
                    final chainId = await walletService.currentChainId();
                    if (chainId != 133) {
                      await walletService.switchChain(133);
                    }
                    final marketIdValue = int.parse(marketId.text);
                    final market = await api.fetchMarketById(marketIdValue);
                    if (market.onChainAddress == null ||
                        market.onChainAddress!.isEmpty) {
                      throw StateError(
                          'Market is not linked to an on-chain address.');
                    }
                    final tx = await api.buildDisputeTx({
                      'market_address': market.onChainAddress,
                      'wallet_address': wallet.address,
                      'amount_wei':
                          ((double.tryParse(stake.text) ?? 0) * 1e18).round(),
                      'evidence_uri': evidence.text,
                    });
                    final chainTxId = await api.createDisputeChainTx(
                        marketIdValue, wallet.address!, evidence.text);
                    final txHash = await walletService.sendTransaction({
                      'from': wallet.address,
                      'to': tx['to'],
                      'data': tx['data'],
                      'value': tx['value'],
                      if (tx['gas'] != null) 'gas': tx['gas'],
                      if (tx['gasPrice'] != null) 'gasPrice': tx['gasPrice'],
                      if (tx['nonce'] != null) 'nonce': tx['nonce'],
                      'chainId': tx['chainId'],
                    });
                    await api.submitChainTx(chainTxId, txHash, wallet.address!);
                    setState(() => status = 'Dispute submitted: $txHash');
                    if (mounted) Navigator.pop(dialogContext);
                  } catch (error) {
                    setState(() => status = error.toString());
                  }
                },
                child: const Text('Submit Dispute'),
              ),
            ],
          );
        },
      );
    } finally {
      marketId.dispose();
      evidence.dispose();
      stake.dispose();
    }
  }

  Widget _txCell(String? txHash) {
    if (txHash == null || txHash.isEmpty) {
      return const Text('Pending');
    }
    return TextButton(
      onPressed: () => _openExplorer('/tx/$txHash'),
      child: Text('${txHash.substring(0, 10)}...'),
    );
  }

  Widget _evidenceCell(String evidenceUrl) {
    if (evidenceUrl.isEmpty) {
      return const Text('None');
    }
    if (evidenceUrl.startsWith('http')) {
      return TextButton(
        onPressed: () => _openEvidence(evidenceUrl),
        child: const Text('View'),
      );
    }
    return SelectableText(evidenceUrl);
  }

  Future<void> _openExplorer(String path) async {
    final uri = Uri.parse('${AppConfig.explorerBaseUrl}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEvidence(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
