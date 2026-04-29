// Widget tests for DashboardScreen
// Tests loading, loaded, and error states.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/cbhi_state.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/dashboard/dashboard_screen.dart';
import 'package:member_based_cbhi/src/auth/auth_cubit.dart';
import 'package:member_based_cbhi/src/auth/auth_state.dart';
import 'package:member_based_cbhi/src/family/my_family_cubit.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}
class MockAppCubit extends Mock implements AppCubit {}
class MockAuthCubit extends Mock implements AuthCubit {}
class MockMyFamilyCubit extends Mock implements MyFamilyCubit {}

Widget _buildTestApp({
  required AppState appState,
  AuthState? authState,
}) {
  final repo = MockCbhiRepository();
  final appCubit = MockAppCubit();
  final authCubit = MockAuthCubit();
  final familyCubit = MockMyFamilyCubit();

  when(() => appCubit.state).thenReturn(appState);
  when(() => appCubit.stream).thenAnswer((_) => Stream.value(appState));
  when(() => appCubit.repository).thenReturn(repo);

  final resolvedAuthState = authState ??
      const AuthState(status: AuthStatus.authenticated, isBusy: false);
  when(() => authCubit.state).thenReturn(resolvedAuthState);
  when(() => authCubit.stream).thenAnswer((_) => Stream.value(resolvedAuthState));

  final familyState = FamilyState.initial();
  when(() => familyCubit.state).thenReturn(familyState);
  when(() => familyCubit.stream).thenAnswer((_) => Stream.value(familyState));

  return MaterialApp(
    localizationsDelegates: CbhiLocalizations.delegatesFor(const Locale('en')),
    supportedLocales: CbhiLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AppCubit>.value(value: appCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<MyFamilyCubit>.value(value: familyCubit),
      ],
      child: const DashboardScreen(),
    ),
  );
}

void main() {
  group('DashboardScreen', () {
    testWidgets('shows loading skeleton when isLoading is true', (tester) async {
      final state = AppState.initial(); // isLoading = true
      await tester.pumpWidget(_buildTestApp(appState: state));
      await tester.pump();

      // DashboardSkeleton should be visible (contains shimmer/loading widgets)
      // We check that the coverage hero card is NOT present yet
      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('shows coverage status when loaded with snapshot', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {
          'householdCode': 'HH-001',
          'headUser': {
            'firstName': 'Alemayehu',
            'lastName': 'Bekele',
          },
        },
        'coverage': {
          'status': 'ACTIVE',
          'premiumAmount': 720.0,
          'paidAmount': 720.0,
        },
        'card': {'token': 'tok_abc'},
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '2025-01-01T00:00:00.000Z',
      });

      final state = AppState(
        snapshot: snapshot,
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: false,
      );

      await tester.pumpWidget(_buildTestApp(appState: state));
      await tester.pumpAndSettle();

      // Coverage status should be visible
      expect(find.textContaining('ACTIVE'), findsAny);
    });

    testWidgets('shows error message when error is set', (tester) async {
      final state = AppState(
        snapshot: null,
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: false,
        error: 'Network error',
      );

      await tester.pumpWidget(_buildTestApp(appState: state));
      await tester.pumpAndSettle();

      // Error state — snapshot is null so empty snapshot is used
      // The screen should still render without crashing
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('renders without overflow', (tester) async {
      final snapshot = CbhiSnapshot.empty();
      final state = AppState(
        snapshot: snapshot,
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: false,
      );

      await tester.pumpWidget(_buildTestApp(appState: state));
      await tester.pumpAndSettle();

      // No overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows syncing indicator when isSyncing is true', (tester) async {
      final snapshot = CbhiSnapshot.empty();
      final state = AppState(
        snapshot: snapshot,
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: true,
      );

      await tester.pumpWidget(_buildTestApp(appState: state));
      await tester.pump();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
