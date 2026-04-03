import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';

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
    final compact = MediaQuery.of(context).size.width < 900;
    final wallet = ref.watch(walletSessionProvider);
    final items = const [
      ('Dashboard', '/dashboard'),
      ('Markets', '/markets'),
      ('Portfolio', '/portfolio'),
      ('Risk', '/risk'),
      ('Copilot', '/copilot'),
      ('AI Agents', '/agents'),
      ('Alerts', '/notifications'),
      ('Leaders', '/leaderboard'),
      ('Bundles', '/bundles'),
      ('Insurance', '/insurance'),
      ('Discussion', '/discussion'),
      ('Disputes', '/disputes'),
      ('Settings', '/settings'),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF07111F), Color(0xFF0A2340), Color(0xFF07111F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!compact)
                Container(
                  width: 240,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AetherPredict', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextButton(
                            onPressed: () => context.go(item.$2),
                            child: Align(alignment: Alignment.centerLeft, child: Text(item.$1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (compact)
                            IconButton(
                              onPressed: () => _showMenu(context, items),
                              icon: const Icon(Icons.menu),
                            ),
                          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(wallet.connected ? (wallet.address ?? 'Wallet connected') : 'Wallet offline'),
                          ),
                        ],
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
      ),
      bottomNavigationBar: compact
          ? NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Dash'),
                NavigationDestination(icon: Icon(Icons.candlestick_chart), label: 'Markets'),
                NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
                NavigationDestination(icon: Icon(Icons.psychology_alt), label: 'Agents'),
              ],
              selectedIndex: 0,
              onDestinationSelected: (index) {
                final paths = ['/dashboard', '/markets', '/portfolio', '/agents'];
                context.go(paths[index]);
              },
            )
          : null,
    );
  }

  void _showMenu(BuildContext context, List<(String, String)> items) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ListView(
        children: items
            .map((item) => ListTile(
                  title: Text(item.$1),
                  onTap: () => context.go(item.$2),
                ))
            .toList(),
      ),
    );
  }
}
