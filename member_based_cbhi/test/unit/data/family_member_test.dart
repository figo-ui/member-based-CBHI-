// Unit tests for FamilyMember — fromJson parsing and boolean fields.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';

void main() {
  group('FamilyMember', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'fm-001',
        'membershipId': 'MEM-001',
        'fullName': 'Chaltu Bekele',
        'coverageStatus': 'ACTIVE',
        'isPrimaryHolder': true,
        'isEligible': true,
        'gender': 'Female',
        'dateOfBirth': '1990-05-15',
        'relationshipToHouseholdHead': 'SPOUSE',
        'identityType': 'NATIONAL_ID',
        'identityNumber': 'ETH-123456',
        'phoneNumber': '+251911111111',
        'canLoginIndependently': true,
      };
      final member = FamilyMember.fromJson(json);
      expect(member.id, 'fm-001');
      expect(member.membershipId, 'MEM-001');
      expect(member.fullName, 'Chaltu Bekele');
      expect(member.coverageStatus, 'ACTIVE');
      expect(member.isPrimaryHolder, isTrue);
      expect(member.isEligible, isTrue);
      expect(member.gender, 'Female');
      expect(member.dateOfBirth, '1990-05-15');
      expect(member.relationshipToHouseholdHead, 'SPOUSE');
      expect(member.canLoginIndependently, isTrue);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'fm-002',
        'membershipId': 'MEM-002',
        'fullName': 'Biyansa Bekele',
        'coverageStatus': 'ACTIVE',
        'isPrimaryHolder': false,
        'isEligible': true,
      };
      final member = FamilyMember.fromJson(json);
      expect(member.gender, isNull);
      expect(member.dateOfBirth, isNull);
      expect(member.phoneNumber, isNull);
      expect(member.canLoginIndependently, isFalse);
    });

    test('fromJson defaults displayName to Member when missing', () {
      final member = FamilyMember.fromJson({});
      expect(member.fullName, 'Member');
      expect(member.coverageStatus, 'UNKNOWN');
    });

    test('isPrimaryHolder defaults to false', () {
      final member = FamilyMember.fromJson({
        'isPrimaryHolder': null,
      });
      expect(member.isPrimaryHolder, isFalse);
    });

    test('isEligible defaults to true when not explicitly false', () {
      final member = FamilyMember.fromJson({});
      expect(member.isEligible, isTrue);
    });

    test('isEligible returns false when explicitly false', () {
      final member = FamilyMember.fromJson({'isEligible': false});
      expect(member.isEligible, isFalse);
    });

    test('toJson produces valid JSON map', () {
      const member = FamilyMember(
        id: 'fm-json', membershipId: 'MEM-J',
        fullName: 'JSON Test', coverageStatus: 'ACTIVE',
        isPrimaryHolder: true, isEligible: true, gender: 'Male',
      );
      final json = member.toJson();
      expect(json['id'], 'fm-json');
      expect(json['fullName'], 'JSON Test');
      expect(json['isPrimaryHolder'], isTrue);
      expect(json['gender'], 'Male');
    });
  });
}
