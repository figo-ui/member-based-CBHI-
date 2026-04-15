// Flutter widget tests for the member app.
// These tests verify core state management and model logic without
// requiring a running backend.

import 'package:flutter_test/flutter_test.dart';

import 'package:member_based_cbhi/src/models/coverage_model.dart';
import 'package:member_based_cbhi/src/models/payment_model.dart';
import 'package:member_based_cbhi/src/models/claim_model.dart';

void main() {
  // ── CoverageModel ──────────────────────────────────────────────────────────

  group('CoverageModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'coverageNumber': 'CVG-001',
        'status': 'ACTIVE',
        'startDate': '2025-01-01T00:00:00.000Z',
        'endDate': '2026-01-01T00:00:00.000Z',
        'premiumAmount': '500.00',
        'paidAmount': '500.00',
      };
      final model = CoverageModel.fromJson(json);
      expect(model.coverageNumber, 'CVG-001');
      expect(model.status, 'ACTIVE');
      expect(model.isActive, isTrue);
      expect(model.isExpired, isFalse);
      expect(model.premiumAmountDouble, 500.0);
      expect(model.paidAmountDouble, 500.0);
    });

    test('isExpired returns true for EXPIRED status', () {
      const model = CoverageModel(
        coverageNumber: 'CVG-002',
        status: 'EXPIRED',
      );
      expect(model.isExpired, isTrue);
      expect(model.isActive, isFalse);
    });

    test('isPendingRenewal returns true for PENDING_RENEWAL status', () {
      const model = CoverageModel(
        coverageNumber: 'CVG-003',
        status: 'PENDING_RENEWAL',
      );
      expect(model.isPendingRenewal, isTrue);
    });

    test('empty() returns a valid empty model', () {
      final model = CoverageModel.empty();
      expect(model.coverageNumber, '');
      expect(model.status, 'PENDING_RENEWAL');
    });

    test('toJson round-trips correctly', () {
      const model = CoverageModel(
        coverageNumber: 'CVG-004',
        status: 'ACTIVE',
        premiumAmount: '120.00',
        paidAmount: '120.00',
      );
      final json = model.toJson();
      final restored = CoverageModel.fromJson(json);
      expect(restored.coverageNumber, model.coverageNumber);
      expect(restored.status, model.status);
      expect(restored.premiumAmountDouble, model.premiumAmountDouble);
    });
  });

  // ── PaymentModel ───────────────────────────────────────────────────────────

  group('PaymentModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'pay-001',
        'amount': '500.00',
        'method': 'MOBILE_MONEY',
        'status': 'SUCCESS',
        'providerName': 'Chapa',
        'paidAt': '2025-03-15T10:30:00.000Z',
      };
      final model = PaymentModel.fromJson(json);
      expect(model.id, 'pay-001');
      expect(model.amountDouble, 500.0);
      expect(model.isSuccess, isTrue);
      expect(model.methodDisplay, 'MOBILE MONEY');
    });

    test('dateLabel formats correctly', () {
      final json = {
        'id': 'pay-002',
        'amount': '120.00',
        'method': 'BANK_TRANSFER',
        'status': 'SUCCESS',
        'paidAt': '2025-06-15T00:00:00.000Z',
      };
      final model = PaymentModel.fromJson(json);
      expect(model.dateLabel, '15 Jun 2025');
    });

    test('isSuccess returns false for PENDING', () {
      final json = {
        'id': 'pay-003',
        'amount': '120.00',
        'method': 'MOBILE_MONEY',
        'status': 'PENDING',
      };
      final model = PaymentModel.fromJson(json);
      expect(model.isSuccess, isFalse);
    });
  });

  // ── ClaimModel ─────────────────────────────────────────────────────────────

  group('ClaimModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'clm-001',
        'claimNumber': 'CLM-ABCD',
        'status': 'APPROVED',
        'claimedAmount': 350.0,
        'approvedAmount': 300.0,
        'serviceDate': '2025-04-10T00:00:00.000Z',
        'facilityName': 'Maya City Health Center',
      };
      final model = ClaimModel.fromJson(json);
      expect(model.claimNumber, 'CLM-ABCD');
      expect(model.isApproved, isTrue);
      expect(model.isRejected, isFalse);
      expect(model.isPending, isFalse);
      expect(model.serviceDateFormatted, '2025-04-10');
    });

    test('isPending returns true for SUBMITTED', () {
      final json = {
        'id': 'clm-002',
        'claimNumber': 'CLM-EFGH',
        'status': 'SUBMITTED',
        'claimedAmount': 200.0,
      };
      final model = ClaimModel.fromJson(json);
      expect(model.isPending, isTrue);
      expect(model.isApproved, isFalse);
    });

    test('isPending returns true for UNDER_REVIEW', () {
      final json = {
        'id': 'clm-003',
        'claimNumber': 'CLM-IJKL',
        'status': 'UNDER_REVIEW',
        'claimedAmount': 150.0,
      };
      final model = ClaimModel.fromJson(json);
      expect(model.isPending, isTrue);
    });

    test('isApproved returns true for PAID', () {
      final json = {
        'id': 'clm-004',
        'claimNumber': 'CLM-MNOP',
        'status': 'PAID',
        'claimedAmount': 400.0,
        'approvedAmount': 400.0,
      };
      final model = ClaimModel.fromJson(json);
      expect(model.isApproved, isTrue);
    });

    test('toJson round-trips correctly', () {
      final json = {
        'id': 'clm-005',
        'claimNumber': 'CLM-QRST',
        'status': 'REJECTED',
        'claimedAmount': 500.0,
        'decisionNote': 'Insufficient documentation',
      };
      final model = ClaimModel.fromJson(json);
      final restored = ClaimModel.fromJson(model.toJson());
      expect(restored.claimNumber, model.claimNumber);
      expect(restored.isRejected, isTrue);
      expect(restored.decisionNote, 'Insufficient documentation');
    });
  });
}
