// Unit tests for AuthSession — expiry logic, serialization.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';

void main() {
  group('AuthSession', () {
    test('fromJson parses correctly', () {
      final json = {
        'accessToken': 'abc123',
        'tokenType': 'Bearer',
        'expiresAt': '2030-01-01T00:00:00Z',
        'user': {'id': 'u1', 'displayName': 'Test'},
        'refreshToken': 'ref-tok',
        'refreshTokenExpiresAt': '2030-06-01T00:00:00Z',
      };
      final session = AuthSession.fromJson(json);
      expect(session.accessToken, 'abc123');
      expect(session.tokenType, 'Bearer');
      expect(session.user.id, 'u1');
      expect(session.refreshToken, 'ref-tok');
    });

    test('isExpired returns false for future expiry', () {
      final session = AuthSession(
        accessToken: 'tok',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        user: const AppUserProfile(id: 'u1', displayName: 'Test'),
      );
      expect(session.isExpired, isFalse);
    });

    test('isExpired returns true for past expiry', () {
      final session = AuthSession(
        accessToken: 'tok',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        user: const AppUserProfile(id: 'u1', displayName: 'Test'),
      );
      expect(session.isExpired, isTrue);
    });

    test('isExpired returns true when within 5-minute buffer', () {
      final session = AuthSession(
        accessToken: 'tok',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(minutes: 3)).toIso8601String(),
        user: const AppUserProfile(id: 'u1', displayName: 'Test'),
      );
      expect(session.isExpired, isTrue);
    });

    test('refreshTokenExpired returns true when refreshToken is null', () {
      const session = AuthSession(
        accessToken: 'tok', tokenType: 'Bearer',
        expiresAt: '2030-01-01T00:00:00Z',
        user: AppUserProfile(id: 'u1', displayName: 'Test'),
      );
      expect(session.refreshTokenExpired, isTrue);
    });

    test('refreshTokenExpired returns false for future refresh expiry', () {
      final session = AuthSession(
        accessToken: 'tok', tokenType: 'Bearer',
        expiresAt: '2030-01-01T00:00:00Z',
        user: const AppUserProfile(id: 'u1', displayName: 'Test'),
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      );
      expect(session.refreshTokenExpired, isFalse);
    });

    test('toJson → fromJson round-trip preserves data', () {
      const original = AuthSession(
        accessToken: 'round-trip-tok', tokenType: 'Bearer',
        expiresAt: '2030-01-01T00:00:00Z',
        user: AppUserProfile(id: 'rt-user', displayName: 'RT User'),
        refreshToken: 'rt-refresh',
      );
      final restored = AuthSession.fromJson(original.toJson());
      expect(restored.accessToken, original.accessToken);
      expect(restored.user.id, original.user.id);
      expect(restored.refreshToken, original.refreshToken);
    });
  });
}
