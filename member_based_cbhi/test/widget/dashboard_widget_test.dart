// Widget tests for DashboardScreen — verifies UI renders correctly

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/cbhi_state.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';
import 'package:member_based_cbhi/src/auth/auth_cubit.dart';
import 'package:member_based_cbhi/src/auth/auth_state.dart';
import 'package:member_based_cbhi/src/dashboard/dashboard_screen.dart';
import 'package:member_based_cbhi/src/family/my_family_cubit.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}
class MockAppCubit extends Mock implements AppCubit {}
class MockAuthCubit extends Mock implements AuthCubit {}
class MockMyFamilyCubit extends Mock implements MyFamilyCubit {}

void main() {
  late MockCbhiRepository mockRepository;
  late MockAppCubit mockAppCubit;
  late MockAuthCubit mockAuthCubit;
  late MockMyFamilyCubit mockFamilyCubit;

  setUp(() {
    mockRepository = MockCbhiRepository();
    mockAppCubit = MockAppCubit();
    mockAuthCubit = MockAuthCubit();
    mockFamilyCubit = MockMyFamilyCubit();

    // Default stubs
    when(() => mockAppCubit.repository).thenReturn(mockRepository);
    when(() => mockAppCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockFamilyCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createTestWidget(AppState appState, AuthState authState) {
    when(() => mockAppCubit.state).thenReturn(appState);
    when(() => mockAuthCubit.state).thenReturn(authState);
    when(() => mockFamilyCubit.state).thenReturn(FamilyState.initial());

    return MaterialApp(
      localizationsDelegates: CbhiLocalizations.delegatesFor(const Locale('en')),
      supportedLocales: CbhiLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AppCubit>.value(value: mockAppCubit),
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
          BlocProvider<MyFamilyCubit>.value(value: mockFamilyCubit),
        ],
        child: const DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen Widget Tests', () {
    testWidgets('shows loading skeleton when isLoading is true', (tester) async {
      final appState = AppState.initial().copyWith(isLoading: true);
      final authState = AuthState.initial();

      await tester.pumpWidget(createTestWidget(appState, authState));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('renders dashboard with snapshot data', (tester) async {
      final snapshot = CbhiSnapshot(
        household: const {
          'householdCode': 'HH-001',
          'coverageStatus': 'ACTIVE',
          'headUser': {
            'firstName': 'Abebe',
            'lastName': 'Tadesse',
          },
        },
        claims: const [],
        payments: const [],
        notifications: const [],
        digitalCards: const [],
        referrals: const [],
        familyMembers: const [],
        syncedAt: '2025-01-01T00:00:00.000Z',
      );

      final appState = AppState.initial().copyWith(
        isLoading: false,
        snapshot: snapshot,
      );
      final authState = AuthState.initial().copyWith(
        status: AuthStatus.authenticated,
        session: const AuthSession(
          accessToken: 'token',
          tokenType: 'Bearer',
          expiresAt: '2025-12-31T00:00:00.000Z',
          user: AppUserProfile(
            id: '1',
            displayName: 'Abebe Tadesse',
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget(appState, authState));
      await tester.pumpAndSettle();

      // Verify household code is displayed
      expect(find.textContaining('HH-001'), findsOneWidget);
    });

    testWidgets('shows coverage status badge', (tester) async {
      final snapshot = CbhiSnapshot(
        household: const {
          'householdCode': 'HH-002',
          'coverageStatus': 'ACTIVE',
        },
        coverage: const {
          'status': 'ACTIVE',
        },
        claims: const [],
        payments: const [],
        notifications: const [],
        digitalCards: const [],
        referrals: const [],
        familyMembers: const [],
        syncedAt: '2025-01-01T00:00:00.000Z',
      );

      final appState = AppState.initial().copyWith(
        isLoading: false,
        snapshot: snapshot,
      );
      final authState = AuthState.initial().copyWith(
        status: AuthStatus.authenticated,
        session: const AuthSession(
          accessToken: 'token',
          tokenType: 'Bearer',
          expiresAt: '2025-12-31T00:00:00.000Z',
          user: AppUserProfile(
            id: '1',
            displayName: 'Test User',
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget(appState, authState));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsWidgets);
    });
  });
}
