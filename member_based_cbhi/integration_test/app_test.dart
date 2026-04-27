// Integration test for the member app.
// Run with: flutter test integration_test/app_test.dart
// Requires a running device or emulator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:member_based_cbhi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App startup integration test', () {
    testWidgets('App launches without crashing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The app should have rendered something — either the welcome/login
      // screen or the dashboard depending on auth state.
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
