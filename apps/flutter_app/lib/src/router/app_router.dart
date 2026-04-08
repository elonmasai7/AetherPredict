import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/copy_trading/copy_trading_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/markets/market_detail_screen.dart';
import '../features/markets/market_list_screen.dart';
import '../features/markets/trade_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/operations/operations_console_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/research/research_workspace_screen.dart';
import '../features/risk/risk_dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/vaults/vault_marketplace_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),

    GoRoute(path: '/overview', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/markets', builder: (_, __) => const MarketListScreen()),
    GoRoute(
      path: '/markets/detail',
      builder: (_, __) => const MarketDetailScreen(),
    ),
    GoRoute(path: '/trading', builder: (_, __) => const TradeScreen()),
    GoRoute(path: '/vaults', builder: (_, __) => const VaultMarketplaceScreen()),
    GoRoute(
      path: '/copy-trading',
      builder: (_, __) => const CopyTradingScreen(),
    ),
    GoRoute(path: '/portfolio', builder: (_, __) => const PortfolioScreen()),
    GoRoute(path: '/risk', builder: (_, __) => const RiskDashboardScreen()),
    GoRoute(
      path: '/research',
      builder: (_, __) => const ResearchWorkspaceScreen(),
    ),
    GoRoute(path: '/alerts', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    GoRoute(
      path: '/operations',
      builder: (_, __) => const OperationsConsoleScreen(),
    ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

    GoRoute(
      path: '/dashboard',
      redirect: (_, __) => '/overview',
    ),
    GoRoute(
      path: '/trade',
      redirect: (_, __) => '/trading',
    ),
    GoRoute(
      path: '/notifications',
      redirect: (_, __) => '/alerts',
    ),
    GoRoute(
      path: '/status',
      redirect: (_, __) => '/operations',
    ),
    GoRoute(
      path: '/disputes',
      redirect: (_, __) => '/operations',
    ),
  ],
);
