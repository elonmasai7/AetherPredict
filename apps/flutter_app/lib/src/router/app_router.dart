import 'package:go_router/go_router.dart';

import '../features/agents/agents_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/copy_trading/copy_trading_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/disputes/dispute_center_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
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
import '../features/status/status_center_screen.dart';
import '../features/vaults/vault_marketplace_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(
      path: '/forecast-overview',
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/live-prediction-markets',
      builder: (_, __) => const MarketListScreen(),
    ),
    GoRoute(
      path: '/ai-forecast-engine',
      builder: (_, __) => const MarketDetailScreen(),
    ),
    GoRoute(
      path: '/create-prediction',
      builder: (_, __) => const TradeScreen(),
    ),
    GoRoute(
      path: '/my-positions',
      builder: (_, __) => const PortfolioScreen(),
    ),
    GoRoute(
      path: '/autonomous-agents',
      builder: (_, __) => const AgentsScreen(),
    ),
    GoRoute(
      path: '/liquidity-vaults',
      builder: (_, __) => const VaultMarketplaceScreen(),
    ),
    GoRoute(
      path: '/copy-forecasts',
      builder: (_, __) => const CopyTradingScreen(),
    ),
    GoRoute(
      path: '/risk-intelligence',
      builder: (_, __) => const RiskDashboardScreen(),
    ),
    GoRoute(
      path: '/market-resolution',
      builder: (_, __) => const MarketResolutionCenterScreen(),
    ),
    GoRoute(path: '/disputes', builder: (_, __) => const DisputeCenterScreen()),
    GoRoute(
      path: '/research-thesis',
      builder: (_, __) => const ResearchWorkspaceScreen(),
    ),
    GoRoute(
        path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
    GoRoute(path: '/alerts', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    GoRoute(
      path: '/operations',
      builder: (_, __) => const OperationsConsoleScreen(),
    ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(
      path: '/dashboard',
      redirect: (_, __) => '/forecast-overview',
    ),
    GoRoute(
      path: '/overview',
      redirect: (_, __) => '/forecast-overview',
    ),
    GoRoute(
      path: '/markets',
      redirect: (_, __) => '/live-prediction-markets',
    ),
    GoRoute(
      path: '/markets/detail',
      redirect: (_, __) => '/ai-forecast-engine',
    ),
    GoRoute(
      path: '/trade',
      redirect: (_, __) => '/create-prediction',
    ),
    GoRoute(
      path: '/trading',
      redirect: (_, __) => '/create-prediction',
    ),
    GoRoute(
      path: '/portfolio',
      redirect: (_, __) => '/my-positions',
    ),
    GoRoute(
      path: '/risk',
      redirect: (_, __) => '/risk-intelligence',
    ),
    GoRoute(
      path: '/research',
      redirect: (_, __) => '/research-thesis',
    ),
    GoRoute(
      path: '/vaults',
      redirect: (_, __) => '/liquidity-vaults',
    ),
    GoRoute(
      path: '/copy-trading',
      redirect: (_, __) => '/copy-forecasts',
    ),
    GoRoute(
      path: '/notifications',
      redirect: (_, __) => '/alerts',
    ),
    GoRoute(
      path: '/status',
      redirect: (_, __) => '/market-resolution',
    ),
  ],
);
