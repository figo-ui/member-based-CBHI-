// Widget tests for LoginScreen — verifies UI renders correctly

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';
import 'package:cbhi_admin_desktop/src/screens/login_screen.dart';
import 'package:cbhi_admin_desktop/src/i18n/app_localizations.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminRepository();
  });

  Widget createTestWidget() {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegateFor(const Locale('en')),
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginScreen(
        repository: mockRepository,
        onLogin: () {},
        locale: const Locale('en'),
        onLocaleChanged: (_) {},
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders login form with email and password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows error message when login fails', (tester) async {
      when(() => mockRepository.login(
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
          )).thenThrow(Exception('Invalid credentials'));

      await tester.pumpWidget(createTestWidget());

      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'admin@test.com');
      await tester.enterText(find.byType(TextField).last, 'password');

      // Tap login button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Error should be displayed
      expect(find.textContaining('Invalid credentials'), findsOneWidget);
    });

    testWidgets('password field is obscured by default', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final passwordField = tester.widget<TextField>(find.byType(TextField).last);
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('toggle password visibility button works', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButton, findsOneWidget);

      // Tap to show password
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
