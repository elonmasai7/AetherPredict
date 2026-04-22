import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../core/wallet_service.dart';
import 'enterprise/enterprise_components.dart';

class _NavItem {
  const _NavItem(this.label, this.path, this.icon, {this.mobile = false});

  final String label;
  final String path;
  final IconData icon;
  final bool mobile;
}

const _navItems = [
  _NavItem('Overview', '/overview', Icons.grid_view_rounded, mobile: true),
  _NavItem('Live Games', '/live-games', Icons.sports_basketball_rounded,
      mobile: true),
  _NavItem('Markets', '/markets', Icons.query_stats_rounded, mobile: true),
  _NavItem(
      'My Predictions', '/my-predictions', Icons.account_balance_wallet_rounded,
      mobile: true),
  _NavItem('AI Agents', '/ai-agents', Icons.psychology_alt_rounded),
  _NavItem('Strategy Lab', '/strategy-lab', Icons.hub_outlined),
  _NavItem('News', '/news', Icons.newspaper_rounded),
  _NavItem('Leaderboard', '/leaderboard', Icons.leaderboard_rounded),
];

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.headerBottom,
    this.sidebarFooter,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? headerBottom;
  final Widget? sidebarFooter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final compact = MediaQuery.of(context).size.width < 1160;
    final wallet = ref.watch(walletSessionProvider);
    final auth = ref.watch(authSessionProvider);
    final balances = ref.watch(walletBalancesProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    ref.listen(txUpdatesProvider, (previous, next) {
      next.whenData((update) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction update: ${update.status}')),
        );
      });
    });

    if (auth.restored &&
        !auth.isAuthenticated &&
        path != '/login' &&
        path != '/signup' &&
        path != '/') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/login');
        }
      });
    }

    final balanceLabel = balances.maybeWhen(
      data: (items) {
        final total = items.fold<double>(0, (sum, item) => sum + item.valueUsd);
        return formatUsd(total, fractionDigits: 0);
      },
      orElse: () => '\$0',
    );

    return Scaffold(
      backgroundColor: AetherColors.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact) _Sidebar(path: path, footer: sidebarFooter),
            Expanded(
              child: Column(
                children: [
                  _TopHeader(
                    compact: compact,
                    searchQuery: searchQuery,
                    walletLabel: _walletSummary(wallet),
                    balanceLabel: balanceLabel,
                    walletType: wallet.type,
                    walletConnected: wallet.connected,
                    onSearchChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).state = value,
                    onConnectWallet: (type) =>
                        ref.read(walletSessionProvider.notifier).connect(type),
                    onDisconnectWallet: () =>
                        ref.read(walletSessionProvider.notifier).disconnect(),
                    onSignOut: () async {
                      await ref.read(authSessionProvider.notifier).clear();
                      await ref
                          .read(walletSessionProvider.notifier)
                          .disconnect();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                  if (headerBottom != null) headerBottom!,
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? AetherSpacing.md : 12,
                        12,
                        compact ? AetherSpacing.md : 12,
                        12,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: compact ? _MobileNav(path: path) : null,
    );
  }

  String _walletSummary(WalletSessionState wallet) {
    if (!wallet.connected ||
        wallet.address == null ||
        wallet.address!.isEmpty) {
      return 'Wallet offline';
    }
    final address = wallet.address!;
    if (address.length <= 10) {
      return address;
    }
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.path, this.footer});

  final String path;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 228,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: const BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border(
          right: BorderSide(color: AetherColors.accentSoft, width: 1.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'NBA Platform',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 0.9, color: AetherColors.accent),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _navItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 3),
              itemBuilder: (_, index) {
                final item = _navItems[index];
                final selected =
                    path == item.path || path.startsWith('${item.path}/');
                return _SidebarTile(item: item, selected: selected);
              },
            ),
          ),
          if (footer != null) ...[
            footer!,
            const SizedBox(height: 6),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AetherColors.bgPanel,
              borderRadius: BorderRadius.circular(AetherRadii.sm),
              border: Border.all(color: AetherColors.accentSoft),
            ),
            child: const Row(
              children: [
                Icon(Icons.sensors_rounded,
                    size: 14, color: AetherColors.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Signal grid online',
                    style: TextStyle(fontSize: 11, color: AetherColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.path),
      borderRadius: BorderRadius.circular(AetherRadii.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AetherRadii.sm),
          color: selected ? AetherColors.bgPanel : AetherColors.bgElevated,
          border: Border.all(
            color: selected ? AetherColors.accent : AetherColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AetherColors.accent.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 16,
              color: selected ? AetherColors.text : AetherColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: selected ? AetherColors.text : AetherColors.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.compact,
    required this.searchQuery,
    required this.walletLabel,
    required this.balanceLabel,
    required this.walletType,
    required this.walletConnected,
    required this.onSearchChanged,
    required this.onConnectWallet,
    required this.onDisconnectWallet,
    required this.onSignOut,
  });

  final bool compact;
  final String searchQuery;
  final String walletLabel;
  final String balanceLabel;
  final WalletType? walletType;
  final bool walletConnected;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<WalletType> onConnectWallet;
  final VoidCallback onDisconnectWallet;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AetherSpacing.md : 12,
      ),
      decoration: const BoxDecoration(
        color: AetherColors.bg,
        border: Border(bottom: BorderSide(color: AetherColors.border)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AetherRadii.sm),
                  color: AetherColors.bgPanel,
                  border: Border.all(color: AetherColors.border),
                ),
                child: const Icon(Icons.sports_basketball_rounded, size: 14),
              ),
              if (!compact) ...[
                const SizedBox(width: 6),
                const Text(
                  'AetherPredict',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ],
          ),
          Expanded(
            child: Container(
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AetherColors.bgElevated,
                borderRadius: BorderRadius.circular(AetherRadii.md),
                border: Border.all(color: AetherColors.border),
              ),
              child: TextField(
                key: const ValueKey('global-search'),
                onChanged: onSearchChanged,
                controller: TextEditingController(text: searchQuery)
                  ..selection = TextSelection.collapsed(
                    offset: searchQuery.length,
                  ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, size: 16),
                  hintText: 'Search teams, players, markets',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          if (!compact)
            _HeaderBadge(
                label: balanceLabel, icon: Icons.account_balance_wallet),
          const SizedBox(width: 6),
          if (!compact)
            const _HeaderBadge(label: 'HashKey', icon: Icons.hub_rounded),
          const SizedBox(width: 6),
          _walletMenu(),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                onSignOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
            child: CircleAvatar(
              radius: 14,
              backgroundColor: walletConnected
                  ? AetherColors.accentSoft
                  : AetherColors.bgPanel,
              child: Text(
                walletConnected ? 'P' : '?',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'disconnect') {
          onDisconnectWallet();
          return;
        }
        switch (value) {
          case 'phantom':
            onConnectWallet(WalletType.phantom);
            return;
          case 'walletconnect':
            onConnectWallet(WalletType.walletConnect);
            return;
          case 'metamask':
            onConnectWallet(WalletType.metaMask);
            return;
          case 'coinbase':
            onConnectWallet(WalletType.coinbase);
            return;
          default:
            return;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            walletConnected
                ? 'Connected ${walletType?.name ?? ''}'
                : 'Connect wallet',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'phantom', child: Text('Phantom')),
        const PopupMenuItem(
            value: 'walletconnect', child: Text('WalletConnect')),
        const PopupMenuItem(value: 'metamask', child: Text('MetaMask')),
        const PopupMenuItem(value: 'coinbase', child: Text('Coinbase Wallet')),
        if (walletConnected) const PopupMenuDivider(),
        if (walletConnected)
          const PopupMenuItem(value: 'disconnect', child: Text('Disconnect')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AetherColors.bgPanel,
          borderRadius: BorderRadius.circular(AetherRadii.md),
          border: Border.all(color: AetherColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 14),
            const SizedBox(width: 5),
            Text(
              walletConnected ? walletLabel : 'Connect',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(AetherRadii.md),
        border: Border.all(color: AetherColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final items =
        _navItems.where((item) => item.mobile).toList(growable: false);
    final selectedIndex = items.indexWhere(
      (item) => path == item.path || path.startsWith('${item.path}/'),
    );
    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      destinations: [
        for (final item in items)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
      onDestinationSelected: (index) => context.go(items[index].path),
    );
  }
}
