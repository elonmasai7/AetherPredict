import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trade_screen.dart';

void main() {
  runApp(const ProviderScope(child: PredictOddsApp()));
}

class PredictOddsApp extends ConsumerStatefulWidget {
  const PredictOddsApp({super.key});

  @override
  ConsumerState<PredictOddsApp> createState() => _PredictOddsAppState();
}

class _PredictOddsAppState extends ConsumerState<PredictOddsApp> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return MaterialApp(
      title: 'PredictOdds Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155EEF)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            TradeScreen(),
            DashboardScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            const NavigationDestination(icon: Icon(Icons.candlestick_chart), label: 'Trade'),
            const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: auth.isLoggedIn,
                label: const Text(''),
                child: const Icon(Icons.settings_outlined),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
