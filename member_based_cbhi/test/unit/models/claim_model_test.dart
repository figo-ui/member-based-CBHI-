// Unit tests for ClaimModel — serialization, computed properties, edge cases.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/models/claim_model.dart';

void main() {
  group('ClaimModel', () {
    // ── fromJson ────────────────────────────────────────────────────────────

    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'clm-100',
        'claimNumber': 'CLM-2025-0001',
        'status': 'APPROVED',
        'claimedAmount': 1500.0,
        'approvedAmount': 1200.0,
        'serviceDate': '2025-06-15T10:30:00.000Z',
        'submittedAt': '2025-06-16T08:00:00.000Z',
        'reviewedAt': '2025-06-18T14:00:00.000Z',
        'facilityName': 'Maya City Health Center',
        'householdCode': 'HH-ETH-001',
        'beneficiaryName': 'Abebe Bekele',
        'decisionNote': 'Approved after document review',
      };

      final model = ClaimModel.fromJson(json);

      expect(model.id, 'clm-100');
      expect(model.claimNumber, 'CLM-2025-0001');
      expect(model.status, 'APPROVED');
      expect(model.claimedAmount, 1500.0);
      expect(model.approvedAmount, 1200.0);
      expect(model.serviceDate, '2025-06-15T10:30:00.000Z');
      expect(model.submittedAt, '2025-06-16T08:00:00.000Z');
      expect(model.reviewedAt, '2025-06-18T14:00:00.000Z');
      expect(model.facilityName, 'Maya City Health Center');
      expect(model.householdCode, 'HH-ETH-001');
      expect(model.beneficiaryName, 'Abebe Bekele');
      expect(model.decisionNote, 'Approved after document review');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'clm-101',
        'claimNumber': 'CLM-2025-0002',
        'status': 'SUBMITTED',
        'claimedAmount': 800.0,
      };

      final model = ClaimModel.fromJson(json);

      expect(model.approvedAmount, isNull);
      expect(model.serviceDate, isNull);
      expect(model.submittedAt, isNull);
      expect(model.reviewedAt, isNull);
      expect(model.facilityName, isNull);
      expect(model.householdCode, isNull);
      expect(model.beneficiaryName, isNull);
      expect(model.decisionNote, isNull);
    });

    // ── Status computed properties ──────────────────────────────────────────

    test('isApproved returns true for APPROVED status', () {
      const model = ClaimModel(
        id: '1', claimNumber: 'C-1', status: 'APPROVED', claimedAmount: 100,
      );
      expect(model.isApproved, isTrue);
      expect(model.isRejected, isFalse);
      expect(model.isPending, isFalse);
    });

    test('isApproved returns true for PAID status', () {
      const model = ClaimModel(
        id: '2', claimNumber: 'C-2', status: 'PAID', claimedAmount: 200,
      );
      expect(model.isApproved, isTrue);
    });

    test('isRejected returns true for REJECTED status', () {
      const model = ClaimModel(
        id: '3', claimNumber: 'C-3', status: 'REJECTED', claimedAmount: 300,
      );
      expect(model.isRejected, isTrue);
      expect(model.isApproved, isFalse);
      expect(model.isPending, isFalse);
    });

    test('isPending returns true for SUBMITTED status', () {
      const model = ClaimModel(
        id: '4', claimNumber: 'C-4', status: 'SUBMITTED', claimedAmount: 400,
      );
      expect(model.isPending, isTrue);
    });

    test('isPending returns true for UNDER_REVIEW status', () {
      const model = ClaimModel(
        id: '5', claimNumber: 'C-5', status: 'UNDER_REVIEW', claimedAmount: 500,
      );
      expect(model.isPending, isTrue);
    });

    test('unknown status returns false for all computed properties', () {
      const model = ClaimModel(
        id: '6', claimNumber: 'C-6', status: 'UNKNOWN', claimedAmount: 600,
      );
      expect(model.isApproved, isFalse);
      expect(model.isRejected, isFalse);
      expect(model.isPending, isFalse);
    });

    // ── serviceDateFormatted ────────────────────────────────────────────────

    test('serviceDateFormatted extracts date portion from ISO string', () {
      const model = ClaimModel(
        id: '7', claimNumber: 'C-7', status: 'APPROVED', claimedAmount: 100,
        serviceDate: '2025-04-10T00:00:00.000Z',
      );
      expect(model.serviceDateFormatted, '2025-04-10');
    });

    test('serviceDateFormatted returns empty string when serviceDate is null', () {
      const model = ClaimModel(
        id: '8', claimNumber: 'C-8', status: 'SUBMITTED', claimedAmount: 100,
      );
      expect(model.serviceDateFormatted, '');
    });

    test('serviceDateFormatted handles date-only string', () {
      const model = ClaimModel(
        id: '9', claimNumber: 'C-9', status: 'SUBMITTED', claimedAmount: 100,
        serviceDate: '2025-12-25',
      );
      expect(model.serviceDateFormatted, '2025-12-25');
    });

    // ── toJson / round-trip ─────────────────────────────────────────────────

    test('toJson produces valid JSON map', () {
      const model = ClaimModel(
        id: 'rt-1',
        claimNumber: 'CLM-RT',
        status: 'REJECTED',
        claimedAmount: 999.99,
        decisionNote: 'Insufficient docs',
      );
      final json = model.toJson();
      expect(json['id'], 'rt-1');
      expect(json['claimNumber'], 'CLM-RT');
      expect(json['status'], 'REJECTED');
      expect(json['claimedAmount'], 999.99);
      expect(json['decisionNote'], 'Insufficient docs');
    });

    test('toJson → fromJson round-trip preserves all data', () {
      final original = ClaimModel.fromJson({
        'id': 'round-trip-1',
        'claimNumber': 'CLM-ROUND',
        'status': 'PAID',
        'claimedAmount': 2500.50,
        'approvedAmount': 2500.50,
        'serviceDate': '2025-09-01T00:00:00Z',
        'facilityName': 'Jimma General Hospital',
        'householdCode': 'HH-ORO-042',
        'beneficiaryName': 'Fatuma Ali',
        'decisionNote': 'Full payment approved',
      });

      final restored = ClaimModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.claimNumber, original.claimNumber);
      expect(restored.status, original.status);
      expect(restored.claimedAmount, original.claimedAmount);
      expect(restored.approvedAmount, original.approvedAmount);
      expect(restored.facilityName, original.facilityName);
      expect(restored.householdCode, original.householdCode);
      expect(restored.beneficiaryName, original.beneficiaryName);
      expect(restored.decisionNote, original.decisionNote);
    });
  });
}
