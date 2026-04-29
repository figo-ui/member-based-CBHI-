// Widget tests for LoginScreen (admin app)
// Tests field presence, loading state, and error display.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';
import 'package:cbhi_admin_desktop/src/screens/login_screen.dart';
import 'package:cbhi_admin_desktop/src/i18n/app_localizations.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

Widget _buildTestApp({
  required AdminRepository repository,
  VoidCallback? onLogin,
}) {
  return MaterialApp(
    home: LoginScreen(
      repository: repository,
      onLogin: onLogin ?? () {},
      locale: const Locale('en'),
      onLocaleChanged: (_) {},
    ),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders without crashing', (tester) async {
      final repo = MockAdminRepository();
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('shows identifier/phone field', (tester) async {
      final repo = MockAdminRepository();
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsAny);
    });

    testWidgets('shows password field', (tester) async {
      final repo = MockAdminRepository();
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();
      // At least 2 text fields: identifier + password
      expect(find.byType(TextField), findsAtLeastNWidgets(2));
    });

    testWidgets('shows sign in button', (tester) async {
      final repo = MockAdminRepository();
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsAny);
    });

    testWidgets('shows error message on failed login', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.login(
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
          )).thenThrow(Exception('Invalid credentials'));

      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Enter credentials
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '+251912345678');
      await tester.enterText(textFields.at(1), 'wrongpassword');

      // Tap sign in
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.textContaining('Invalid credentials'), findsAny);
    });

    testWidgets('shows loading indicator during login', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.login(
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 5));
        return {'accessToken': 'tok_abc'};
      });

      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '+251912345678');
      await tester.enterText(textFields.at(1), 'password123');

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump(); // Don't settle — check loading state

      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('renders without overflow', (tester) async {
      final repo = MockAdminRepository();
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
