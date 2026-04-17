import 'dart:convert';

import 'package:aetherpredict_flutter/src/app.dart';
import 'package:aetherpredict_flutter/src/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsWidgets);
}

Future<void> _clearAuthState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_access_token');
  await prefs.remove('auth_refresh_token');
  await prefs.remove('auth_token_type');
}

Future<void> _registerUser(
    String baseUrl, String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'display_name': 'Strategy Engine E2E',
    }),
  );

  expect(
    response.statusCode,
    anyOf(200, 201, 409),
    reason:
        'Expected local backend registration to succeed or report an existing account. Response: ${response.statusCode} ${response.body}',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'logs in and exercises the Strategy Engine flow against a local backend',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final baseUrl = AppConfig.apiBaseUrl;
      final health = await http.get(Uri.parse('$baseUrl/health'));
      expect(
        health.statusCode,
        200,
        reason:
            'Local backend must be running before this integration test. Start apps/backend on $baseUrl and retry.',
      );

      final unique = DateTime.now().millisecondsSinceEpoch;
      final email = 'strategy-e2e-$unique@example.com';
      const password = 'password123';

      await _registerUser(baseUrl, email, password);
      await _clearAuthState();

      await tester.pumpWidget(const ProviderScope(child: AetherPredictApp()));
      await _pumpUntil(tester, find.text('Sign In'));

      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();

      await _pumpUntil(tester, find.text('Forecast Overview'));
      await tester.tap(find.text('Strategy Engine').first);
      await tester.pump();

      await _pumpUntil(tester, find.text('My Strategies'));
      await _pumpUntil(tester, find.text('Canon CLI Prediction Workflow'));

      await tester.tap(find.text('AI Builder').first);
      await tester.pump();
      await _pumpUntil(tester, find.text('Plain-Language Strategy Prompt'));

      await tester.enterText(
        find.byType(TextField).first,
        'Build an innovative cross-market arbitrage model for related BTC prediction markets using ETF flows, sentiment, and public catalyst data.',
      );
      await tester.tap(find.text('Generate Pipeline'));
      await tester.pump();

      await _pumpUntil(tester, find.text('Generated Project Files'));

      await tester.tap(find.text('My Strategies').first);
      await tester.pump();
      await _pumpUntil(tester, find.text('Command Center'));

      await tester.scrollUntilVisible(
        find.text('canon init'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('canon init'));
      await tester.pump();
      await _pumpUntil(tester, find.textContaining('Canon init refreshed'));

      await tester.tap(find.text('canon start'));
      await tester.pump();
      await _pumpUntil(
        tester,
        find.textContaining('Canon start advanced the strategy'),
      );

      await tester.tap(find.text('canon deploy'));
      await tester.pump();
      await _pumpUntil(
        tester,
        find.textContaining('Canon deploy registered the strategy'),
      );

      await tester.tap(find.text('Export Project'));
      await tester.pump();
      await _pumpUntil(tester, find.textContaining('Export ready:'));

      await tester.tap(find.text('Automation Monitor').first);
      await tester.pump();
      await _pumpUntil(tester, find.text('Execution Timeline'));
      expect(find.textContaining('canon deploy'), findsWidgets);

      await tester.tap(find.text('Performance Ranking').first);
      await tester.pump();
      await _pumpUntil(tester, find.text('Prediction Strategy Ranking System'));
      expect(find.text('Registered'), findsWidgets);
    },
  );
}
