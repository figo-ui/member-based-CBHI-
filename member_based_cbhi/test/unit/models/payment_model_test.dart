// Unit tests for PaymentModel — serialization, computed properties, edge cases.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/models/payment_model.dart';

void main() {
  group('PaymentModel', () {
    // ── fromJson ────────────────────────────────────────────────────────────

    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'pay-100',
        'amount': '1500.00',
        'method': 'MOBILE_MONEY',
        'status': 'SUCCESS',
        'providerName': 'Chapa',
        'receiptNumber': 'RCP-2025-001',
        'paidAt': '2025-06-15T10:30:00.000Z',
        'createdAt': '2025-06-15T09:00:00.000Z',
      };

      final model = PaymentModel.fromJson(json);

      expect(model.id, 'pay-100');
      expect(model.amount, '1500.00');
      expect(model.method, 'MOBILE_MONEY');
      expect(model.status, 'SUCCESS');
      expect(model.providerName, 'Chapa');
      expect(model.receiptNumber, 'RCP-2025-001');
      expect(model.paidAt, '2025-06-15T10:30:00.000Z');
      expect(model.createdAt, '2025-06-15T09:00:00.000Z');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'pay-101',
        'amount': '200.00',
        'method': 'CASH',
        'status': 'PENDING',
      };

      final model = PaymentModel.fromJson(json);

      expect(model.providerName, isNull);
      expect(model.receiptNumber, isNull);
      expect(model.paidAt, isNull);
      expect(model.createdAt, isNull);
    });

    // ── amountDouble ────────────────────────────────────────────────────────

    test('amountDouble parses valid amount string', () {
      const model = PaymentModel(
        id: '1', amount: '1500.75', method: 'CASH', status: 'SUCCESS',
      );
      expect(model.amountDouble, 1500.75);
    });

    test('amountDouble returns 0.0 for invalid amount string', () {
      const model = PaymentModel(
        id: '2', amount: 'not-a-number', method: 'CASH', status: 'SUCCESS',
      );
      expect(model.amountDouble, 0.0);
    });

    test('amountDouble returns 0.0 for empty amount string', () {
      const model = PaymentModel(
        id: '3', amount: '', method: 'CASH', status: 'SUCCESS',
      );
      expect(model.amountDouble, 0.0);
    });

    // ── methodDisplay ───────────────────────────────────────────────────────

    test('methodDisplay replaces underscores with spaces', () {
      const model = PaymentModel(
        id: '4', amount: '100', method: 'MOBILE_MONEY', status: 'SUCCESS',
      );
      expect(model.methodDisplay, 'MOBILE MONEY');
    });

    test('methodDisplay handles method without underscores', () {
      const model = PaymentModel(
        id: '5', amount: '100', method: 'CASH', status: 'SUCCESS',
      );
      expect(model.methodDisplay, 'CASH');
    });

    test('methodDisplay handles BANK_TRANSFER', () {
      const model = PaymentModel(
        id: '6', amount: '100', method: 'BANK_TRANSFER', status: 'SUCCESS',
      );
      expect(model.methodDisplay, 'BANK TRANSFER');
    });

    // ── isSuccess ───────────────────────────────────────────────────────────

    test('isSuccess returns true for SUCCESS status', () {
      const model = PaymentModel(
        id: '7', amount: '100', method: 'CASH', status: 'SUCCESS',
      );
      expect(model.isSuccess, isTrue);
    });

    test('isSuccess returns false for PENDING status', () {
      const model = PaymentModel(
        id: '8', amount: '100', method: 'CASH', status: 'PENDING',
      );
      expect(model.isSuccess, isFalse);
    });

    test('isSuccess returns false for FAILED status', () {
      const model = PaymentModel(
        id: '9', amount: '100', method: 'CASH', status: 'FAILED',
      );
      expect(model.isSuccess, isFalse);
    });

    // ── dateLabel ───────────────────────────────────────────────────────────

    test('dateLabel formats paidAt date correctly', () {
      const model = PaymentModel(
        id: '10', amount: '100', method: 'CASH', status: 'SUCCESS',
        paidAt: '2025-06-15T10:30:00.000Z',
      );
      expect(model.dateLabel, '15 Jun 2025');
    });

    test('dateLabel falls back to createdAt when paidAt is null', () {
      const model = PaymentModel(
        id: '11', amount: '100', method: 'CASH', status: 'SUCCESS',
        createdAt: '2025-01-03T00:00:00.000Z',
      );
      expect(model.dateLabel, '03 Jan 2025');
    });

    test('dateLabel returns empty string when both dates are null', () {
      const model = PaymentModel(
        id: '12', amount: '100', method: 'CASH', status: 'SUCCESS',
      );
      expect(model.dateLabel, '');
    });

    test('dateLabel handles various months correctly', () {
      const months = {
        '2025-03-01T00:00:00Z': '01 Mar 2025',
        '2025-07-20T00:00:00Z': '20 Jul 2025',
        '2025-12-31T00:00:00Z': '31 Dec 2025',
      };
      for (final entry in months.entries) {
        final model = PaymentModel(
          id: 'month-test', amount: '100', method: 'CASH', status: 'SUCCESS',
          paidAt: entry.key,
        );
        expect(model.dateLabel, entry.value,
            reason: 'Failed for date: ${entry.key}');
      }
    });

    test('dateLabel returns raw string for unparseable date', () {
      const model = PaymentModel(
        id: '13', amount: '100', method: 'CASH', status: 'SUCCESS',
        paidAt: 'not-a-date',
      );
      expect(model.dateLabel, 'not-a-date');
    });

    // ── toJson / round-trip ─────────────────────────────────────────────────

    test('toJson → fromJson round-trip preserves all data', () {
      final original = PaymentModel.fromJson({
        'id': 'rt-pay-1',
        'amount': '2500.00',
        'method': 'MOBILE_MONEY',
        'status': 'SUCCESS',
        'providerName': 'Chapa',
        'receiptNumber': 'RCP-RT-001',
        'paidAt': '2025-08-20T12:00:00Z',
        'createdAt': '2025-08-20T10:00:00Z',
      });

      final restored = PaymentModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.method, original.method);
      expect(restored.status, original.status);
      expect(restored.providerName, original.providerName);
      expect(restored.receiptNumber, original.receiptNumber);
    });
  });
}
