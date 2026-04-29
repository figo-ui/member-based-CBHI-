// Unit tests for OverviewCubit — verifies state transitions

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbhi_admin_desktop/src/blocs/overview_cubit.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockRepository;
  late OverviewCubit cubit;

  setUp(() {
    mockRepository = MockAdminRepository();
    cubit = OverviewCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('OverviewCubit', () {
    test('initial state has correct defaults', () {
      expect(cubit.state.report, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
    });

    test('load() fetches report and updates state', () async {
      final mockReport = {
        'totalHouseholds': 100,
        'activeCoverages': 80,
        'pendingClaims': 15,
      };
      when(() => mockRepository.getSummaryReport(
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => mockReport);

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.report['totalHouseholds'], 100);
      verify(() => mockRepository.getSummaryReport(
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).called(1);
    });

    test('load() sets error on failure', () async {
      when(() => mockRepository.getSummaryReport(
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenThrow(Exception('Server error'));

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNotNull);
    });

    test('load() with date range passes params to repository', () async {
      when(() => mockRepository.getSummaryReport(
            from: '2025-01-01',
            to: '2025-12-31',
          )).thenAnswer((_) async => {'totalHouseholds': 50});

      await cubit.load(from: '2025-01-01', to: '2025-12-31');

      verify(() => mockRepository.getSummaryReport(
            from: '2025-01-01',
            to: '2025-12-31',
          )).called(1);
    });
  });

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

    test('copyWith clears error', () {
      final state = OverviewState.initial().copyWith(error: 'Some error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });
  });
}
