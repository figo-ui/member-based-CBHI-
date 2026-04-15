// Facility desktop app tests — verifies BLoC state logic without a running backend.

import 'package:flutter_test/flutter_test.dart';
import 'package:cbhi_facility_desktop/src/blocs/verify_cubit.dart';
import 'package:cbhi_facility_desktop/src/blocs/submit_claim_cubit.dart';
import 'package:cbhi_facility_desktop/src/blocs/claim_tracker_cubit.dart';

void main() {
  // ── VerifyState ────────────────────────────────────────────────────────────

  group('VerifyState', () {
    test('initial state has correct defaults', () {
      final state = VerifyState.initial();
      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(state.error, isNull);
      expect(state.hasResult, isFalse);
    });

    test('isEligible returns true when result has isEligible=true', () {
      final state = VerifyState(
        isLoading: false,
        result: {
          'eligibility': {'isEligible': true},
        },
      );
      expect(state.isEligible, isTrue);
      expect(state.hasResult, isTrue);
    });

    test('isEligible returns false when result has isEligible=false', () {
      final state = VerifyState(
        isLoading: false,
        result: {
          'eligibility': {'isEligible': false},
        },
      );
      expect(state.isEligible, isFalse);
    });

    test('copyWith clears result', () {
      final state = VerifyState(
        isLoading: false,
        result: {'eligibility': {}},
      );
      final cleared = state.copyWith(clearResult: true);
      expect(cleared.result, isNull);
    });

    test('copyWith clears error', () {
      final state = VerifyState(
        isLoading: false,
        error: 'Network error',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });
  });

  // ── SubmitClaimState ───────────────────────────────────────────────────────

  group('SubmitClaimState', () {
    test('initial state has correct defaults', () {
      final state = SubmitClaimState.initial();
      expect(state.isSubmitting, isFalse);
      expect(state.successMessage, isNull);
      expect(state.error, isNull);
      expect(state.hasSuccess, isFalse);
      expect(state.hasError, isFalse);
    });

    test('hasSuccess returns true when successMessage is set', () {
      final state = SubmitClaimState(
        isSubmitting: false,
        successMessage: 'CLM-ABCD',
      );
      expect(state.hasSuccess, isTrue);
    });

    test('hasError returns true when error is set', () {
      final state = SubmitClaimState(
        isSubmitting: false,
        error: 'Beneficiary not found',
      );
      expect(state.hasError, isTrue);
    });

    test('copyWith clears success', () {
      final state = SubmitClaimState(
        isSubmitting: false,
        successMessage: 'CLM-001',
      );
      final cleared = state.copyWith(clearSuccess: true);
      expect(cleared.successMessage, isNull);
    });
  });

  // ── ClaimTrackerState ──────────────────────────────────────────────────────

  group('ClaimTrackerState', () {
    test('initial state has correct defaults', () {
      final state = ClaimTrackerState.initial();
      expect(state.claims, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith updates claims list', () {
      final state = ClaimTrackerState.initial();
      final updated = state.copyWith(claims: [
        {'claimNumber': 'CLM-001', 'status': 'SUBMITTED'},
      ]);
      expect(updated.claims.length, 1);
      expect(updated.claims.first['claimNumber'], 'CLM-001');
    });
  });
}
