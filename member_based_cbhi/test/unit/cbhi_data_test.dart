// Unit tests for CbhiSnapshot model (fromJson / toJson / helpers)
// Tests model logic without HTTP calls.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';

void main() {
  group('CbhiSnapshot', () {
    test('empty() returns a valid empty snapshot', () {
      final s = CbhiSnapshot.empty();
      expect(s.household, isEmpty);
      expect(s.claims, isEmpty);
      expect(s.payments, isEmpty);
      expect(s.familyMembers, isEmpty);
      expect(s.coverageStatus, 'UNKNOWN');
      expect(s.householdCode, '');
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'household': {'householdCode': 'HH-001', 'coverageStatus': 'ACTIVE'},
        'coverage': {'status': 'ACTIVE', 'premiumAmount': 720.0, 'paidAmount': 720.0},
        'card': {'token': 'tok_abc123'},
        'claims': [
          {'id': 'clm-1', 'status': 'APPROVED'},
        ],
        'payments': [
          {'id': 'pay-1', 'amount': '720.00'},
        ],
        'notifications': [],
        'digitalCards': [
          {'memberId': 'ben-1', 'token': 'tok_abc123'},
        ],
        'referrals': [],
        'familyMembers': [
          {
            'id': 'ben-1',
            'membershipId': 'MEM-001',
            'fullName': 'Alemayehu Bekele',
            'coverageStatus': 'ACTIVE',
            'isPrimaryHolder': true,
            'isEligible': true,
          },
        ],
        'syncedAt': '2025-01-01T00:00:00.000Z',
      };

      final snapshot = CbhiSnapshot.fromJson(json);
      expect(snapshot.householdCode, 'HH-001');
      expect(snapshot.coverageStatus, 'ACTIVE');
      expect(snapshot.premiumAmount, 720.0);
      expect(snapshot.paidAmount, 720.0);
      expect(snapshot.cardToken, 'tok_abc123');
      expect(snapshot.claims.length, 1);
      expect(snapshot.payments.length, 1);
      expect(snapshot.familyMembers.length, 1);
      expect(snapshot.familyMembers.first.fullName, 'Alemayehu Bekele');
      expect(snapshot.hasLiveCard, isTrue);
    });

    test('toJson / fromJson round-trip preserves data', () {
      final original = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-999'},
        'coverage': {'status': 'EXPIRED'},
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '2025-06-01T00:00:00.000Z',
      });

      final restored = CbhiSnapshot.fromJson(original.toJson());
      expect(restored.householdCode, original.householdCode);
      expect(restored.coverageStatus, original.coverageStatus);
      expect(restored.syncedAt, original.syncedAt);
    });

    test('coverageStatus falls back to household field when coverage is null', () {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'HH-002', 'coverageStatus': 'PENDING_RENEWAL'},
        'coverage': null,
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '',
      });
      expect(snapshot.coverageStatus, 'PENDING_RENEWAL');
    });

    test('hasLiveCard is false when cardToken is empty', () {
      final snapshot = CbhiSnapshot.empty();
      expect(snapshot.hasLiveCard, isFalse);
    });

    test('isPendingSync is true for LOCAL- household codes', () {
      final snapshot = CbhiSnapshot.fromJson({
        'household': {'householdCode': 'LOCAL-abc123'},
        'coverage': null,
        'card': null,
        'claims': [],
        'payments': [],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [],
        'syncedAt': '',
      });
      expect(snapshot.isPendingSync, isTrue);
    });

    test('copyWith updates only specified fields', () {
      final original = CbhiSnapshot.empty();
      final updated = original.copyWith(
        household: {'householdCode': 'HH-NEW'},
        syncedAt: '2025-12-01T00:00:00.000Z',
      );
      expect(updated.householdCode, 'HH-NEW');
      expect(updated.syncedAt, '2025-12-01T00:00:00.000Z');
      expect(updated.claims, isEmpty);
    });
  });

  group('FamilyMember', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'ben-1',
        'membershipId': 'MEM-001',
        'fullName': 'Tigist Haile',
        'coverageStatus': 'ACTIVE',
        'isPrimaryHolder': false,
        'isEligible': true,
        'gender': 'FEMALE',
        'dateOfBirth': '1990-05-15',
        'relationshipToHouseholdHead': 'SPOUSE',
      };
      final member = FamilyMember.fromJson(json);
      expect(member.id, 'ben-1');
      expect(member.fullName, 'Tigist Haile');
      expect(member.isPrimaryHolder, isFalse);
      expect(member.isEligible, isTrue);
      expect(member.gender, 'FEMALE');
    });

    test('toJson round-trip preserves data', () {
      final json = {
        'id': 'ben-2',
        'membershipId': 'MEM-002',
        'fullName': 'Dawit Tadesse',
        'coverageStatus': 'EXPIRED',
        'isPrimaryHolder': true,
        'isEligible': false,
      };
      final member = FamilyMember.fromJson(json);
      final restored = FamilyMember.fromJson(member.toJson());
      expect(restored.id, member.id);
      expect(restored.fullName, member.fullName);
      expect(restored.isPrimaryHolder, member.isPrimaryHolder);
    });

    test('handles null optional fields gracefully', () {
      final json = {
        'id': 'ben-3',
        'membershipId': '',
        'fullName': 'Unknown',
        'coverageStatus': 'UNKNOWN',
        'isPrimaryHolder': false,
        'isEligible': true,
      };
      final member = FamilyMember.fromJson(json);
      expect(member.gender, isNull);
      expect(member.dateOfBirth, isNull);
      expect(member.photoPath, isNull);
    });
  });

  group('AppUserProfile', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'usr-1',
        'displayName': 'Alemayehu Bekele',
        'firstName': 'Alemayehu',
        'lastName': 'Bekele',
        'phoneNumber': '+251912345678',
        'role': 'HOUSEHOLD_HEAD',
        'householdCode': 'HH-001',
      };
      final profile = AppUserProfile.fromJson(json);
      expect(profile.id, 'usr-1');
      expect(profile.displayName, 'Alemayehu Bekele');
      expect(profile.role, 'HOUSEHOLD_HEAD');
    });

    test('toJson round-trip preserves data', () {
      final json = {
        'id': 'usr-2',
        'displayName': 'Test User',
        'firstName': 'Test',
        'lastName': 'User',
        'phoneNumber': '+251911111111',
        'role': 'BENEFICIARY',
      };
      final profile = AppUserProfile.fromJson(json);
      final restored = AppUserProfile.fromJson(profile.toJson());
      expect(restored.id, profile.id);
      expect(restored.displayName, profile.displayName);
    });
  });
}
