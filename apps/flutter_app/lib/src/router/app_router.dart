import 'package:go_router/go_router.dart';

import '../features/agents/agents_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/disputes/dispute_center_screen.dart';
import '../features/markets/market_detail_screen.dart';
import '../features/markets/market_list_screen.dart';
import '../features/markets/trade_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/markets', builder: (_, __) => const MarketListScreen()),
    GoRoute(path: '/markets/detail', builder: (_, __) => const MarketDetailScreen()),
    GoRoute(path: '/trade', builder: (_, __) => const TradeScreen()),
    GoRoute(path: '/portfolio', builder: (_, __) => const PortfolioScreen()),
    GoRoute(path: '/agents', builder: (_, __) => const AgentsScreen()),
    GoRoute(path: '/disputes', builder: (_, __) => const DisputeCenterScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
