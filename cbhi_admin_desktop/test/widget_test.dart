// Admin desktop app tests — verifies BLoC state logic without a running backend.

import 'package:flutter_test/flutter_test.dart';
import 'package:cbhi_admin_desktop/src/blocs/claims_cubit.dart';
import 'package:cbhi_admin_desktop/src/blocs/overview_cubit.dart';
import 'package:cbhi_admin_desktop/src/blocs/indigent_cubit.dart';

void main() {
  // ── ClaimsState ────────────────────────────────────────────────────────────

  group('ClaimsState', () {
    test('initial state has correct defaults', () {
      final state = ClaimsState.initial();
      expect(state.claims, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isReviewing, isFalse);
      expect(state.filter, 'ALL');
      expect(state.searchQuery, '');
      expect(state.error, isNull);
    });

    test('filtered returns all claims when filter is ALL', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'APPROVED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob'},
        ],
        isLoading: false,
        isReviewing: false,
        filter: 'ALL',
      );
      expect(state.filtered.length, 2);
    });

    test('filtered filters by status', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'APPROVED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob'},
        ],
        isLoading: false,
        isReviewing: false,
        filter: 'APPROVED',
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first['claimNumber'], 'CLM-002');
    });

    test('filtered searches by claim number', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob'},
        ],
        isLoading: false,
        isReviewing: false,
        filter: 'ALL',
        searchQuery: 'CLM-001',
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first['beneficiaryName'], 'Alice');
    });

    test('filtered searches by beneficiary name (case-insensitive)', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice Bekele'},
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob Tadesse'},
        ],
        isLoading: false,
        isReviewing: false,
        filter: 'ALL',
        searchQuery: 'alice',
      );
      expect(state.filtered.length, 1);
    });

    test('copyWith clears error', () {
      final state = ClaimsState(
        claims: const [],
        isLoading: false,
        isReviewing: false,
        error: 'Some error',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });
  });

  // ── OverviewState ──────────────────────────────────────────────────────────

  group('OverviewState', () {
    test('initial state has correct defaults', () {
      final state = OverviewState.initial();
      expect(state.report, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith updates report', () {
      final state = OverviewState.initial();
      final updated = state.copyWith(report: {'households': 42});
      expect(updated.report['households'], 42);
    });
  });

  // ── IndigentState ──────────────────────────────────────────────────────────

  group('IndigentState', () {
    test('initial state has correct defaults', () {
      final state = IndigentState.initial();
      expect(state.applications, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isReviewing, isFalse);
    });

    test('copyWith clears success message', () {
      final state = IndigentState(
        applications: const [],
        isLoading: false,
        isReviewing: false,
        successMessage: 'Done',
      );
      final cleared = state.copyWith(clearSuccess: true);
      expect(cleared.successMessage, isNull);
    });
  });
}
