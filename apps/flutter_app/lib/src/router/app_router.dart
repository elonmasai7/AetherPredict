import 'package:go_router/go_router.dart';

import '../features/agents/agents_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/live_games/live_games_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/markets/market_list_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/strategy_engine/strategy_ai_builder_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/overview', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/live-games', builder: (_, __) => const LiveGamesScreen()),
    GoRoute(path: '/markets', builder: (_, __) => const MarketListScreen()),
    GoRoute(
        path: '/my-predictions', builder: (_, __) => const PortfolioScreen()),
    GoRoute(path: '/ai-agents', builder: (_, __) => const AgentsScreen()),
    GoRoute(path: '/news', builder: (_, __) => const NotificationsScreen()),
    GoRoute(
        path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
    GoRoute(
        path: '/strategy-lab',
        builder: (_, __) => const StrategyAiBuilderScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(
      path: '/dashboard',
      redirect: (_, __) => '/overview',
    ),
    GoRoute(
      path: '/forecast-overview',
      redirect: (_, __) => '/overview',
    ),
    GoRoute(
      path: '/live-prediction-markets',
      redirect: (_, __) => '/markets',
    ),
    GoRoute(
      path: '/ai-forecast-engine',
      redirect: (_, __) => '/markets',
    ),
    GoRoute(
      path: '/create-prediction',
      redirect: (_, __) => '/markets',
    ),
    GoRoute(
      path: '/my-positions',
      redirect: (_, __) => '/my-predictions',
    ),
    GoRoute(
      path: '/autonomous-agents',
      redirect: (_, __) => '/ai-agents',
    ),
    GoRoute(
      path: '/alerts',
      redirect: (_, __) => '/news',
    ),
    GoRoute(
      path: '/strategy-engine/ai-builder',
      redirect: (_, __) => '/strategy-lab',
    ),
  ],
);
