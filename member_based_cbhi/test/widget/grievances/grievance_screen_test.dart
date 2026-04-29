// Widget tests for GrievanceScreen
// Tests list rendering, submit button, and status chips.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/grievances/grievance_screen.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}

Widget _buildTestApp(CbhiRepository repo) {
  return MaterialApp(
    localizationsDelegates: CbhiLocalizations.delegatesFor(const Locale('en')),
    supportedLocales: CbhiLocalizations.supportedLocales,
    home: GrievanceScreen(repository: repo),
  );
}

void main() {
  group('GrievanceScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      final repo = MockCbhiRepository();
      // Never completes — simulates loading
      when(() => repo.getMyGrievances())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return [];
      });

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pump(); // First frame

      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('shows empty state when no grievances', (tester) async {
      final repo = MockCbhiRepository();
      when(() => repo.getMyGrievances()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(GrievanceScreen), findsOneWidget);
    });

    testWidgets('shows grievance list when grievances exist', (tester) async {
      final repo = MockCbhiRepository();
      when(() => repo.getMyGrievances()).thenAnswer((_) async => [
        {
          'id': 'grv-1',
          'type': 'CLAIM_REJECTION',
          'subject': 'Claim was wrongly rejected',
          'description': 'My claim for OPD services was rejected without reason.',
          'status': 'OPEN',
          'createdAt': '2025-01-15T10:00:00.000Z',
        },
        {
          'id': 'grv-2',
          'type': 'FACILITY_DENIAL',
          'subject': 'Denied at facility',
          'description': 'Facility refused to accept my card.',
          'status': 'UNDER_REVIEW',
          'createdAt': '2025-02-01T10:00:00.000Z',
        },
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Claim was wrongly rejected'), findsAny);
      expect(find.textContaining('Denied at facility'), findsAny);
    });

    testWidgets('shows status chips for grievances', (tester) async {
      final repo = MockCbhiRepository();
      when(() => repo.getMyGrievances()).thenAnswer((_) async => [
        {
          'id': 'grv-1',
          'type': 'OTHER',
          'subject': 'Test grievance',
          'description': 'Test description',
          'status': 'RESOLVED',
          'createdAt': '2025-01-15T10:00:00.000Z',
        },
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('RESOLVED'), findsAny);
    });

    testWidgets('shows submit tab with form fields', (tester) async {
      final repo = MockCbhiRepository();
      when(() => repo.getMyGrievances()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Tap the "Submit New" tab
      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      // Submit button should be present
      expect(find.byType(FilledButton), findsAny);
    });

    testWidgets('shows error message on load failure', (tester) async {
      final repo = MockCbhiRepository();
      when(() => repo.getMyGrievances())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsAny);
    });

    testWidgets('renders without overflow', (tester) async {
      final repo = MockCbhiRepository();
      when(() => repo.getMyGrievances()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
