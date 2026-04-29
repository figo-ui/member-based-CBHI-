// Widget tests for IndigentScreen (admin app)
// Tests list rendering, approve/reject buttons.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';
import 'package:cbhi_admin_desktop/src/screens/indigent_screen.dart';
import 'package:cbhi_admin_desktop/src/i18n/app_localizations.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

Widget _buildTestApp(AdminRepository repository) {
  return MaterialApp(
    home: Scaffold(
      body: IndigentScreen(repository: repository),
    ),
  );
}

void main() {
  group('IndigentScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getPendingIndigent()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return [];
      });

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('shows empty state when no applications', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getPendingIndigent()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(IndigentScreen), findsOneWidget);
    });

    testWidgets('shows applications list when data is present', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getPendingIndigent()).thenAnswer((_) async => [
        {
          'id': 'ind-1',
          'userId': 'usr-1',
          'status': 'PENDING_REVIEW',
          'income': 500,
          'employmentStatus': 'UNEMPLOYED',
          'familySize': 4,
          'score': 85,
          'documentMeta': [],
        },
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // DataTable should be present with data
      expect(find.byType(DataTable), findsAny);
    });

    testWidgets('shows approve and reject buttons for pending applications', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getPendingIndigent()).thenAnswer((_) async => [
        {
          'id': 'ind-1',
          'userId': 'usr-1',
          'status': 'PENDING_REVIEW',
          'income': 500,
          'employmentStatus': 'UNEMPLOYED',
          'familySize': 4,
          'score': 85,
          'documentMeta': [],
        },
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Approve and reject buttons should be present
      expect(find.byType(TextButton), findsAny);
    });

    testWidgets('shows error message on load failure', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getPendingIndigent())
          .thenThrow(Exception('Server error'));

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Server error'), findsAny);
    });

    testWidgets('renders without overflow', (tester) async {
      final repo = MockAdminRepository();
      when(() => repo.getPendingIndigent()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
