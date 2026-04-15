// FIX ME-4: BLoC for facility submit claim screen — replaces raw setState

import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/facility_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SubmitClaimState extends Equatable {
  const SubmitClaimState({
    required this.isSubmitting,
    this.successMessage,
    this.error,
  });

  factory SubmitClaimState.initial() =>
      const SubmitClaimState(isSubmitting: false);

  final bool isSubmitting;
  final String? successMessage;
  final String? error;

  bool get hasSuccess => successMessage != null;
  bool get hasError => error != null;

  SubmitClaimState copyWith({
    bool? isSubmitting,
    String? successMessage,
    String? error,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return SubmitClaimState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isSubmitting, successMessage, error];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class SubmitClaimCubit extends Cubit<SubmitClaimState> {
  SubmitClaimCubit(this.repository) : super(SubmitClaimState.initial());

  final FacilityRepository repository;

  Future<void> submit({
    String? membershipId,
    String? phoneNumber,
    String? householdCode,
    String? fullName,
    required String serviceDate,
    required List<Map<String, dynamic>> items,
    String? attachmentPath,
    String? attachmentName,
    String? attachmentMime,
  }) async {
    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      Map<String, dynamic>? attachmentUpload;
      if (attachmentPath != null && attachmentName != null) {
        final bytes = await File(attachmentPath).readAsBytes();
        attachmentUpload = {
          'fileName': attachmentName,
          'contentBase64': base64Encode(bytes),
          'mimeType': attachmentMime ?? 'application/octet-stream',
        };
      }

      final response = await repository.submitClaim(
        membershipId: membershipId,
        phoneNumber: phoneNumber,
        householdCode: householdCode,
        fullName: fullName,
        serviceDate: serviceDate,
        items: items,
        supportingDocumentUpload: attachmentUpload,
      );

      emit(state.copyWith(
        isSubmitting: false,
        successMessage: response['claimNumber']?.toString() ?? '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void reset() => emit(SubmitClaimState.initial());
}
