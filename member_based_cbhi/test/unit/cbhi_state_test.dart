// Unit tests for AppCubit / AppState
// Tests state transitions without a running backend.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:member_based_cbhi/src/cbhi_state.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}

void main() {
  // SharedPreferences is used by AppCubit.load(), setLocale(), setThemeMode()
  // We must initialize the binding and set up a fake SharedPreferences instance.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('AppState', () {
    test('initial() has correct defaults', () {
      final state = AppState.initial();
      expect(state.isLoading, isTrue);
      expect(state.isSyncing, isFalse);
      expect(state.snapshot, isNull);
      expect(state.locale, const Locale('en'));
      expect(state.error, isNull);
      expect(state.themeMode, ThemeMode.system);
    });

    test('copyWith updates fields correctly', () {
      final state = AppState.initial();
      final snapshot = CbhiSnapshot.empty();
      final updated = state.copyWith(
        snapshot: snapshot,
        isLoading: false,
        locale: const Locale('am'),
        themeMode: ThemeMode.dark,
      );
      expect(updated.snapshot, snapshot);
      expect(updated.isLoading, isFalse);
      expect(updated.locale, const Locale('am'));
      expect(updated.themeMode, ThemeMode.dark);
    });

    test('copyWith clears error when error is null', () {
      final state = AppState.initial().copyWith(error: 'some error');
      expect(state.error, 'some error');
      final cleared = state.copyWith(isLoading: false);
      // error is cleared because copyWith passes null for error
      expect(cleared.error, isNull);
    });

    test('isDarkMode returns true only for ThemeMode.dark', () {
      final dark = AppState.initial().copyWith(themeMode: ThemeMode.dark);
      final light = AppState.initial().copyWith(themeMode: ThemeMode.light);
      final system = AppState.initial().copyWith(themeMode: ThemeMode.system);
      expect(dark.isDarkMode, isTrue);
      expect(light.isDarkMode, isFalse);
      expect(system.isDarkMode, isFalse);
    });

    test('props equality works correctly', () {
      final a = AppState.initial();
      final b = AppState.initial();
      expect(a, equals(b));
    });
  });

  group('AppCubit', () {
    late MockCbhiRepository repository;
    late AppCubit cubit;

    setUp(() {
      repository = MockCbhiRepository();
      cubit = AppCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is AppState.initial()', () {
      expect(cubit.state, AppState.initial());
    });

    test('load() emits loaded state with snapshot on success', () async {
      final snapshot = CbhiSnapshot.empty();
      when(() => repository.loadCachedSnapshot())
          .thenAnswer((_) async => snapshot);

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.snapshot, snapshot);
      expect(cubit.state.error, isNull);
    });

    test('load() emits error state on exception', () async {
      when(() => repository.loadCachedSnapshot())
          .thenThrow(Exception('DB error'));

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.error, contains('DB error'));
    });

    test('sync() emits syncing then synced state on success', () async {
      final snapshot = CbhiSnapshot.empty();
      when(() => repository.loadCachedSnapshot())
          .thenAnswer((_) async => snapshot);
      when(() => repository.sync(any()))
          .thenAnswer((_) async => snapshot);

      await cubit.load();
      await cubit.sync();

      expect(cubit.state.isSyncing, isFalse);
      expect(cubit.state.snapshot, snapshot);
    });

    test('sync() emits error on exception', () async {
      final snapshot = CbhiSnapshot.empty();
      when(() => repository.loadCachedSnapshot())
          .thenAnswer((_) async => snapshot);
      when(() => repository.sync(any()))
          .thenThrow(Exception('Network error'));

      await cubit.load();
      await cubit.sync();

      expect(cubit.state.isSyncing, isFalse);
      expect(cubit.state.error, isNotNull);
    });

    test('setLocale() updates locale in state', () {
      cubit.setLocale(const Locale('am'));
      expect(cubit.state.locale, const Locale('am'));
    });

    test('setThemeMode() updates themeMode in state', () {
      cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state.themeMode, ThemeMode.dark);
    });

    test('toggleDarkMode() switches between dark and light', () {
      cubit.setThemeMode(ThemeMode.light);
      cubit.toggleDarkMode();
      expect(cubit.state.themeMode, ThemeMode.dark);
      cubit.toggleDarkMode();
      expect(cubit.state.themeMode, ThemeMode.light);
    });
  });
}
