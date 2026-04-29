// Unit tests for ClaimsCubit — verifies state transitions and filtering logic

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_admin_desktop/src/blocs/claims_cubit.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockRepository;
  late ClaimsCubit cubit;

  setUp(() {
    mockRepository = MockAdminRepository();
    cubit = ClaimsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ClaimsCubit', () {
    test('initial state has correct defaults', () {
      expect(cubit.state.claims, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isReviewing, isFalse);
      expect(cubit.state.filter, 'ALL');
      expect(cubit.state.searchQuery, '');
      expect(cubit.state.error, isNull);
    });

    test('load() fetches claims and updates state', () async {
      final mockClaims = [
        {'id': 'c1', 'claimNumber': 'CLM-001', 'status': 'SUBMITTED', 'beneficiaryName': 'Alice'},
        {'id': 'c2', 'claimNumber': 'CLM-002', 'status': 'APPROVED', 'beneficiaryName': 'Bob'},
      ];
      when(() => mockRepository.getClaims()).thenAnswer((_) async => mockClaims);

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.claims.length, 2);
      verify(() => mockRepository.getClaims()).called(1);
    });

    test('load() sets error on failure', () async {
      when(() => mockRepository.getClaims())
          .thenThrow(Exception('Network error'));

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNotNull);
    });

    test('setFilter() updates filter', () {
      cubit.setFilter('APPROVED');
      expect(cubit.state.filter, 'APPROVED');
    });

    test('setSearchQuery() updates search query', () {
      cubit.setSearchQuery('CLM-001');
      expect(cubit.state.searchQuery, 'CLM-001');
    });

    test('reviewClaim() calls repository and reloads', () async {
      when(() => mockRepository.getClaims()).thenAnswer((_) async => []);
      when(() => mockRepository.reviewClaim(
            claimId: any(named: 'claimId'),
            status: any(named: 'status'),
            approvedAmount: any(named: 'approvedAmount'),
            decisionNote: any(named: 'decisionNote'),
          )).thenAnswer((_) async => {'success': true});

      await cubit.reviewClaim(
        claimId: 'c1',
        status: 'APPROVED',
        approvedAmount: 300.0,
        decisionNote: 'Approved',
      );

      expect(cubit.state.isReviewing, isFalse);
      verify(() => mockRepository.reviewClaim(
            claimId: 'c1',
            status: 'APPROVED',
            approvedAmount: 300.0,
            decisionNote: 'Approved',
          )).called(1);
    });
  });

  group('ClaimsState filtering', () {
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
}
