// Unit tests for AppUserProfile — serialization and default values.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';

void main() {
  group('AppUserProfile', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'user-001',
        'displayName': 'Abebe Bekele',
        'firstName': 'Abebe',
        'middleName': 'Tadesse',
        'lastName': 'Bekele',
        'phoneNumber': '+251911234567',
        'email': 'abebe@example.com',
        'role': 'HOUSEHOLD_HEAD',
        'preferredLanguage': 'om',
        'householdCode': 'HH-ORO-001',
        'beneficiaryId': 'ben-001',
        'membershipId': 'mem-001',
        'lastLoginAt': '2025-06-15T10:00:00Z',
      };
      final profile = AppUserProfile.fromJson(json);
      expect(profile.id, 'user-001');
      expect(profile.displayName, 'Abebe Bekele');
      expect(profile.firstName, 'Abebe');
      expect(profile.role, 'HOUSEHOLD_HEAD');
      expect(profile.householdCode, 'HH-ORO-001');
    });

    test('fromJson handles empty JSON with defaults', () {
      final profile = AppUserProfile.fromJson({});
      expect(profile.id, '');
      expect(profile.displayName, 'Member');
      expect(profile.firstName, isNull);
      expect(profile.role, isNull);
    });

    test('toJson produces valid JSON map', () {
      const profile = AppUserProfile(
        id: 'user-002', displayName: 'Test User',
        firstName: 'Test', lastName: 'User', role: 'BENEFICIARY',
      );
      final json = profile.toJson();
      expect(json['id'], 'user-002');
      expect(json['displayName'], 'Test User');
      expect(json['role'], 'BENEFICIARY');
    });

    test('toJson → fromJson round-trip preserves data', () {
      const original = AppUserProfile(
        id: 'rt-001', displayName: 'Round Trip',
        firstName: 'Round', lastName: 'Trip',
        phoneNumber: '+251900000000', email: 'rt@test.com',
        role: 'HOUSEHOLD_HEAD', householdCode: 'HH-RT-001',
      );
      final restored = AppUserProfile.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.role, original.role);
      expect(restored.householdCode, original.householdCode);
    });
  });
}
