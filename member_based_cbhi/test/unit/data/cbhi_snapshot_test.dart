// Unit tests for CbhiSnapshot — fromJson, computed properties, copyWith.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';

void main() {
  group('CbhiSnapshot', () {
    test('empty() creates snapshot with default values', () {
      final snap = CbhiSnapshot.empty();
      expect(snap.household, isEmpty);
      expect(snap.claims, isEmpty);
      expect(snap.payments, isEmpty);
      expect(snap.notifications, isEmpty);
      expect(snap.digitalCards, isEmpty);
      expect(snap.referrals, isEmpty);
      expect(snap.familyMembers, isEmpty);
      expect(snap.syncedAt, '');
      expect(snap.coverage, isNull);
      expect(snap.card, isNull);
    });

    test('householdCode extracts from household map', () {
      const snap = CbhiSnapshot(
        household: {'householdCode': 'HH-001'},
        claims: [], payments: [], notifications: [],
        digitalCards: [], referrals: [], familyMembers: [],
        syncedAt: '2025-01-01',
      );
      expect(snap.householdCode, 'HH-001');
    });

    test('householdCode returns empty string when missing', () {
      final snap = CbhiSnapshot.empty();
      expect(snap.householdCode, '');
    });

    test('headName extracts from household headUser', () {
      const snap = CbhiSnapshot(
        household: {
          'headUser': {
            'firstName': 'Abebe',
            'middleName': 'Tadesse',
            'lastName': 'Bekele',
          }
        },
        claims: [], payments: [], notifications: [],
        digitalCards: [], referrals: [], familyMembers: [],
        syncedAt: '2025-01-01',
      );
      expect(snap.headName, 'Abebe Tadesse Bekele');
    });

    test('headName returns Member when headUser is missing', () {
      final snap = CbhiSnapshot.empty();
      expect(snap.headName, 'Member');
    });

    test('coverageStatus reads from coverage map first', () {
      const snap = CbhiSnapshot(
        household: {'coverageStatus': 'EXPIRED'},
        coverage: {'status': 'ACTIVE'},
        claims: [], payments: [], notifications: [],
        digitalCards: [], referrals: [], familyMembers: [],
        syncedAt: '2025-01-01',
      );
      expect(snap.coverageStatus, 'ACTIVE');
    });

    test('coverageStatus falls back to household', () {
      const snap = CbhiSnapshot(
        household: {'coverageStatus': 'EXPIRED'},
        claims: [], payments: [], notifications: [],
        digitalCards: [], referrals: [], familyMembers: [],
        syncedAt: '2025-01-01',
      );
      expect(snap.coverageStatus, 'EXPIRED');
    });

    test('isPendingSync returns true for LOCAL- prefixed code', () {
      const snap = CbhiSnapshot(
        household: {'householdCode': 'LOCAL-12345'},
        claims: [], payments: [], notifications: [],
        digitalCards: [], referrals: [], familyMembers: [],
        syncedAt: '2025-01-01',
      );
      expect(snap.isPendingSync, isTrue);
    });

    test('hasLiveCard returns false when no card token', () {
      final snap = CbhiSnapshot.empty();
      expect(snap.hasLiveCard, isFalse);
    });

    test('hasLiveCard returns true when card has token', () {
      const snap = CbhiSnapshot(
        household: {},
        card: {'token': 'live-token-123'},
        claims: [], payments: [], notifications: [],
        digitalCards: [], referrals: [], familyMembers: [],
        syncedAt: '2025-01-01',
      );
      expect(snap.hasLiveCard, isTrue);
    });

    test('fromJson parses nested structures', () {
      final json = {
        'household': {'householdCode': 'HH-JSON'},
        'coverage': {'status': 'ACTIVE', 'premiumAmount': 500},
        'claims': [
          {'id': 'c1', 'status': 'SUBMITTED'}
        ],
        'payments': [
          {'id': 'p1', 'amount': '100'}
        ],
        'notifications': [],
        'digitalCards': [],
        'referrals': [],
        'familyMembers': [
          {
            'id': 'fm1', 'membershipId': 'M1',
            'fullName': 'Test', 'coverageStatus': 'ACTIVE',
            'isPrimaryHolder': true, 'isEligible': true,
          }
        ],
        'syncedAt': '2025-06-15T00:00:00Z',
      };
      final snap = CbhiSnapshot.fromJson(json);
      expect(snap.householdCode, 'HH-JSON');
      expect(snap.coverageStatus, 'ACTIVE');
      expect(snap.claims.length, 1);
      expect(snap.payments.length, 1);
      expect(snap.familyMembers.length, 1);
      expect(snap.familyMembers.first.fullName, 'Test');
    });

    test('copyWith updates specific fields', () {
      final snap = CbhiSnapshot.empty();
      final updated = snap.copyWith(
        household: {'householdCode': 'HH-NEW'},
        syncedAt: '2025-12-01',
      );
      expect(updated.householdCode, 'HH-NEW');
      expect(updated.syncedAt, '2025-12-01');
      expect(updated.claims, isEmpty); // unchanged
    });

    test('premiumAmount reads from coverage', () {
      const snap = CbhiSnapshot(
        household: {},
        coverage: {'premiumAmount': 1200},
        claims: [], payments: [], notifications: [],
        digitalCards: [], referrals: [], familyMembers: [],
        syncedAt: '',
      );
      expect(snap.premiumAmount, 1200.0);
    });

    test('premiumAmount returns 0 when coverage is null', () {
      final snap = CbhiSnapshot.empty();
      expect(snap.premiumAmount, 0.0);
    });
  });
}
