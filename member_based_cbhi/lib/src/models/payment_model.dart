// FIX ME-1: Typed model for payment records

import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

@JsonSerializable()
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    this.providerName,
    this.receiptNumber,
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final String amount;
  final String method;
  final String status;
  final String? providerName;
  final String? receiptNumber;
  final String? paidAt;
  final String? createdAt;

  double get amountDouble => double.tryParse(amount) ?? 0.0;

  String get methodDisplay => method.replaceAll('_', ' ');

  bool get isSuccess => status == 'SUCCESS';

  String get dateLabel {
    final raw = paidAt ?? createdAt ?? '';
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);
}
