// FIX ME-1: Typed model replacing Map<String, dynamic> for coverage data.
// Generated with json_serializable. Run: flutter pub run build_runner build

import 'package:json_annotation/json_annotation.dart';

part 'coverage_model.g.dart';

@JsonSerializable()
class CoverageModel {
  const CoverageModel({
    required this.coverageNumber,
    required this.status,
    this.startDate,
    this.endDate,
    this.nextRenewalDate,
    this.premiumAmount,
    this.paidAmount,
  });

  final String coverageNumber;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? nextRenewalDate;
  final String? premiumAmount;
  final String? paidAmount;

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';
  bool get isPendingRenewal => status == 'PENDING_RENEWAL';

  double get premiumAmountDouble =>
      double.tryParse(premiumAmount ?? '0') ?? 0.0;
  double get paidAmountDouble => double.tryParse(paidAmount ?? '0') ?? 0.0;

  factory CoverageModel.fromJson(Map<String, dynamic> json) =>
      _$CoverageModelFromJson(json);

  Map<String, dynamic> toJson() => _$CoverageModelToJson(this);

  static CoverageModel empty() => const CoverageModel(
        coverageNumber: '',
        status: 'PENDING_RENEWAL',
      );
}
