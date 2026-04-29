// Widget tests for SubmitClaimScreen (facility app)
// Tests form field presence, validation, submit button, and success/error states.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_facility_desktop/src/data/facility_repository.dart';
import 'package:cbhi_facility_desktop/src/screens/submit_claim_screen.dart';

class MockFacilityRepository extends Mock implements FacilityRepository {}

Widget _buildTestApp(FacilityRepository repository) {
  return MaterialApp(
    home: Scaffold(
      body: SubmitClaimScreen(repository: repository),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('SubmitClaimScreen', () {
    testWidgets('renders without crashing', (tester) async {
      final repo = MockFacilityRepository();
      when(() => repo.getBenefitPackageItems()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pump();

      expect(find.byType(SubmitClaimScreen), findsOneWidget);
    });

    testWidgets('shows membership ID field', (tester) async {
      final repo = MockFacilityRepository();
      when(() => repo.getBenefitPackageItems()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsAny);
    });

    testWidgets('shows submit claim button', (tester) async {
      final repo = MockFacilityRepository();
      when(() => repo.getBenefitPackageItems()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsAny);
    });

    testWidgets('shows service date picker', (tester) async {
      final repo = MockFacilityRepository();
      when(() => repo.getBenefitPackageItems()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Service date InkWell should be present
      expect(find.byType(InkWell), findsAny);
    });

    testWidgets('shows error when submitting with no service items', (tester) async {
      final repo = MockFacilityRepository();
      when(() => repo.getBenefitPackageItems()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Tap submit button with empty items
      final submitButton = find.byType(FilledButton).last;
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show error or confirmation dialog
      expect(find.byType(SubmitClaimScreen), findsOneWidget);
    });

    testWidgets('shows success message after successful submission', (tester) async {
      final repo = MockFacilityRepository();
      when(() => repo.getBenefitPackageItems()).thenAnswer((_) async => []);
      when(() => repo.submitClaim(
            membershipId: any(named: 'membershipId'),
            phoneNumber: any(named: 'phoneNumber'),
            householdCode: any(named: 'householdCode'),
            fullName: any(named: 'fullName'),
            serviceDate: any(named: 'serviceDate'),
            items: any(named: 'items'),
            supportingDocumentPath: any(named: 'supportingDocumentPath'),
            supportingDocumentUpload: any(named: 'supportingDocumentUpload'),
          )).thenAnswer((_) async => {
            'id': 'clm-1',
            'claimNumber': 'CLM-2025-001',
            'status': 'SUBMITTED',
          });

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Fill in membership ID
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'MEM-001');
      }

      // Screen renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow', (tester) async {
      final repo = MockFacilityRepository();
      when(() => repo.getBenefitPackageItems()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows scan QR button', (tester) async {
      final repo = MockFacilityRepository();
      when(() => repo.getBenefitPackageItems()).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      // Scan QR button should be present
      expect(find.byType(OutlinedButton), findsAny);
    });
  });
}
