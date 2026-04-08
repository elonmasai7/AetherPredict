import 'package:go_router/go_router.dart';

import '../features/agents/agents_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/bundles/bundle_marketplace_screen.dart';
import '../features/copilot/copilot_screen.dart';
import '../features/copy_trading/copy_trading_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/discussion/discussion_screen.dart';
import '../features/disputes/dispute_center_screen.dart';
import '../features/insurance/insurance_center_screen.dart';
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
import '../features/vaults/vault_detail_screen.dart';
import '../features/vaults/vault_marketplace_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/markets', builder: (_, __) => const MarketListScreen()),
    GoRoute(
        path: '/markets/detail',
        builder: (_, __) => const MarketDetailScreen()),
    GoRoute(path: '/trade', builder: (_, __) => const TradeScreen()),
    GoRoute(path: '/portfolio', builder: (_, __) => const PortfolioScreen()),
    GoRoute(path: '/risk', builder: (_, __) => const RiskDashboardScreen()),
    GoRoute(path: '/copilot', builder: (_, __) => const CopilotScreen()),
    GoRoute(path: '/agents', builder: (_, __) => const AgentsScreen()),
    GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen()),
    GoRoute(
        path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
    GoRoute(
        path: '/research', builder: (_, __) => const ResearchWorkspaceScreen()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    GoRoute(
        path: '/operations',
        builder: (_, __) => const OperationsConsoleScreen()),
    GoRoute(path: '/status', builder: (_, __) => const StatusCenterScreen()),
    GoRoute(
        path: '/bundles', builder: (_, __) => const BundleMarketplaceScreen()),
    GoRoute(
        path: '/vaults', builder: (_, __) => const VaultMarketplaceScreen()),
    GoRoute(
        path: '/vaults/detail', builder: (_, __) => const VaultDetailScreen()),
    GoRoute(
        path: '/copy-trading', builder: (_, __) => const CopyTradingScreen()),
    GoRoute(
        path: '/insurance', builder: (_, __) => const InsuranceCenterScreen()),
    GoRoute(path: '/discussion', builder: (_, __) => const DiscussionScreen()),
    GoRoute(path: '/disputes', builder: (_, __) => const DisputeCenterScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
