// Widget tests — verifies UI rendering based on AuthState and AppState.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/auth/auth_state.dart';

void main() {
  group('Auth status widget rendering', () {
    testWidgets('shows login prompt for unauthenticated state', (tester) async {
      const state = AuthState(
        status: AuthStatus.unauthenticated, isBusy: false,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.isAuthenticated
                ? const Text('Welcome')
                : const Text('Please sign in'),
          ),
        ),
      ));

      expect(find.text('Please sign in'), findsOneWidget);
      expect(find.text('Welcome'), findsNothing);
    });

    testWidgets('shows welcome for authenticated state', (tester) async {
      const state = AuthState(
        status: AuthStatus.authenticated, isBusy: false,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.isAuthenticated
                ? const Text('Welcome')
                : const Text('Please sign in'),
          ),
        ),
      ));

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Please sign in'), findsNothing);
    });

    testWidgets('shows loading indicator when busy', (tester) async {
      const state = AuthState(
        status: AuthStatus.checking, isBusy: true,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.isBusy
                ? const CircularProgressIndicator()
                : const Text('Ready'),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error is set', (tester) async {
      const state = AuthState(
        status: AuthStatus.unauthenticated,
        isBusy: false,
        error: 'Invalid credentials',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              if (state.error != null)
                Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
              const Text('Please sign in'),
            ],
          ),
        ),
      ));

      expect(find.text('Error: Invalid credentials'), findsOneWidget);
    });

    testWidgets('shows guest mode content', (tester) async {
      const state = AuthState(status: AuthStatus.guest, isBusy: false);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.isGuest
                ? const Text('Guest Mode — Register to unlock all features')
                : const Text('Dashboard'),
          ),
        ),
      ));

      expect(find.text('Guest Mode — Register to unlock all features'), findsOneWidget);
    });
  });

  group('Theme rendering', () {
    testWidgets('MaterialApp renders with light theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        themeMode: ThemeMode.light,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const Scaffold(body: Text('Light Theme')),
      ));
      expect(find.text('Light Theme'), findsOneWidget);
    });

    testWidgets('MaterialApp renders with dark theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        themeMode: ThemeMode.dark,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const Scaffold(body: Text('Dark Theme')),
      ));
      expect(find.text('Dark Theme'), findsOneWidget);
    });
  });
}
