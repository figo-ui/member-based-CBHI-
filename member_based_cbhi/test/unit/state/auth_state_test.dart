// Unit tests for AuthState — initial state, computed getters, copyWith.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/auth/auth_state.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';

void main() {
  group('AuthState', () {
    test('initial() has correct defaults', () {
      final state = AuthState.initial();
      expect(state.status, AuthStatus.checking);
      expect(state.isBusy, isFalse);
      expect(state.session, isNull);
      expect(state.error, isNull);
    });

    test('isAuthenticated returns true when authenticated', () {
      const state = AuthState(
        status: AuthStatus.authenticated, isBusy: false,
      );
      expect(state.isAuthenticated, isTrue);
      expect(state.isGuest, isFalse);
    });

    test('isGuest returns true when guest', () {
      const state = AuthState(status: AuthStatus.guest, isBusy: false);
      expect(state.isGuest, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('isFamilyMember checks BENEFICIARY role', () {
      final session = AuthSession(
        accessToken: 't', tokenType: 'Bearer', expiresAt: '2030-01-01',
        user: const AppUserProfile(
          id: 'u1', displayName: 'Ben', role: 'BENEFICIARY',
        ),
      );
      final state = AuthState(
        status: AuthStatus.authenticated, isBusy: false, session: session,
      );
      expect(state.isFamilyMember, isTrue);
      expect(state.isHouseholdHead, isFalse);
    });

    test('isHouseholdHead checks HOUSEHOLD_HEAD role', () {
      final session = AuthSession(
        accessToken: 't', tokenType: 'Bearer', expiresAt: '2030-01-01',
        user: const AppUserProfile(
          id: 'u1', displayName: 'Head', role: 'HOUSEHOLD_HEAD',
        ),
      );
      final state = AuthState(
        status: AuthStatus.authenticated, isBusy: false, session: session,
      );
      expect(state.isHouseholdHead, isTrue);
      expect(state.isFamilyMember, isFalse);
    });

    test('copyWith updates status and preserves other fields', () {
      final state = AuthState.initial();
      final updated = state.copyWith(
        status: AuthStatus.unauthenticated,
      );
      expect(updated.status, AuthStatus.unauthenticated);
      expect(updated.isBusy, isFalse); // preserved
    });

    test('copyWith clearError removes error', () {
      const state = AuthState(
        status: AuthStatus.unauthenticated,
        isBusy: false,
        error: 'Some error',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('copyWith clearSession removes session', () {
      final session = AuthSession(
        accessToken: 't', tokenType: 'Bearer', expiresAt: '2030-01-01',
        user: const AppUserProfile(id: 'u1', displayName: 'Test'),
      );
      final state = AuthState(
        status: AuthStatus.authenticated,
        isBusy: false,
        session: session,
      );
      final cleared = state.copyWith(clearSession: true);
      expect(cleared.session, isNull);
    });

    test('Equatable props work correctly', () {
      final a = AuthState.initial();
      final b = AuthState.initial();
      expect(a, equals(b));

      final c = a.copyWith(status: AuthStatus.authenticated);
      expect(a, isNot(equals(c)));
    });
  });
}
