// Widget tests for facility app — state-driven UI rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cbhi_facility_desktop/src/blocs/verify_cubit.dart';
import 'package:cbhi_facility_desktop/src/blocs/submit_claim_cubit.dart';
import 'package:cbhi_facility_desktop/src/blocs/claim_tracker_cubit.dart';

void main() {
  group('Verify screen widget rendering', () {
    testWidgets('shows idle state', (tester) async {
      final state = VerifyState.initial();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.hasResult
                ? const Text('Eligibility result')
                : const Text('Enter member details to verify'),
          ),
        ),
      ));

      expect(find.text('Enter member details to verify'), findsOneWidget);
    });

    testWidgets('shows eligible result', (tester) async {
      final state = VerifyState(
        isLoading: false,
        result: {'eligibility': {'isEligible': true}},
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.hasResult
                ? (state.isEligible
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 48)
                    : const Icon(Icons.cancel, color: Colors.red, size: 48))
                : const Text('Waiting'),
          ),
        ),
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('shows ineligible result', (tester) async {
      final state = VerifyState(
        isLoading: false,
        result: {'eligibility': {'isEligible': false}},
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.hasResult
                ? (state.isEligible
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 48)
                    : const Icon(Icons.cancel, color: Colors.red, size: 48))
                : const Text('Waiting'),
          ),
        ),
      ));

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('shows loading during verification', (tester) async {
      const state = VerifyState(isLoading: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.isLoading
                ? const CircularProgressIndicator()
                : const Text('Done'),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message', (tester) async {
      const state = VerifyState(isLoading: false, error: 'Member not found');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.error != null
                ? Text('Error: ${state.error}')
                : const Text('OK'),
          ),
        ),
      ));

      expect(find.text('Error: Member not found'), findsOneWidget);
    });
  });

  group('Submit claim widget rendering', () {
    testWidgets('shows success message after submission', (tester) async {
      const state = SubmitClaimState(
        isSubmitting: false, successMessage: 'CLM-2025-0001',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.hasSuccess
                ? Text('Claim submitted: ${state.successMessage}')
                : const Text('Submit a claim'),
          ),
        ),
      ));

      expect(find.text('Claim submitted: CLM-2025-0001'), findsOneWidget);
    });

    testWidgets('shows submitting indicator', (tester) async {
      const state = SubmitClaimState(isSubmitting: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.isSubmitting
                ? const CircularProgressIndicator()
                : const Text('Ready'),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Claim tracker widget rendering', () {
    testWidgets('shows empty claims list', (tester) async {
      final state = ClaimTrackerState.initial();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: state.claims.isEmpty
              ? const Center(child: Text('No claims tracked'))
              : const Text('Has claims'),
        ),
      ));

      expect(find.text('No claims tracked'), findsOneWidget);
    });

    testWidgets('shows claims in a list', (tester) async {
      final state = ClaimTrackerState(
        claims: [
          {'claimNumber': 'CLM-T1', 'status': 'SUBMITTED'},
          {'claimNumber': 'CLM-T2', 'status': 'APPROVED'},
        ],
        isLoading: false,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: state.claims.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(state.claims[i]['claimNumber']?.toString() ?? ''),
              trailing: Text(state.claims[i]['status']?.toString() ?? ''),
            ),
          ),
        ),
      ));

      expect(find.text('CLM-T1'), findsOneWidget);
      expect(find.text('CLM-T2'), findsOneWidget);
      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);
    });
  });
}
