// Unit tests for AppState — initial state, isDarkMode, copyWith.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/cbhi_state.dart';

void main() {
  group('AppState', () {
    test('initial() has correct defaults', () {
      final state = AppState.initial();
      expect(state.snapshot, isNull);
      expect(state.locale, const Locale('en'));
      expect(state.isLoading, isTrue);
      expect(state.isSyncing, isFalse);
      expect(state.error, isNull);
      expect(state.themeMode, ThemeMode.system);
    });

    test('isDarkMode returns true when themeMode is dark', () {
      final state = AppState.initial().copyWith(themeMode: ThemeMode.dark);
      expect(state.isDarkMode, isTrue);
    });

    test('isDarkMode returns false when themeMode is light', () {
      final state = AppState.initial().copyWith(themeMode: ThemeMode.light);
      expect(state.isDarkMode, isFalse);
    });

    test('isDarkMode returns false when themeMode is system', () {
      final state = AppState.initial();
      expect(state.isDarkMode, isFalse);
    });

    test('copyWith updates locale', () {
      final state = AppState.initial();
      final updated = state.copyWith(locale: const Locale('om'));
      expect(updated.locale, const Locale('om'));
      expect(updated.isLoading, isTrue); // preserved
    });

    test('copyWith updates isLoading', () {
      final state = AppState.initial();
      final updated = state.copyWith(isLoading: false);
      expect(updated.isLoading, isFalse);
    });

    test('copyWith sets error', () {
      final state = AppState.initial();
      final withError = state.copyWith(error: 'Network fail');
      expect(withError.error, 'Network fail');
    });

    test('copyWith clears error when set to null', () {
      final state = AppState.initial().copyWith(error: 'err');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('Equatable props work correctly', () {
      final a = AppState.initial();
      final b = AppState.initial();
      expect(a, equals(b));

      final c = a.copyWith(isLoading: false);
      expect(a, isNot(equals(c)));
    });
  });
}
