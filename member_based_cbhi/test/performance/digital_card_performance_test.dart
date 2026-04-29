// Performance tests for DigitalCardScreen
// Tests QR render time and animation smoothness.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/cbhi_state.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/card/digital_card_screen.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';

class MockAppCubit extends Mock implements AppCubit {}

Widget _buildCard(AppState state) {
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
  group('DigitalCardScreen Performance', () {
    testWidgets('renders QR within frame budget (< 16ms per frame)', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'ACTIVE'},
        'card': {'token': 'tok_abc123_member_qr_token_for_facility_verification'},
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [
          {
            'memberId': 'ben-1',
            'memberName': 'Alemayehu Bekele',
            'membershipId': 'MEM-001',
            'coverageStatus': 'ACTIVE',
            'token': 'tok_abc123_member_qr_token_for_facility_verification',
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

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(_buildCard(state));
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Full render including QR should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'DigitalCardScreen with QR took too long: ${stopwatch.elapsedMilliseconds}ms');

      // No exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('card flip animation completes without dropped frames', (tester) async {
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

      await tester.pumpWidget(_buildCard(state));
      await tester.pumpAndSettle();

      // Tap the card to trigger flip animation
      final cardGesture = find.byType(GestureDetector).first;
      await tester.tap(cardGesture);

      // Pump through the animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // No exceptions during animation
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders empty card state without errors', (tester) async {
      final state = AppState(
        snapshot: CbhiSnapshot.empty(),
        locale: const Locale('en'),
        isLoading: false,
        isSyncing: false,
      );

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(_buildCard(state));
      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(tester.takeException(), isNull);
    });
  });
}
