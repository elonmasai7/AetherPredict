import 'package:aetherpredict_flutter/src/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots into AetherPredict shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AetherPredictApp(),
      ),
    );

    await tester.pump();
    expect(find.text('AetherPredict'), findsOneWidget);
  });
}
