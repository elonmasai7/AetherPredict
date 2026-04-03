import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'router/app_router.dart';

class AetherPredictApp extends StatelessWidget {
  const AetherPredictApp({super.key});

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
