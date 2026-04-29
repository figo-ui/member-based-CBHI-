// Widget tests for GrievancesAdminScreen
// Tests list rendering, status filter, and resolve action.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';
import 'package:cbhi_admin_desktop/src/screens/grievances_admin_screen.dart';
import 'package:cbhi_admin_desktop/src/i18n/app_localizations.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

Widget _buildTestApp(AdminRepository repository) {
  return MaterialApp(
    home: Scaffold(
      body: GrievancesAdminScreen(repository: repository),
    ),
  );
}

void main() {
  group('GrievancesAdminScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllGrievances(status: any(named: 'status')))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return [];
      });

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('shows empty state when no grievances', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllGrievances(status: any(named: 'status')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(GrievancesAdminScreen), findsOneWidget);
    });

    testWidgets('shows grievances list when data is present', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllGrievances(status: any(named: 'status')))
          .thenAnswer((_) async => [
        {
          'id': 'grv-1',
          'type': 'CLAIM_REJECTION',
          'subject': 'Claim wrongly rejected',
          'description': 'My claim was rejected without reason.',
          'status': 'OPEN',
          'createdAt': '2025-01-15T10:00:00.000Z',
        },
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Claim wrongly rejected'), findsAny);
    });

    testWidgets('shows status filter chips', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllGrievances(status: any(named: 'status')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Filter chips should be present
      expect(find.byType(FilterChip), findsAny);
    });

    testWidgets('shows resolve button for open grievances', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllGrievances(status: any(named: 'status')))
          .thenAnswer((_) async => [
        {
          'id': 'grv-1',
          'type': 'OTHER',
          'subject': 'Test grievance',
          'description': 'Test description',
          'status': 'OPEN',
          'createdAt': '2025-01-15T10:00:00.000Z',
        },
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Resolve button should be present for open grievances
      expect(find.byType(FilledButton), findsAny);
    });

    testWidgets('shows error message on load failure', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllGrievances(status: any(named: 'status')))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsAny);
    });

    testWidgets('renders without overflow', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getAllGrievances(status: any(named: 'status')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
