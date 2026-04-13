import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreAndRoute();
  }

  Future<void> _restoreAndRoute() async {
    await ref.read(authSessionProvider.notifier).restore();
    final authenticated = ref.read(authSessionProvider).isAuthenticated;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.go(authenticated ? '/forecast-overview' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AetherColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: EnterprisePanel(
              title: 'AetherPredict',
              subtitle:
                  'Initializing institutional prediction intelligence workspace...',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: AetherSpacing.sm),
                  LinearProgressIndicator(minHeight: 8),
                  SizedBox(height: AetherSpacing.md),
                  Text(
                    'Loading live prediction markets, AI forecast engines, and on-chain resolution telemetry.',
                    style: TextStyle(color: AetherColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
