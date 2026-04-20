import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:predictodds_pro/main.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PredictOddsApp()));
    expect(find.text('PredictOdds Pro'), findsOneWidget);
  });
}
