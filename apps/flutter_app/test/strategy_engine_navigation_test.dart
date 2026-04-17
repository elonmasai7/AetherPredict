import 'package:aetherpredict_flutter/src/features/strategy_engine/strategy_engine_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() {
  Widget shell(String path, String title) {
    return Material(
      child: StrategyShell(
        title: title,
        subtitle: 'Test shell for $title',
        currentPath: path,
        child: Center(child: Text(title)),
      ),
    );
  }

  return GoRouter(
    initialLocation: '/strategy-engine',
    routes: [
      GoRoute(
        path: '/strategy-engine',
        builder: (_, __) => shell('/strategy-engine', 'My Strategies'),
      ),
      GoRoute(
        path: '/strategy-engine/templates',
        builder: (_, __) => shell('/strategy-engine/templates', 'Templates'),
      ),
      GoRoute(
        path: '/strategy-engine/ai-builder',
        builder: (_, __) => shell('/strategy-engine/ai-builder', 'AI Builder'),
      ),
      GoRoute(
        path: '/strategy-engine/automation-monitor',
        builder: (_, __) =>
            shell('/strategy-engine/automation-monitor', 'Automation Monitor'),
      ),
      GoRoute(
        path: '/strategy-engine/performance-ranking',
        builder: (_, __) => shell(
            '/strategy-engine/performance-ranking', 'Performance Ranking'),
      ),
    ],
  );
}

void main() {
  testWidgets('Strategy Engine routes navigate across section tabs',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _router()),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Strategies'), findsWidgets);

    await tester.tap(find.text('Templates').first);
    await tester.pumpAndSettle();
    expect(find.text('Templates'), findsWidgets);

    await tester.tap(find.text('Automation Monitor').first);
    await tester.pumpAndSettle();
    expect(find.text('Automation Monitor'), findsWidgets);

    await tester.tap(find.text('Performance Ranking').first);
    await tester.pumpAndSettle();
    expect(find.text('Performance Ranking'), findsWidgets);
  });
}
