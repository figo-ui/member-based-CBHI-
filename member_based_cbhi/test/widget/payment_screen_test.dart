// Widget tests for PaymentScreen
// Tests amount display, pay button presence, and loading state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/payment/payment_screen.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}

Widget _buildTestApp({
  required CbhiSnapshot snapshot,
  VoidCallback? onPaymentComplete,
}) {
  final repo = MockCbhiRepository();
  return MaterialApp(
    localizationsDelegates: CbhiLocalizations.delegatesFor(const Locale('en')),
    supportedLocales: CbhiLocalizations.supportedLocales,
    home: Scaffold(
      body: PaymentScreen(
        repository: repo,
        snapshot: snapshot,
        onPaymentComplete: onPaymentComplete ?? () {},
      ),
    ),
  );
}

void main() {
  group('PaymentScreen', () {
    testWidgets('renders without crashing', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'PENDING_RENEWAL', 'premiumAmount': 720.0},
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '',
      });

      await tester.pumpWidget(_buildTestApp(snapshot: snapshot));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentScreen), findsOneWidget);
    });

    testWidgets('shows premium amount when coverage has premiumAmount', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'PENDING_RENEWAL', 'premiumAmount': 720.0},
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '',
      });

      await tester.pumpWidget(_buildTestApp(snapshot: snapshot));
      await tester.pumpAndSettle();

      // Amount should be displayed
      expect(find.textContaining('720'), findsAny);
    });

    testWidgets('shows pay button when not loading', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'PENDING_RENEWAL', 'premiumAmount': 720.0},
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '',
      });

      await tester.pumpWidget(_buildTestApp(snapshot: snapshot));
      await tester.pumpAndSettle();

      // FilledButton for payment should be present
      expect(find.byType(FilledButton), findsAny);
    });

    testWidgets('shows Chapa payment methods section', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'PENDING_RENEWAL', 'premiumAmount': 720.0},
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '',
      });

      await tester.pumpWidget(_buildTestApp(snapshot: snapshot));
      await tester.pumpAndSettle();

      // Chapa payment methods should be visible
      expect(find.textContaining('Telebirr'), findsAny);
    });

    testWidgets('shows manual proof section', (tester) async {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-001'},
        'coverage': {'status': 'PENDING_RENEWAL', 'premiumAmount': 720.0},
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '',
      });

      await tester.pumpWidget(_buildTestApp(snapshot: snapshot));
      await tester.pumpAndSettle();

      // Manual bank receipt button should be present
      expect(find.byType(OutlinedButton), findsAny);
    });

    testWidgets('renders without overflow', (tester) async {
      final snapshot = CbhiSnapshot.empty();
      await tester.pumpWidget(_buildTestApp(snapshot: snapshot));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
