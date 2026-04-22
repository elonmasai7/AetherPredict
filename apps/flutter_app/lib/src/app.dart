import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'core/providers.dart';
import 'router/app_router.dart';

class AetherPredictApp extends ConsumerStatefulWidget {
  const AetherPredictApp({super.key});

  @override
  ConsumerState<AetherPredictApp> createState() => _AetherPredictAppState();
}

class _AetherPredictAppState extends ConsumerState<AetherPredictApp> {
  @override
  void initState() {
    super.initState();
    // One-time session restoration. Doing this in widget build paths causes
    // repeated refresh churn and unstable navigation on web.
    Future.microtask(() async {
      await ref.read(authSessionProvider.notifier).restore();
      await ref.read(walletSessionProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AetherPredict',
      debugShowCheckedModeBanner: false,
      theme: buildAetherTheme(),
      routerConfig: appRouter,
    );
  }
}
