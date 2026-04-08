import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';

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
    context.go(authenticated ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'AetherPredict',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
