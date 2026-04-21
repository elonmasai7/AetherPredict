import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../core/wallet_service.dart';
import 'enterprise/enterprise_components.dart';
import 'live_signal_bar.dart';

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
  _NavItem('News', '/news', Icons.newspaper_rounded),
  _NavItem('Leaderboard', '/leaderboard', Icons.leaderboard_rounded),
  _NavItem('Strategy Lab', '/strategy-lab', Icons.hub_outlined),
  _NavItem('Settings', '/settings', Icons.settings_outlined),
];

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final compact = MediaQuery.of(context).size.width < 1160;
    final wallet = ref.watch(walletSessionProvider);
    final auth = ref.watch(authSessionProvider);
    final portfolio = ref.watch(portfolioProvider);

    ref.read(authSessionProvider.notifier).restore();
    ref.read(walletSessionProvider.notifier).restore();

    ref.listen(txUpdatesProvider, (previous, next) {
      next.whenData((update) {
        if (!context.mounted) return;
        final message = update.status.toLowerCase() == 'confirmed'
            ? 'Forecast position ${update.tradeId ?? ''} settled on-chain.'
            : 'Forecast update: ${update.status}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message), duration: const Duration(seconds: 3)),
        );
      });
    });

    final portfolioSummary = portfolio.maybeWhen(
      data: (positions) {
        final pnl = positions.fold<double>(0, (sum, item) => sum + item.pnl);
        return '${positions.length} open forecasts • ${formatUsd(pnl, fractionDigits: 0)} forecast PnL';
      },
      orElse: () => 'Positions syncing',
    );

    if (!auth.isAuthenticated &&
        path != '/login' &&
        path != '/signup' &&
        path != '/') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/login');
        }
      });
    }

    return Scaffold(
      backgroundColor: AetherColors.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact) _Sidebar(path: path),
            Expanded(
              child: Column(
                children: [
                  const LiveSignalBar(),
                  _TopBar(
                    title: title,
                    subtitle: subtitle,
                    compact: compact,
                    portfolioSummary: portfolioSummary,
                    walletLabel: _walletSummary(wallet),
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
                    walletType: wallet.type,
                    walletConnected: wallet.connected,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: compact ? AetherSpacing.md : AetherSpacing.xl,
                        right: compact ? AetherSpacing.md : AetherSpacing.xl,
                        bottom: AetherSpacing.lg,
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
      return '${wallet.type?.name.toUpperCase() ?? 'WALLET'} $address';
    }
    return '${wallet.type?.name.toUpperCase() ?? 'WALLET'} ${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      decoration: const BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border(right: BorderSide(color: AetherColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AetherRadii.sm),
                    color: AetherColors.bgPanel,
                    border: Border.all(color: AetherColors.border),
                  ),
                  child: const Icon(Icons.auto_graph_rounded, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'AetherPredict',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'NBA prediction intelligence platform',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: _navItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, index) {
                  final item = _navItems[index];
                  final selected =
                      path == item.path || path.startsWith('${item.path}/');
                  return _SidebarTile(item: item, selected: selected);
                },
              ),
            ),
            const Divider(height: 18),
            Row(
              children: [
                const Icon(Icons.sensors,
                    size: 14, color: AetherColors.success),
                const SizedBox(width: 8),
                Text(
                  'NBA Signal Network Online',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AetherColors.success),
                ),
              ],
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(AetherRadii.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AetherRadii.md),
          color: selected ? AetherColors.bgPanel : Colors.transparent,
          border: Border.all(
            color: selected ? AetherColors.accentSoft : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: selected ? AetherColors.text : AetherColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? AetherColors.text : AetherColors.muted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.portfolioSummary,
    required this.walletLabel,
    required this.onConnectWallet,
    required this.onDisconnectWallet,
    required this.onSignOut,
    required this.walletType,
    required this.walletConnected,
  });

  final String title;
  final String? subtitle;
  final bool compact;
  final String portfolioSummary;
  final String walletLabel;
  final ValueChanged<WalletType> onConnectWallet;
  final VoidCallback onDisconnectWallet;
  final VoidCallback onSignOut;
  final WalletType? walletType;
  final bool walletConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 96 : 90,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AetherSpacing.md : AetherSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AetherColors.bg,
        border: Border(bottom: BorderSide(color: AetherColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (!compact) ...[
            StatusBadge(label: portfolioSummary),
            const SizedBox(width: 8),
            const StatusBadge(label: 'News + Game Feeds Healthy'),
            const SizedBox(width: 8),
            StatusBadge(
              label: walletLabel,
              color:
                  walletConnected ? AetherColors.success : AetherColors.warning,
            ),
            const SizedBox(width: 8),
          ],
          _walletMenu(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'NBA news',
            onPressed: () => context.go('/news'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Profile menu',
            onSelected: (value) {
              if (value == 'settings') {
                context.go('/settings');
                return;
              }
              if (value == 'logout') {
                onSignOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AetherColors.bgPanel,
              child: Icon(Icons.person_outline, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Wallet',
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
          value: 'walletconnect',
          child: Text('WalletConnect'),
        ),
        const PopupMenuItem(value: 'metamask', child: Text('MetaMask')),
        const PopupMenuItem(value: 'coinbase', child: Text('Coinbase Wallet')),
        if (walletConnected) const PopupMenuDivider(),
        if (walletConnected)
          const PopupMenuItem(value: 'disconnect', child: Text('Disconnect')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AetherColors.bgPanel,
          borderRadius: BorderRadius.circular(AetherRadii.md),
          border: Border.all(color: AetherColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 16),
            SizedBox(width: 6),
            Text('Wallet', style: TextStyle(fontSize: 12)),
          ],
        ),
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
