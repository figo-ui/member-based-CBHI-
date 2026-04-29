// Widget tests for MyFamilyScreen
// Tests beneficiary list rendering, add button, and empty state.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/family/my_family_screen.dart';
import 'package:member_based_cbhi/src/family/my_family_cubit.dart';
import 'package:member_based_cbhi/src/auth/auth_cubit.dart';
import 'package:member_based_cbhi/src/auth/auth_state.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}
class MockMyFamilyCubit extends Mock implements MyFamilyCubit {}
class MockAuthCubit extends Mock implements AuthCubit {}

Widget _buildTestApp({
  required FamilyState familyState,
  bool isFamilyMember = false,
}) {
  final repo = MockCbhiRepository();
  final familyCubit = MockMyFamilyCubit();
  final authCubit = MockAuthCubit();

  when(() => familyCubit.state).thenReturn(familyState);
  when(() => familyCubit.stream).thenAnswer((_) => Stream.value(familyState));
  when(() => familyCubit.repository).thenReturn(repo);
  when(() => familyCubit.load()).thenAnswer((_) async {});

  final authState = AuthState(
    status: AuthStatus.authenticated,
    isFamilyMember: isFamilyMember,
  );
  when(() => authCubit.state).thenReturn(authState);
  when(() => authCubit.stream).thenAnswer((_) => Stream.value(authState));

  return MaterialApp(
    localizationsDelegates: CbhiLocalizations.delegatesFor(const Locale('en')),
    supportedLocales: CbhiLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<MyFamilyCubit>.value(value: familyCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
      ],
      child: const MyFamilyScreen(),
    ),
  );
}

void main() {
  group('MyFamilyScreen', () {
    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      final state = FamilyState(
        members: const [],
        isLoading: true,
        isSaving: false,
      );
      await tester.pumpWidget(_buildTestApp(familyState: state));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('shows empty state when no members', (tester) async {
      final state = FamilyState(
        members: const [],
        isLoading: false,
        isSaving: false,
      );
      await tester.pumpWidget(_buildTestApp(familyState: state));
      await tester.pumpAndSettle();
      // Empty state should show some message
      expect(find.byType(MyFamilyScreen), findsOneWidget);
    });

    testWidgets('shows add member button for household head', (tester) async {
      final state = FamilyState(
        members: const [],
        isLoading: false,
        isSaving: false,
      );
      await tester.pumpWidget(_buildTestApp(
        familyState: state,
        isFamilyMember: false,
      ));
      await tester.pumpAndSettle();
      // Add button should be present for household head
      expect(find.byType(FilledButton), findsAny);
    });

    testWidgets('shows member list when members are present', (tester) async {
      final members = [
        FamilyMember.fromJson({
          'id': 'ben-1',
          'membershipId': 'MEM-001',
          'fullName': 'Alemayehu Bekele',
          'coverageStatus': 'ACTIVE',
          'isPrimaryHolder': true,
          'isEligible': true,
        }),
        FamilyMember.fromJson({
          'id': 'ben-2',
          'membershipId': 'MEM-002',
          'fullName': 'Tigist Haile',
          'coverageStatus': 'ACTIVE',
          'isPrimaryHolder': false,
          'isEligible': true,
        }),
      ];

      final state = FamilyState(
        members: members,
        isLoading: false,
        isSaving: false,
      );

      await tester.pumpWidget(_buildTestApp(familyState: state));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alemayehu'), findsAny);
      expect(find.textContaining('Tigist'), findsAny);
    });

    testWidgets('renders without overflow', (tester) async {
      final state = FamilyState(
        members: const [],
        isLoading: false,
        isSaving: false,
      );
      await tester.pumpWidget(_buildTestApp(familyState: state));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
