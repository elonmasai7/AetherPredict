import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class VaultMarketplaceScreen extends ConsumerWidget {
  const VaultMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(vaultProvider);
    final top = ref.watch(topVaultsProvider);
    final lowRisk = ref.watch(lowRiskVaultsProvider);
    final ai = ref.watch(aiVaultsProvider);
    final human = ref.watch(humanVaultsProvider);

    return AppScaffold(
      title: 'Vault Marketplace',
      child: ListView(
        children: [
          _section(context, 'Featured Vaults', featured),
          const SizedBox(height: 16),
          _section(context, 'Top Performing', top),
          const SizedBox(height: 16),
          _section(context, 'Low Risk', lowRisk),
          const SizedBox(height: 16),
          _section(context, 'AI Managed', ai),
          const SizedBox(height: 16),
          _section(context, 'Human Managed', human),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, AsyncValue<List<VaultModel>> source) {
    return source.when(
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardWidth = width > 1200 ? 360.0 : width > 900 ? 320.0 : width > 600 ? 280.0 : width;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final vault in items.take(6))
                    SizedBox(
                      width: cardWidth,
                      child: _VaultCard(vault: vault),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => GlassCard(child: Text(error.toString())),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({required this.vault});

  final VaultModel vault;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/vaults/detail?id=${vault.id}'),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(vault.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                _chip(vault.managerType == 'AI' ? 'AI' : vault.managerType),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              vault.strategyDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AetherColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric('ROI 30D', '${(vault.roi30d * 100).toStringAsFixed(1)}%'),
                const SizedBox(width: 12),
                _metric('Win Rate', '${(vault.winRate * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _metric('Volatility', '${(vault.volatility * 100).toStringAsFixed(1)}%'),
                const SizedBox(width: 12),
                _metric('AUM', '\$${vault.totalAum.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${vault.activeSubscribers} subscribers', style: const TextStyle(color: AetherColors.muted)),
                Text('Confidence ${(vault.aiConfidenceScore * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AetherColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AetherColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chip(String label) {
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
}
