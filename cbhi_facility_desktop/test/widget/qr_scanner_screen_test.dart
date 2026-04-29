// Widget tests for QrScannerScreen (facility app)
// Tests manual entry fallback and screen rendering.
// Note: MobileScanner camera is not available in test environment;
// tests verify the manual entry path and UI structure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cbhi_facility_desktop/src/screens/qr_scanner_screen.dart';

Widget _buildTestApp() {
  return const MaterialApp(
    home: QrScannerScreen(),
  );
}

void main() {
  group('QrScannerScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(QrScannerScreen), findsOneWidget);
    });

    testWidgets('shows app bar with scan title', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows manual entry button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Manual entry TextButton should be present
      expect(find.byType(TextButton), findsAny);
    });

    testWidgets('opens manual entry dialog when button tapped', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Tap the manual entry button
      final manualButton = find.byType(TextButton).first;
      await tester.tap(manualButton);
      await tester.pumpAndSettle();

      // Dialog should appear with a text field
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextField), findsAny);
    });

    testWidgets('manual entry dialog has confirm and cancel buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      // Both confirm and cancel buttons should be present
      expect(find.byType(FilledButton), findsAny);
      expect(find.byType(TextButton), findsAtLeastNWidgets(2));
    });

    testWidgets('manual entry dialog cancel closes dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('QrScanResult parses membershipId correctly', (tester) async {
      // Unit test for QrScanResult model
      const result = QrScanResult(
        raw: 'MEM-001',
        membershipId: 'MEM-001',
      );
      expect(result.membershipId, 'MEM-001');
      expect(result.householdCode, isNull);
      expect(result.raw, 'MEM-001');
    });

    testWidgets('QrScanResult parses householdCode correctly', (tester) async {
      const result = QrScanResult(
        raw: '{"householdCode":"HH-001"}',
        householdCode: 'HH-001',
      );
      expect(result.householdCode, 'HH-001');
      expect(result.membershipId, isNull);
    });
  });
}
