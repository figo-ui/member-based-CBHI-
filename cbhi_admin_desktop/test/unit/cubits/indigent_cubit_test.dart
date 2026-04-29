// Unit tests for IndigentCubit — verifies state transitions

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_admin_desktop/src/blocs/indigent_cubit.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockRepository;
  late IndigentCubit cubit;

  setUp(() {
    mockRepository = MockAdminRepository();
    cubit = IndigentCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('IndigentCubit', () {
    test('initial state has correct defaults', () {
      expect(cubit.state.applications, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isReviewing, isFalse);
    });

    test('load() fetches applications and updates state', () async {
      final mockApps = [
        {'id': 'app-1', 'status': 'PENDING', 'householdCode': 'HH-001'},
        {'id': 'app-2', 'status': 'PENDING', 'householdCode': 'HH-002'},
      ];
      when(() => mockRepository.getPendingIndigent())
          .thenAnswer((_) async => mockApps);

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.applications.length, 2);
      verify(() => mockRepository.getPendingIndigent()).called(1);
    });

    test('load() sets error on failure', () async {
      when(() => mockRepository.getPendingIndigent())
          .thenThrow(Exception('Network error'));

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNotNull);
    });

    test('review() calls repository and reloads', () async {
      when(() => mockRepository.getPendingIndigent())
          .thenAnswer((_) async => []);
      when(() => mockRepository.reviewIndigent(
            applicationId: any(named: 'applicationId'),
            status: any(named: 'status'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await cubit.review(
        applicationId: 'app-1',
        status: 'APPROVED',
        reason: 'Meets criteria',
      );

      expect(cubit.state.isReviewing, isFalse);
      verify(() => mockRepository.reviewIndigent(
            applicationId: 'app-1',
            status: 'APPROVED',
            reason: 'Meets criteria',
          )).called(1);
    });
  });

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
