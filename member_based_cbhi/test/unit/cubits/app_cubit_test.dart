// Unit tests for AppCubit — verifies state transitions without backend

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/cbhi_state.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}

void main() {
  late MockCbhiRepository mockRepository;
  late AppCubit cubit;

  setUp(() {
    mockRepository = MockCbhiRepository();
    cubit = AppCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('AppCubit', () {
    test('initial state is loading', () {
      expect(cubit.state.isLoading, isTrue);
      expect(cubit.state.snapshot, isNull);
    });

    test('load() fetches cached snapshot and updates state', () async {
      final mockSnapshot = CbhiSnapshot.empty();
      when(() => mockRepository.loadCachedSnapshot())
          .thenAnswer((_) async => mockSnapshot);

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.snapshot, equals(mockSnapshot));
      verify(() => mockRepository.loadCachedSnapshot()).called(1);
    });

    test('sync() updates snapshot from backend', () async {
      final initialSnapshot = CbhiSnapshot.empty();
      final syncedSnapshot = CbhiSnapshot(
        household: const {'householdCode': 'HH-001'},
        claims: const [],
        payments: const [],
        notifications: const [],
        digitalCards: const [],
        referrals: const [],
        familyMembers: const [],
        syncedAt: '2025-01-01T00:00:00.000Z',
      );

      when(() => mockRepository.loadCachedSnapshot())
          .thenAnswer((_) async => initialSnapshot);
      when(() => mockRepository.sync(any()))
          .thenAnswer((_) async => syncedSnapshot);

      await cubit.load();
      await cubit.sync();

      expect(cubit.state.isSyncing, isFalse);
      expect(cubit.state.snapshot?.householdCode, 'HH-001');
      verify(() => mockRepository.sync(any())).called(1);
    });

    test('setLocale() updates locale and persists', () {
      const newLocale = Locale('am');
      cubit.setLocale(newLocale);

      expect(cubit.state.locale, newLocale);
    });

    test('toggleDarkMode() switches theme mode', () {
      final initialMode = cubit.state.themeMode;
      cubit.toggleDarkMode();

      expect(cubit.state.themeMode, isNot(initialMode));
    });
  });
}
