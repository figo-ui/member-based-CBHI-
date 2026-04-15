// FIX ME-1: Typed model for claim records

import 'package:json_annotation/json_annotation.dart';

part 'claim_model.g.dart';

@JsonSerializable()
class ClaimModel {
  const ClaimModel({
    required this.id,
    required this.claimNumber,
    required this.status,
    required this.claimedAmount,
    this.approvedAmount,
    this.serviceDate,
    this.submittedAt,
    this.reviewedAt,
    this.facilityName,
    this.householdCode,
    this.beneficiaryName,
    this.decisionNote,
  });

  final String id;
  final String claimNumber;
  final String status;
  final double claimedAmount;
  final double? approvedAmount;
  final String? serviceDate;
  final String? submittedAt;
  final String? reviewedAt;
  final String? facilityName;
  final String? householdCode;
  final String? beneficiaryName;
  final String? decisionNote;

  bool get isApproved => status == 'APPROVED' || status == 'PAID';
  bool get isRejected => status == 'REJECTED';
  bool get isPending => status == 'SUBMITTED' || status == 'UNDER_REVIEW';

  String get serviceDateFormatted {
    final raw = serviceDate ?? '';
    return raw.split('T').first;
  }

  factory ClaimModel.fromJson(Map<String, dynamic> json) =>
      _$ClaimModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimModelToJson(this);
}
