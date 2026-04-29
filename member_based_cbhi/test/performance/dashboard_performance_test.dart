// Performance tests for DashboardScreen
// Tests build time, scroll performance, and rebuild count.

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

Widget _buildDashboard(AppState state) {
  final repo = MockCbhiRepository();
  final appCubit = MockAppCubit();
  final authCubit = MockAuthCubit();
  final familyCubit = MockMyFamilyCubit();

  when(() => appCubit.state).thenReturn(state);
  when(() => appCubit.stream).thenAnswer((_) => Stream.value(state));
  when(() => appCubit.repository).thenReturn(repo);

  final authState = const AuthState(status: AuthStatus.authenticated, isBusy: false);
  when(() => authCubit.state).thenReturn(authState);
  when(() => authCubit.stream).thenAnswer((_) => Stream.value(authState));

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
  group('DashboardScreen Performance', () {
    testWidgets('builds in under 100ms', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'ACTIVE', 'premiumAmount': 720.0},
        'card': {'token': 'tok_abc'},
        'claims': [],
        'payments': List.generate(20, (i) => {
          'id': 'pay-$i',
          'amount': '120.00',
          'status': 'SUCCESS',
          'method': 'MOBILE_MONEY',
        }),
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

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(_buildDashboard(state));
      await tester.pump();
      stopwatch.stop();

      // Build should complete in under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'DashboardScreen should build in under 100ms, '
              'took ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('scrolls list of 20 payment items without errors', (tester) async {
      final payments = List.generate(20, (i) => {
        'id': 'pay-$i',
        'amount': '${(i + 1) * 50}.00',
        'status': 'SUCCESS',
        'method': 'MOBILE_MONEY',
        'paidAt': '2025-0${(i % 9) + 1}-01T00:00:00.000Z',
      });

      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'ACTIVE', 'premiumAmount': 720.0},
        'card': {'token': 'tok_abc'},
        'claims': [],
        'payments': payments,
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

      await tester.pumpWidget(_buildDashboard(state));
      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // No exceptions during scroll
      expect(tester.takeException(), isNull);
    });

    testWidgets('state transitions do not trigger excessive rebuilds', (tester) async {
      int buildCount = 0;

      final snapshot = CbhiSnapshot.empty();
      final state = AppState(
        snapshot: snapshot,
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: false,
      );

      // Wrap in a build counter
      final repo = MockCbhiRepository();
      final appCubit = MockAppCubit();
      final authCubit = MockAuthCubit();
      final familyCubit = MockMyFamilyCubit();

      when(() => appCubit.state).thenReturn(state);
      when(() => appCubit.stream).thenAnswer((_) => Stream.value(state));
      when(() => appCubit.repository).thenReturn(repo);

      final authState = const AuthState(status: AuthStatus.authenticated, isBusy: false);
      when(() => authCubit.state).thenReturn(authState);
      when(() => authCubit.stream).thenAnswer((_) => Stream.value(authState));

      final familyState = FamilyState.initial();
      when(() => familyCubit.state).thenReturn(familyState);
      when(() => familyCubit.stream).thenAnswer((_) => Stream.value(familyState));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: CbhiLocalizations.delegatesFor(const Locale('en')),
          supportedLocales: CbhiLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AppCubit>.value(value: appCubit),
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<MyFamilyCubit>.value(value: familyCubit),
            ],
            child: Builder(
              builder: (context) {
                buildCount++;
                return const DashboardScreen();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not rebuild excessively (max 5 rebuilds for initial render)
      expect(buildCount, lessThanOrEqualTo(5),
          reason: 'DashboardScreen triggered $buildCount rebuilds, expected ≤ 5');
    });
  });
}
