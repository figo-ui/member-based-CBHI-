// Comprehensive unit tests for all facility app state classes.

import 'package:flutter_test/flutter_test.dart';
import 'package:cbhi_facility_desktop/src/blocs/verify_cubit.dart';
import 'package:cbhi_facility_desktop/src/blocs/submit_claim_cubit.dart';
import 'package:cbhi_facility_desktop/src/blocs/claim_tracker_cubit.dart';

void main() {
  // ── VerifyState ────────────────────────────────────────────────────────────

  group('VerifyState — comprehensive', () {
    test('initial state has correct defaults', () {
      final state = VerifyState.initial();
      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(state.error, isNull);
      expect(state.hasResult, isFalse);
    });

    test('isEligible returns true when isEligible=true', () {
      final state = VerifyState(
        isLoading: false,
        result: {
          'eligibility': {'isEligible': true},
          'member': {'fullName': 'Abebe', 'membershipId': 'MEM-001'},
        },
      );
      expect(state.isEligible, isTrue);
      expect(state.hasResult, isTrue);
    });

    test('isEligible returns false when isEligible=false', () {
      final state = VerifyState(
        isLoading: false,
        result: {
          'eligibility': {'isEligible': false, 'reason': 'Coverage expired'},
        },
      );
      expect(state.isEligible, isFalse);
      expect(state.hasResult, isTrue);
    });

    test('isEligible returns false when result is null', () {
      final state = VerifyState.initial();
      expect(state.isEligible, isFalse);
    });

    test('isEligible returns false when eligibility key is missing', () {
      const state = VerifyState(isLoading: false, result: {'other': 'data'});
      expect(state.isEligible, isFalse);
    });

    test('copyWith clears result', () {
      final state = VerifyState(
        isLoading: false, result: {'eligibility': {}},
      );
      final cleared = state.copyWith(clearResult: true);
      expect(cleared.result, isNull);
      expect(cleared.hasResult, isFalse);
    });

    test('copyWith clears error', () {
      const state = VerifyState(isLoading: false, error: 'Network error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('copyWith sets loading', () {
      final state = VerifyState.initial();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
    });

    test('copyWith sets result', () {
      final state = VerifyState.initial();
      final withResult = state.copyWith(result: {'eligibility': {'isEligible': true}});
      expect(withResult.hasResult, isTrue);
      expect(withResult.isEligible, isTrue);
    });

    test('Equatable: same states are equal', () {
      final a = VerifyState.initial();
      final b = VerifyState.initial();
      expect(a, equals(b));
    });

    test('Equatable: different states are not equal', () {
      final a = VerifyState.initial();
      final b = a.copyWith(isLoading: true);
      expect(a, isNot(equals(b)));
    });
  });

  // ── SubmitClaimState ───────────────────────────────────────────────────────

  group('SubmitClaimState — comprehensive', () {
    test('initial state has correct defaults', () {
      final state = SubmitClaimState.initial();
      expect(state.isSubmitting, isFalse);
      expect(state.successMessage, isNull);
      expect(state.error, isNull);
      expect(state.hasSuccess, isFalse);
      expect(state.hasError, isFalse);
    });

    test('hasSuccess returns true when successMessage is set', () {
      const state = SubmitClaimState(
        isSubmitting: false, successMessage: 'CLM-2025-0001',
      );
      expect(state.hasSuccess, isTrue);
      expect(state.hasError, isFalse);
    });

    test('hasError returns true when error is set', () {
      const state = SubmitClaimState(
        isSubmitting: false, error: 'Beneficiary not found',
      );
      expect(state.hasError, isTrue);
      expect(state.hasSuccess, isFalse);
    });

    test('copyWith clears success', () {
      const state = SubmitClaimState(
        isSubmitting: false, successMessage: 'CLM-001',
      );
      final cleared = state.copyWith(clearSuccess: true);
      expect(cleared.successMessage, isNull);
      expect(cleared.hasSuccess, isFalse);
    });

    test('copyWith clears error', () {
      const state = SubmitClaimState(
        isSubmitting: false, error: 'Server error',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
      expect(cleared.hasError, isFalse);
    });

    test('copyWith sets isSubmitting', () {
      final state = SubmitClaimState.initial();
      final submitting = state.copyWith(isSubmitting: true);
      expect(submitting.isSubmitting, isTrue);
    });

    test('Equatable: same states are equal', () {
      final a = SubmitClaimState.initial();
      final b = SubmitClaimState.initial();
      expect(a, equals(b));
    });
  });

  // ── ClaimTrackerState ──────────────────────────────────────────────────────

  group('ClaimTrackerState — comprehensive', () {
    test('initial state has correct defaults', () {
      final state = ClaimTrackerState.initial();
      expect(state.claims, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith updates claims list', () {
      final state = ClaimTrackerState.initial();
      final updated = state.copyWith(claims: [
        {'claimNumber': 'CLM-001', 'status': 'SUBMITTED', 'amount': 500},
        {'claimNumber': 'CLM-002', 'status': 'APPROVED', 'amount': 300},
      ]);
      expect(updated.claims.length, 2);
      expect(updated.claims.first['claimNumber'], 'CLM-001');
      expect(updated.claims.last['status'], 'APPROVED');
    });

    test('copyWith sets isLoading', () {
      final state = ClaimTrackerState.initial();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
    });

    test('copyWith sets error', () {
      final state = ClaimTrackerState.initial();
      final withError = state.copyWith(error: 'Connection failed');
      expect(withError.error, 'Connection failed');
    });

    test('copyWith clears error', () {
      final state = ClaimTrackerState(
        claims: const [], isLoading: false, error: 'old',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('Equatable: same states are equal', () {
      final a = ClaimTrackerState.initial();
      final b = ClaimTrackerState.initial();
      expect(a, equals(b));
    });

    test('Equatable: different states are not equal', () {
      final a = ClaimTrackerState.initial();
      final b = a.copyWith(isLoading: true);
      expect(a, isNot(equals(b)));
    });
  });
}
