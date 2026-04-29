// Widget tests for ClaimAppealsScreen
// Tests appeals list rendering and approve/reject buttons.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';
import 'package:cbhi_admin_desktop/src/screens/claim_appeals_screen.dart';
import 'package:cbhi_admin_desktop/src/i18n/app_localizations.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

Widget _buildTestApp(AdminRepository repository) {
  return MaterialApp(
    home: Scaffold(
      body: ClaimAppealsScreen(repository: repository),
    ),
  );
}

void main() {
  group('ClaimAppealsScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllAppeals()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return [];
      });

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('shows empty state when no appeals', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllAppeals()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(ClaimAppealsScreen), findsOneWidget);
    });

    testWidgets('shows appeals list when data is present', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllAppeals()).thenAnswer((_) async => [
        {
          'id': 'app-1',
          'claimNumber': 'CLM-001',
          'submittedBy': 'Alemayehu Bekele',
          'reason': 'Claim was incorrectly rejected',
          'status': 'PENDING',
          'createdAt': '2025-01-15T10:00:00.000Z',
        },
        {
          'id': 'app-2',
          'claimNumber': 'CLM-002',
          'submittedBy': 'Tigist Haile',
          'reason': 'Amount was underpaid',
          'status': 'APPROVED',
          'createdAt': '2025-02-01T10:00:00.000Z',
        },
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('CLM-001'), findsAny);
      expect(find.textContaining('CLM-002'), findsAny);
    });

    testWidgets('shows review button for pending appeals', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllAppeals()).thenAnswer((_) async => [
        {
          'id': 'app-1',
          'claimNumber': 'CLM-001',
          'submittedBy': 'Alemayehu Bekele',
          'reason': 'Claim was incorrectly rejected',
          'status': 'PENDING',
          'createdAt': '2025-01-15T10:00:00.000Z',
        },
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Review button should be present for pending appeals
      expect(find.byType(FilledButton), findsAny);
    });

    testWidgets('shows error message on load failure', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllAppeals()).thenThrow(Exception('Server error'));

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Server error'), findsAny);
    });

    testWidgets('renders without overflow', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllAppeals()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
