// Widget tests for DigitalCardScreen
// Tests member name display, QR widget presence, and no overflow.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:member_based_cbhi/src/cbhi_state.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/card/digital_card_screen.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';

class MockAppCubit extends Mock implements AppCubit {}

Widget _buildTestApp(AppState state) {
  final cubit = MockAppCubit();
  when(() => cubit.state).thenReturn(state);
  when(() => cubit.stream).thenAnswer((_) => Stream.value(state));
  when(() => cubit.sync()).thenAnswer((_) async {});

  return MaterialApp(
    localizationsDelegates: CbhiLocalizations.delegatesFor(const Locale('en')),
    supportedLocales: CbhiLocalizations.supportedLocales,
    home: BlocProvider<AppCubit>.value(
      value: cubit,
      child: const DigitalCardScreen(),
    ),
  );
}

void main() {
  group('DigitalCardScreen', () {
    testWidgets('renders without crashing', (tester) async {
      final state = AppState(
        snapshot: CbhiSnapshot.empty(),
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: false,
      );
      await tester.pumpWidget(_buildTestApp(state));
      await tester.pumpAndSettle();
      expect(find.byType(DigitalCardScreen), findsOneWidget);
    });

    testWidgets('shows member name when snapshot has viewer name', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {
          'householdCode': 'HH-001',
          'headUser': {
            'firstName': 'Alemayehu',
            'middleName': '',
            'lastName': 'Bekele',
          },
        },
        'coverage': {'status': 'ACTIVE'},
        'card': {'token': 'tok_abc123'},
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [
          {
            'memberId': 'ben-1',
            'memberName': 'Alemayehu Bekele',
            'membershipId': 'MEM-001',
            'coverageStatus': 'ACTIVE',
            'token': 'tok_abc123',
          },
        ],
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

      await tester.pumpWidget(_buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alemayehu'), findsAny);
    });

    testWidgets('shows QR widget when token is present', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'ACTIVE'},
        'card': {'token': 'tok_abc123'},
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [
          {
            'memberId': 'ben-1',
            'memberName': 'Test Member',
            'membershipId': 'MEM-001',
            'coverageStatus': 'ACTIVE',
            'token': 'tok_abc123',
          },
        ],
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

      await tester.pumpWidget(_buildTestApp(state));
      await tester.pumpAndSettle();

      // QrImageView should be present when token exists
      expect(find.byType(QrImageView), findsAny);
    });

    testWidgets('shows no-card placeholder when token is empty', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'PENDING_RENEWAL'},
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '',
      });

      final state = AppState(
        snapshot: snapshot,
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: false,
      );

      await tester.pumpWidget(_buildTestApp(state));
      await tester.pumpAndSettle();

      // QrImageView should NOT be present when no token
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('renders without overflow', (tester) async {
      final state = AppState(
        snapshot: CbhiSnapshot.empty(),
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: false,
      );
      await tester.pumpWidget(_buildTestApp(state));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
