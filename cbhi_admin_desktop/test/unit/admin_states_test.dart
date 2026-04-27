// Comprehensive unit tests for admin app state classes.

import 'package:flutter_test/flutter_test.dart';
import 'package:cbhi_admin_desktop/src/blocs/claims_cubit.dart';
import 'package:cbhi_admin_desktop/src/blocs/overview_cubit.dart';
import 'package:cbhi_admin_desktop/src/blocs/indigent_cubit.dart';

void main() {
  // ── ClaimsState ────────────────────────────────────────────────────────────

  group('ClaimsState — comprehensive', () {
    test('initial state has correct defaults', () {
      final state = ClaimsState.initial();
      expect(state.claims, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isReviewing, isFalse);
      expect(state.filter, 'ALL');
      expect(state.searchQuery, '');
      expect(state.error, isNull);
      expect(state.successMessage, isNull);
    });

    test('filtered returns all claims when filter is ALL', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'APPROVED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob'},
          {'status': 'REJECTED', 'claimNumber': 'CLM-003', 'beneficiaryName': 'Charlie'},
        ],
        isLoading: false, isReviewing: false, filter: 'ALL',
      );
      expect(state.filtered.length, 3);
    });

    test('filtered filters by SUBMITTED status', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'APPROVED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob'},
        ],
        isLoading: false, isReviewing: false, filter: 'SUBMITTED',
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first['claimNumber'], 'CLM-001');
    });

    test('filtered filters by REJECTED status', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'REJECTED', 'claimNumber': 'CLM-003', 'beneficiaryName': 'Charlie'},
        ],
        isLoading: false, isReviewing: false, filter: 'REJECTED',
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first['beneficiaryName'], 'Charlie');
    });

    test('filtered searches by claim number', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob'},
        ],
        isLoading: false, isReviewing: false,
        filter: 'ALL', searchQuery: 'CLM-002',
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first['beneficiaryName'], 'Bob');
    });

    test('filtered searches by beneficiary name (case-insensitive)', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice Bekele'},
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob Tadesse'},
        ],
        isLoading: false, isReviewing: false,
        filter: 'ALL', searchQuery: 'alice',
      );
      expect(state.filtered.length, 1);
    });

    test('filtered searches by household code', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice', 'householdCode': 'HH-001'},
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob', 'householdCode': 'HH-002'},
        ],
        isLoading: false, isReviewing: false,
        filter: 'ALL', searchQuery: 'HH-002',
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first['claimNumber'], 'CLM-002');
    });

    test('filtered combines filter and search', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'APPROVED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Alice B'},
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-003', 'beneficiaryName': 'Bob'},
        ],
        isLoading: false, isReviewing: false,
        filter: 'SUBMITTED', searchQuery: 'alice',
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first['claimNumber'], 'CLM-001');
    });

    test('filtered returns empty when no matches', () {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
        ],
        isLoading: false, isReviewing: false,
        filter: 'ALL', searchQuery: 'zzzzz',
      );
      expect(state.filtered, isEmpty);
    });

    test('copyWith clears error', () {
      final state = ClaimsState(
        claims: const [], isLoading: false, isReviewing: false,
        error: 'Some error',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('copyWith clears success message', () {
      final state = ClaimsState(
        claims: const [], isLoading: false, isReviewing: false,
        successMessage: 'Done',
      );
      final cleared = state.copyWith(clearSuccess: true);
      expect(cleared.successMessage, isNull);
    });

    test('copyWith updates filter', () {
      final state = ClaimsState.initial();
      final updated = state.copyWith(filter: 'APPROVED');
      expect(updated.filter, 'APPROVED');
    });

    test('copyWith updates searchQuery', () {
      final state = ClaimsState.initial();
      final updated = state.copyWith(searchQuery: 'test');
      expect(updated.searchQuery, 'test');
    });

    test('Equatable: same states are equal', () {
      final a = ClaimsState.initial();
      final b = ClaimsState.initial();
      expect(a, equals(b));
    });

    test('Equatable: different states are not equal', () {
      final a = ClaimsState.initial();
      final b = a.copyWith(isLoading: true);
      expect(a, isNot(equals(b)));
    });
  });

  // ── OverviewState ──────────────────────────────────────────────────────────

  group('OverviewState — comprehensive', () {
    test('initial state has correct defaults', () {
      final state = OverviewState.initial();
      expect(state.report, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith updates report', () {
      final state = OverviewState.initial();
      final updated = state.copyWith(report: {
        'totalHouseholds': 42,
        'activeCoverage': 35,
        'pendingClaims': 8,
      });
      expect(updated.report['totalHouseholds'], 42);
      expect(updated.report['activeCoverage'], 35);
    });

    test('copyWith updates isLoading', () {
      final state = OverviewState.initial();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
    });

    test('copyWith sets error', () {
      final state = OverviewState.initial();
      final withError = state.copyWith(error: 'Connection timeout');
      expect(withError.error, 'Connection timeout');
    });

    test('copyWith clears error', () {
      final state = OverviewState(
        report: const {}, isLoading: false, error: 'old error',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('Equatable: same states are equal', () {
      final a = OverviewState.initial();
      final b = OverviewState.initial();
      expect(a, equals(b));
    });
  });

  // ── IndigentState ──────────────────────────────────────────────────────────

  group('IndigentState — comprehensive', () {
    test('initial state has correct defaults', () {
      final state = IndigentState.initial();
      expect(state.applications, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isReviewing, isFalse);
      expect(state.error, isNull);
      expect(state.successMessage, isNull);
    });

    test('copyWith updates applications', () {
      final state = IndigentState.initial();
      final updated = state.copyWith(applications: [
        {'id': 'app-1', 'status': 'PENDING', 'applicantName': 'Kebede'},
      ]);
      expect(updated.applications.length, 1);
      expect(updated.applications.first['applicantName'], 'Kebede');
    });

    test('copyWith sets isReviewing', () {
      final state = IndigentState.initial();
      final reviewing = state.copyWith(isReviewing: true);
      expect(reviewing.isReviewing, isTrue);
    });

    test('copyWith clears error', () {
      final state = IndigentState(
        applications: const [], isLoading: false, isReviewing: false,
        error: 'Network error',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('copyWith clears success message', () {
      final state = IndigentState(
        applications: const [], isLoading: false, isReviewing: false,
        successMessage: 'Application APPROVED',
      );
      final cleared = state.copyWith(clearSuccess: true);
      expect(cleared.successMessage, isNull);
    });

    test('copyWith sets success message', () {
      final state = IndigentState.initial();
      final updated = state.copyWith(successMessage: 'Application APPROVED');
      expect(updated.successMessage, 'Application APPROVED');
    });

    test('Equatable: same states are equal', () {
      final a = IndigentState.initial();
      final b = IndigentState.initial();
      expect(a, equals(b));
    });

    test('Equatable: different states are not equal', () {
      final a = IndigentState.initial();
      final b = a.copyWith(isLoading: true);
      expect(a, isNot(equals(b)));
    });
  });
}
