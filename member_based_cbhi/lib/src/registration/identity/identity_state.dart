part of 'identity_cubit.dart';

/// OCR processing status for the ID document scanner.
enum IdScanStatus {
  idle,
  scanning,
  success,
  lowConfidence,
  failed,
}

/// Name match result after comparing OCR-detected name vs personal info.
enum IdNameMatchStatus {
  /// OCR returned no name — cannot compare.
  notChecked,
  /// Names share enough tokens to be considered a match.
  matched,
  /// Names were compared and do not match.
  mismatch,
  /// OCR returned no name field — comparison skipped.
  skipped,
}

/// Availability check status for the extracted ID number.
enum IdAvailabilityStatus {
  /// No ID extracted yet — check not started.
  unchecked,
  /// Availability check in progress.
  checking,
  /// ID is not yet registered — safe to proceed.
  available,
  /// ID is already registered in the system.
  taken,
}

class IdentityState {
  final String identityNumber;
  final String employmentStatus;

  // ID document scanner state
  final List<int>? idImageBytes;
  final String? idImageName;
  final IdScanStatus scanStatus;
  final String? scanError;

  // Name extracted by OCR
  final String? detectedName;
  final IdNameMatchStatus nameMatchStatus;

  // Duplicate ID check
  final IdAvailabilityStatus idAvailabilityStatus;

  const IdentityState({
    this.identityNumber = '',
    this.employmentStatus = '',
    this.idImageBytes,
    this.idImageName,
    this.scanStatus = IdScanStatus.idle,
    this.scanError,
    this.detectedName,
    this.nameMatchStatus = IdNameMatchStatus.notChecked,
    this.idAvailabilityStatus = IdAvailabilityStatus.unchecked,
  });

  IdentityState copyWith({
    String? identityNumber,
    String? employmentStatus,
    List<int>? idImageBytes,
    bool clearIdImage = false,
    String? idImageName,
    bool clearIdImageName = false,
    IdScanStatus? scanStatus,
    String? scanError,
    bool clearScanError = false,
    String? detectedName,
    bool clearDetectedName = false,
    IdNameMatchStatus? nameMatchStatus,
    IdAvailabilityStatus? idAvailabilityStatus,
  }) {
    return IdentityState(
      identityNumber: identityNumber ?? this.identityNumber,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      idImageBytes: clearIdImage ? null : (idImageBytes ?? this.idImageBytes),
      idImageName: clearIdImageName ? null : (idImageName ?? this.idImageName),
      scanStatus: scanStatus ?? this.scanStatus,
      scanError: clearScanError ? null : (scanError ?? this.scanError),
      detectedName: clearDetectedName ? null : (detectedName ?? this.detectedName),
      nameMatchStatus: nameMatchStatus ?? this.nameMatchStatus,
      idAvailabilityStatus: idAvailabilityStatus ?? this.idAvailabilityStatus,
    );
  }
}
