// Unit tests for CoverageModel — serialization, computed properties, edge cases.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/models/coverage_model.dart';

void main() {
  group('CoverageModel', () {
    // ── fromJson ────────────────────────────────────────────────────────────

    test('fromJson parses all fields correctly', () {
      final json = {
        'coverageNumber': 'CVG-ETH-001',
        'status': 'ACTIVE',
        'startDate': '2025-01-01T00:00:00.000Z',
        'endDate': '2026-01-01T00:00:00.000Z',
        'nextRenewalDate': '2025-12-15T00:00:00.000Z',
        'premiumAmount': '500.00',
        'paidAmount': '500.00',
      };

      final model = CoverageModel.fromJson(json);

      expect(model.coverageNumber, 'CVG-ETH-001');
      expect(model.status, 'ACTIVE');
      expect(model.startDate, '2025-01-01T00:00:00.000Z');
      expect(model.endDate, '2026-01-01T00:00:00.000Z');
      expect(model.nextRenewalDate, '2025-12-15T00:00:00.000Z');
      expect(model.premiumAmount, '500.00');
      expect(model.paidAmount, '500.00');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'coverageNumber': 'CVG-002',
        'status': 'EXPIRED',
      };

      final model = CoverageModel.fromJson(json);

      expect(model.startDate, isNull);
      expect(model.endDate, isNull);
      expect(model.nextRenewalDate, isNull);
      expect(model.premiumAmount, isNull);
      expect(model.paidAmount, isNull);
    });

    // ── Status computed properties ──────────────────────────────────────────

    test('isActive returns true for ACTIVE status', () {
      const model = CoverageModel(coverageNumber: 'C-1', status: 'ACTIVE');
      expect(model.isActive, isTrue);
      expect(model.isExpired, isFalse);
      expect(model.isPendingRenewal, isFalse);
    });

    test('isExpired returns true for EXPIRED status', () {
      const model = CoverageModel(coverageNumber: 'C-2', status: 'EXPIRED');
      expect(model.isExpired, isTrue);
      expect(model.isActive, isFalse);
      expect(model.isPendingRenewal, isFalse);
    });

    test('isPendingRenewal returns true for PENDING_RENEWAL status', () {
      const model = CoverageModel(coverageNumber: 'C-3', status: 'PENDING_RENEWAL');
      expect(model.isPendingRenewal, isTrue);
      expect(model.isActive, isFalse);
      expect(model.isExpired, isFalse);
    });

    test('unknown status returns false for all computed properties', () {
      const model = CoverageModel(coverageNumber: 'C-4', status: 'SUSPENDED');
      expect(model.isActive, isFalse);
      expect(model.isExpired, isFalse);
      expect(model.isPendingRenewal, isFalse);
    });

    // ── Numeric parsing ─────────────────────────────────────────────────────

    test('premiumAmountDouble parses valid string', () {
      const model = CoverageModel(
        coverageNumber: 'C-5', status: 'ACTIVE', premiumAmount: '1200.50',
      );
      expect(model.premiumAmountDouble, 1200.50);
    });

    test('premiumAmountDouble returns 0.0 for null premiumAmount', () {
      const model = CoverageModel(coverageNumber: 'C-6', status: 'ACTIVE');
      expect(model.premiumAmountDouble, 0.0);
    });

    test('paidAmountDouble parses valid string', () {
      const model = CoverageModel(
        coverageNumber: 'C-7', status: 'ACTIVE', paidAmount: '800.25',
      );
      expect(model.paidAmountDouble, 800.25);
    });

    test('paidAmountDouble returns 0.0 for null paidAmount', () {
      const model = CoverageModel(coverageNumber: 'C-8', status: 'ACTIVE');
      expect(model.paidAmountDouble, 0.0);
    });

    test('paidAmountDouble returns 0.0 for invalid string', () {
      const model = CoverageModel(
        coverageNumber: 'C-9', status: 'ACTIVE', paidAmount: 'abc',
      );
      expect(model.paidAmountDouble, 0.0);
    });

    // ── empty() factory ─────────────────────────────────────────────────────

    test('empty() creates model with default values', () {
      final model = CoverageModel.empty();
      expect(model.coverageNumber, '');
      expect(model.status, 'PENDING_RENEWAL');
      expect(model.isPendingRenewal, isTrue);
      expect(model.startDate, isNull);
      expect(model.endDate, isNull);
      expect(model.premiumAmountDouble, 0.0);
      expect(model.paidAmountDouble, 0.0);
    });

    // ── toJson / round-trip ─────────────────────────────────────────────────

    test('toJson produces valid JSON map', () {
      const model = CoverageModel(
        coverageNumber: 'CVG-JSON',
        status: 'ACTIVE',
        premiumAmount: '600.00',
        paidAmount: '600.00',
      );
      final json = model.toJson();
      expect(json['coverageNumber'], 'CVG-JSON');
      expect(json['status'], 'ACTIVE');
      expect(json['premiumAmount'], '600.00');
    });

    test('toJson → fromJson round-trip preserves all data', () {
      final original = CoverageModel.fromJson({
        'coverageNumber': 'CVG-ROUND',
        'status': 'ACTIVE',
        'startDate': '2025-01-01T00:00:00Z',
        'endDate': '2026-01-01T00:00:00Z',
        'nextRenewalDate': '2025-12-01T00:00:00Z',
        'premiumAmount': '750.00',
        'paidAmount': '750.00',
      });

      final restored = CoverageModel.fromJson(original.toJson());

      expect(restored.coverageNumber, original.coverageNumber);
      expect(restored.status, original.status);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
      expect(restored.premiumAmountDouble, original.premiumAmountDouble);
      expect(restored.paidAmountDouble, original.paidAmountDouble);
    });
  });
}
