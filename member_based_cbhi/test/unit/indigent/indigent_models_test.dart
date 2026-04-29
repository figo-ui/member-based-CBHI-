// Unit tests for IndigentDocumentMeta and IndigentDocumentType
// Tests model logic, copyWith, and status helpers.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/indigent/indigent_models.dart';

void main() {
  group('IndigentDocumentType', () {
    test('all enum values have non-empty labels', () {
      for (final type in IndigentDocumentType.values) {
        expect(type.label, isNotEmpty);
        expect(type.amharic, isNotEmpty);
        expect(type.validityMonths, greaterThan(0));
      }
    });

    test('incomeCertificate has 12 month validity', () {
      expect(IndigentDocumentType.incomeCertificate.validityMonths, 12);
    });

    test('disabilityCertificate has 36 month validity', () {
      expect(IndigentDocumentType.disabilityCertificate.validityMonths, 36);
    });

    test('kebeleId has 24 month validity', () {
      expect(IndigentDocumentType.kebeleId.validityMonths, 24);
    });
  });

  group('IndigentDocumentMeta', () {
    test('constructor sets all fields correctly', () {
      const meta = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        documentType: 'incomeCertificate',
        detectedDate: '2024-01-01',
        isExpired: false,
        isValidated: true,
        confidence: 0.95,
        detectedKeywords: ['income', 'certificate'],
      );
      expect(meta.localPath, '/path/to/doc.pdf');
      expect(meta.documentType, 'incomeCertificate');
      expect(meta.isExpired, isFalse);
      expect(meta.isValidated, isTrue);
      expect(meta.confidence, 0.95);
      expect(meta.detectedKeywords, ['income', 'certificate']);
    });

    test('isAccepted is true when validated, not expired, and has known type', () {
      const meta = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        documentType: 'incomeCertificate',
        isExpired: false,
        isValidated: true,
      );
      expect(meta.isAccepted, isTrue);
    });

    test('isAccepted is false when expired', () {
      const meta = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        documentType: 'incomeCertificate',
        isExpired: true,
        isValidated: true,
      );
      expect(meta.isAccepted, isFalse);
    });

    test('isAccepted is false when not validated', () {
      const meta = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        documentType: 'incomeCertificate',
        isExpired: false,
        isValidated: false,
      );
      expect(meta.isAccepted, isFalse);
    });

    test('isAccepted is false when documentType is null', () {
      const meta = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        isExpired: false,
        isValidated: true,
      );
      expect(meta.isAccepted, isFalse);
    });

    test('isAccepted is false when documentType is "unknown"', () {
      const meta = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        documentType: 'unknown',
        isExpired: false,
        isValidated: true,
      );
      expect(meta.isAccepted, isFalse);
    });

    test('copyWith updates specified fields', () {
      const original = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        isValidating: true,
      );
      final updated = original.copyWith(
        documentType: 'povertyCertificate',
        isValidating: false,
        isValidated: true,
        confidence: 0.88,
      );
      expect(updated.localPath, '/path/to/doc.pdf'); // unchanged
      expect(updated.documentType, 'povertyCertificate');
      expect(updated.isValidating, isFalse);
      expect(updated.isValidated, isTrue);
      expect(updated.confidence, 0.88);
    });

    test('copyWith preserves unchanged fields', () {
      const original = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        documentType: 'kebeleId',
        detectedDate: '2024-06-01',
        confidence: 0.75,
        detectedKeywords: ['kebele', 'id'],
      );
      final updated = original.copyWith(isExpired: true);
      expect(updated.documentType, 'kebeleId');
      expect(updated.detectedDate, '2024-06-01');
      expect(updated.confidence, 0.75);
      expect(updated.detectedKeywords, ['kebele', 'id']);
    });

    test('toJson includes required fields', () {
      const meta = IndigentDocumentMeta(
        localPath: '/path/to/doc.pdf',
        documentType: 'incomeCertificate',
        detectedDate: '2024-01-01',
        isExpired: false,
        validationSummary: 'Valid income certificate',
      );
      final json = meta.toJson();
      expect(json['url'], '/path/to/doc.pdf');
      expect(json['documentType'], 'incomeCertificate');
      expect(json['detectedDate'], '2024-01-01');
      expect(json['isExpired'], isFalse);
      expect(json['validationSummary'], 'Valid income certificate');
    });

    test('default values are correct', () {
      const meta = IndigentDocumentMeta(localPath: '/path/to/doc.pdf');
      expect(meta.isExpired, isFalse);
      expect(meta.isValidated, isFalse);
      expect(meta.isValidating, isFalse);
      expect(meta.confidence, 0.0);
      expect(meta.detectedKeywords, isEmpty);
      expect(meta.documentType, isNull);
    });
  });
}
