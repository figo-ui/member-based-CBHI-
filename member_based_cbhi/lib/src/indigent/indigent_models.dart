import 'package:flutter/foundation.dart';

/// Accepted document types for indigent applications
enum IndigentDocumentType {
  incomeCertificate('Income Certificate', 12, 'የገቢ ማረጋገጫ ደብዳቤ'),
  disabilityCertificate('Disability Certificate', 36, 'የአካል ጉዳት ማረጋገጫ'),
  kebeleId('Kebele ID / Residence', 24, 'የቀበሌ መታወቂያ'),
  povertyCertificate('Poverty Certificate', 12, 'የድህነት ማረጋገጫ'),
  agriculturalCertificate('Agricultural Certificate', 12, 'የገበሬ ማረጋገጫ');

  const IndigentDocumentType(this.label, this.validityMonths, this.amharic);

  final String label;
  final int validityMonths;
  final String amharic;
}

@immutable
class IndigentDocumentMeta {
  const IndigentDocumentMeta({
    required this.localPath,
    this.documentType,
    this.detectedDate,
    this.isExpired = false,
    this.expiryWarning,
    this.validationSummary,
    this.isValidated = false,
    this.isValidating = false,
    this.validationError,
    this.confidence = 0,
    this.detectedKeywords = const [],
  });

  final String localPath;
  final String? documentType;
  final String? detectedDate;
  final bool isExpired;
  final String? expiryWarning;
  final String? validationSummary;
  final bool isValidated;
  final bool isValidating;
  final String? validationError;
  final double confidence;
  final List<String> detectedKeywords;

  bool get isAccepted =>
      isValidated &&
      !isExpired &&
      documentType != null &&
      documentType != 'unknown';

  IndigentDocumentMeta copyWith({
    String? documentType,
    String? detectedDate,
    bool? isExpired,
    String? expiryWarning,
    String? validationSummary,
    bool? isValidated,
    bool? isValidating,
    String? validationError,
    double? confidence,
    List<String>? detectedKeywords,
  }) {
    return IndigentDocumentMeta(
      localPath: localPath,
      documentType: documentType ?? this.documentType,
      detectedDate: detectedDate ?? this.detectedDate,
      isExpired: isExpired ?? this.isExpired,
      expiryWarning: expiryWarning ?? this.expiryWarning,
      validationSummary: validationSummary ?? this.validationSummary,
      isValidated: isValidated ?? this.isValidated,
      isValidating: isValidating ?? this.isValidating,
      validationError: validationError ?? this.validationError,
      confidence: confidence ?? this.confidence,
      detectedKeywords: detectedKeywords ?? this.detectedKeywords,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': localPath,
    'documentType': documentType,
    'detectedDate': detectedDate,
    'isExpired': isExpired,
    'validationSummary': validationSummary,
  };
}
