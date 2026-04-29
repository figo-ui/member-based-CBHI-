import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../cbhi_data.dart';
import '../models/personal_info_model.dart';

part 'identity_state.dart';

class IdentityCubit extends Cubit<IdentityState> {
  IdentityCubit(this._repository) : super(const IdentityState());

  final CbhiRepository _repository;

  void updateIdentityNumber(String number) {
    emit(state.copyWith(identityNumber: number));
  }

  void updateEmploymentStatus(String status) {
    emit(state.copyWith(employmentStatus: status));
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  /// Pick an ID document image. On web, always uses file_picker.
  /// On mobile, uses image_picker (camera or gallery).
  Future<void> pickIdImage({bool fromCamera = false}) async {
    try {
      List<int>? bytes;
      String? name;

      if (kIsWeb) {
        // Web: file_picker is the only safe option
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.first;
        bytes = file.bytes?.toList();
        name = file.name;
      } else {
        // Mobile/desktop: use image_picker for camera/gallery
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        if (picked == null) return;
        bytes = await picked.readAsBytes().then((b) => b.toList());
        name = picked.name;
      }

      if (bytes == null || bytes.isEmpty) return;

      emit(state.copyWith(
        idImageBytes: bytes,
        idImageName: name,
        scanStatus: IdScanStatus.idle,
        clearScanError: true,
        // Clear any previously extracted data when a new image is picked
        identityNumber: '',
        clearDetectedName: true,
        nameMatchStatus: IdNameMatchStatus.notChecked,
        idAvailabilityStatus: IdAvailabilityStatus.unchecked,
      ));

      // Automatically trigger OCR after picking
      await _runOcr(bytes);
    } catch (_) {
      // User cancelled or permission denied — silently ignore
    }
  }

  /// Clear the selected image and reset OCR state.
  void clearIdImage() {
    emit(state.copyWith(
      clearIdImage: true,
      clearIdImageName: true,
      scanStatus: IdScanStatus.idle,
      clearScanError: true,
      identityNumber: '',
      clearDetectedName: true,
      nameMatchStatus: IdNameMatchStatus.notChecked,
      idAvailabilityStatus: IdAvailabilityStatus.unchecked,
    ));
  }

  /// Re-run OCR on the currently selected image.
  Future<void> retryOcr({PersonalInfoModel? personalInfo}) async {
    final bytes = state.idImageBytes;
    if (bytes == null || bytes.isEmpty) return;
    await _runOcr(bytes, personalInfo: personalInfo);
  }

  // ── OCR ───────────────────────────────────────────────────────────────────

  Future<void> _runOcr(
    List<int> bytes, {
    PersonalInfoModel? personalInfo,
  }) async {
    emit(state.copyWith(
      scanStatus: IdScanStatus.scanning,
      clearScanError: true,
      identityNumber: '',
      clearDetectedName: true,
      nameMatchStatus: IdNameMatchStatus.notChecked,
      idAvailabilityStatus: IdAvailabilityStatus.unchecked,
    ));

    try {
      final base64Image = base64Encode(bytes);
      final result = await _repository.validateIdDocument(
        imageBase64: base64Image,
      );

      final detectedId = result['detectedIdNumber']?.toString() ?? '';
      final detectedName = result['detectedName']?.toString();
      final isValid = result['isValid'] == true;
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      final issues = (result['issues'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      // Low confidence threshold: below 0.6 or explicitly invalid with issues
      final isLowConfidence = !isValid && issues.isNotEmpty;

      // Compute name match status
      final nameMatch = _compareNames(detectedName, personalInfo);

      if (detectedId.isNotEmpty && (isValid || confidence >= 0.6)) {
        emit(state.copyWith(
          identityNumber: detectedId,
          scanStatus: IdScanStatus.success,
          clearScanError: true,
          detectedName: detectedName,
          nameMatchStatus: nameMatch,
        ));
      } else if (isLowConfidence) {
        final errorMsg = issues.isNotEmpty ? issues.first : 'Low confidence';
        emit(state.copyWith(
          identityNumber: detectedId,
          scanStatus: IdScanStatus.lowConfidence,
          scanError: errorMsg,
          detectedName: detectedName,
          nameMatchStatus: nameMatch,
        ));
      } else {
        emit(state.copyWith(
          scanStatus: IdScanStatus.failed,
          scanError: issues.isNotEmpty
              ? issues.first
              : 'Could not extract ID number from the document.',
          clearDetectedName: true,
          nameMatchStatus: IdNameMatchStatus.notChecked,
        ));
        return; // No ID to check availability for
      }

      // ── Duplicate ID check ─────────────────────────────────────────────
      if (detectedId.isNotEmpty) {
        emit(state.copyWith(
          idAvailabilityStatus: IdAvailabilityStatus.checking,
        ));
        try {
          final errorMsg = await _repository.checkIdAvailability(detectedId);
          if (errorMsg == null) {
            emit(state.copyWith(
              idAvailabilityStatus: IdAvailabilityStatus.available,
            ));
          } else {
            emit(state.copyWith(
              idAvailabilityStatus: IdAvailabilityStatus.taken,
              scanError: errorMsg,
            ));
          }
        } catch (_) {
          // Availability check failed — treat as available to not block user
          emit(state.copyWith(
            idAvailabilityStatus: IdAvailabilityStatus.available,
          ));
        }
      }
    } catch (e) {
      emit(state.copyWith(
        scanStatus: IdScanStatus.failed,
        scanError: e.toString(),
        clearDetectedName: true,
        nameMatchStatus: IdNameMatchStatus.notChecked,
      ));
    }
  }

  // ── Name comparison ───────────────────────────────────────────────────────

  /// Compare OCR-detected name against personal info.
  /// Returns [IdNameMatchStatus.skipped] if no name was detected.
  /// Returns [IdNameMatchStatus.matched] if at least 2 name tokens overlap,
  /// or if the detected name contains both firstName and lastName.
  /// Returns [IdNameMatchStatus.mismatch] otherwise.
  IdNameMatchStatus _compareNames(
    String? detectedName,
    PersonalInfoModel? personalInfo,
  ) {
    if (detectedName == null || detectedName.trim().isEmpty) {
      return IdNameMatchStatus.skipped;
    }
    if (personalInfo == null) return IdNameMatchStatus.skipped;

    String normalize(String s) =>
        s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    final detectedParts = normalize(detectedName)
        .split(' ')
        .where((p) => p.length > 1)
        .toSet();
    final infoParts = normalize(personalInfo.fullName)
        .split(' ')
        .where((p) => p.length > 1)
        .toSet();

    final commonParts = detectedParts.intersection(infoParts);

    // Match if at least 2 name parts overlap
    if (commonParts.length >= 2) return IdNameMatchStatus.matched;

    // Or if detected name contains both firstName and lastName
    final normalizedDetected = normalize(detectedName);
    if (normalizedDetected.contains(normalize(personalInfo.firstName)) &&
        normalizedDetected.contains(normalize(personalInfo.lastName))) {
      return IdNameMatchStatus.matched;
    }

    return IdNameMatchStatus.mismatch;
  }
}
