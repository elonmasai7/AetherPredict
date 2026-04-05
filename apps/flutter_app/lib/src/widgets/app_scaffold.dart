import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../core/wallet_service.dart';
import 'live_ticker_bar.dart';

class _NavItem {
  const _NavItem(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}

const _desktopItems = [
  _NavItem('Dashboard', '/dashboard', Icons.dashboard_outlined),
  _NavItem('Markets', '/markets', Icons.candlestick_chart),
  _NavItem('Portfolio', '/portfolio', Icons.account_balance_wallet_outlined),
  _NavItem('AI Signals', '/copilot', Icons.auto_awesome_outlined),
  _NavItem('Research Workspace', '/research', Icons.edit_note_outlined),
  _NavItem('Leaderboard', '/leaderboard', Icons.emoji_events_outlined),
  _NavItem('Notifications', '/notifications', Icons.notifications_none),
  _NavItem('Reports', '/reports', Icons.assessment_outlined),
  _NavItem('Operations Console', '/operations',
      Icons.precision_manufacturing_outlined),
  _NavItem('Status Center', '/status', Icons.health_and_safety_outlined),
  _NavItem('Settings', '/settings', Icons.settings_outlined),
];

const _mobileItems = [
  _NavItem('Home', '/dashboard', Icons.home_outlined),
  _NavItem('Markets', '/markets', Icons.candlestick_chart),
  _NavItem('Portfolio', '/portfolio', Icons.account_balance_wallet_outlined),
  _NavItem('Signals', '/copilot', Icons.auto_awesome_outlined),
  _NavItem('Alerts', '/notifications', Icons.notifications_none),
];

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.of(context).size.width < 1100;
    final path = GoRouterState.of(context).uri.path;
    final wallet = ref.watch(walletSessionProvider);
    final portfolio = ref.watch(portfolioProvider);

    final portfolioSummary = portfolio.maybeWhen(
      data: (positions) =>
          '\$${positions.fold<double>(0, (sum, p) => sum + p.pnl).toStringAsFixed(0)} PnL',
      orElse: () => 'Loading portfolio',
    );

    final walletLabel = wallet.connected
        ? '${wallet.address ?? 'Connected'} • \$${wallet.balanceUsd.toStringAsFixed(0)}'
        : 'Wallet offline';

    return Scaffold(
      backgroundColor: AetherColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F131A), Color(0xFF111722)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!compact) _Sidebar(path: path),
              Expanded(
                child: Column(
                  children: [
                    const LiveTickerBar(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(
                              title: title,
                              compact: compact,
                              portfolioSummary:
                                  '${portfolioSummary} • ${wallet.activePositions} active',
                              walletLabel: walletLabel,
                              walletType: wallet.type,
                              connected: wallet.connected,
                              onConnect: (type) => ref
                                  .read(walletSessionProvider.notifier)
                                  .connect(type),
                              onDisconnect: () => ref
                                  .read(walletSessionProvider.notifier)
                                  .disconnect(),
                            ),
                            const SizedBox(height: 20),
                            Expanded(child: child),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: compact ? _MobileNav(path: path) : null,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: AetherColors.bgElevated,
        border: Border(right: BorderSide(color: AetherColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('AetherPredict',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text('Institutional Intelligence',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _desktopItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, index) {
                  final item = _desktopItems[index];
                  final selected =
                      path == item.path || path.startsWith('${item.path}/');
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.go(item.path),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected
                            ? AetherColors.bgPanel
                            : Colors.transparent,
                        border: Border.all(
                            color: selected
                                ? AetherColors.accentSoft
                                : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon,
                              size: 18,
                              color: selected
                                  ? AetherColors.text
                                  : AetherColors.muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: selected
                                    ? AetherColors.text
                                    : AetherColors.muted,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
    required this.title,
    required this.compact,
    required this.portfolioSummary,
    required this.walletLabel,
    required this.walletType,
    required this.connected,
    required this.onConnect,
    required this.onDisconnect,
  });

  final String title;
  final bool compact;
  final String portfolioSummary;
  final String walletLabel;
  final WalletType? walletType;
  final bool connected;
  final ValueChanged<WalletType> onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontSize: compact ? 24 : 30)),
              const SizedBox(height: 4),
              Text('Live system telemetry and AI-driven decision intelligence',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        _HeaderChip(
            icon: Icons.health_and_safety_outlined,
            label: 'System Healthy',
            accent: AetherColors.success),
        const SizedBox(width: 8),
        _HeaderChip(icon: Icons.pie_chart_outline, label: portfolioSummary),
        const SizedBox(width: 8),
        _HeaderChip(icon: Icons.wallet_outlined, label: walletLabel),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Wallet Switcher',
          onSelected: (value) {
            if (value == 'disconnect') {
              onDisconnect();
              return;
            }
            switch (value) {
              case 'phantom':
                onConnect(WalletType.phantom);
                return;
              case 'walletconnect':
                onConnect(WalletType.walletConnect);
                return;
              case 'metamask':
                onConnect(WalletType.metaMask);
                return;
              case 'coinbase':
                onConnect(WalletType.coinbase);
                return;
              default:
                return;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                connected
                    ? 'Connected: ${walletType?.name ?? 'wallet'}'
                    : 'Connect Wallet',
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'phantom', child: Text('Phantom')),
            const PopupMenuItem(
                value: 'walletconnect', child: Text('WalletConnect')),
            const PopupMenuItem(value: 'metamask', child: Text('MetaMask')),
            const PopupMenuItem(
                value: 'coinbase', child: Text('Coinbase Wallet')),
            if (connected) const PopupMenuDivider(),
            if (connected)
              const PopupMenuItem(
                  value: 'disconnect', child: Text('Disconnect')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AetherColors.bgPanel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AetherColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 16, color: AetherColors.muted),
                SizedBox(width: 8),
                Text('Wallet',
                    style: TextStyle(color: AetherColors.text, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_none),
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'Profile Menu',
          onSelected: (value) {
            if (value == 'settings') {
              context.go('/settings');
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'settings', child: Text('Settings')),
            PopupMenuItem(value: 'logout', child: Text('Sign out (demo)')),
          ],
          child: const CircleAvatar(
              radius: 16, child: Icon(Icons.person, size: 18)),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AetherColors.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AetherColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent ?? AetherColors.muted),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AetherColors.text)),
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
    final selectedIndex = _mobileItems.indexWhere(
        (item) => path == item.path || path.startsWith('${item.path}/'));
    return NavigationBar(
      height: 72,
      backgroundColor: AetherColors.bgElevated,
      indicatorColor: AetherColors.bgPanel,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) => context.go(_mobileItems[index].path),
      destinations: [
        for (final item in _mobileItems)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}
