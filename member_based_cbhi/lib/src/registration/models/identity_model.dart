/// Maps UI / legacy codes to backend [IndigentEmploymentStatus] string values.
const Map<String, String> kEmploymentStatusForApi = {
  'farmer': 'farmer',
  'merchant': 'merchant',
  'daily_laborer': 'daily_laborer',
  'employed': 'employed',
  'unemployed': 'unemployed',
  'student': 'student',
  'homemaker': 'homemaker',
  'pensioner': 'pensioner',
  // Legacy uppercase keys (older builds)
  'FARMER': 'farmer',
  'MERCHANT': 'merchant',
  'DAILY_LABORER': 'daily_laborer',
  'EMPLOYED': 'employed',
  'UNEMPLOYED': 'unemployed',
  'STUDENT': 'student',
  'HOUSEWIFE': 'homemaker',
  'HOMEMAKER': 'homemaker',
  'PENSIONER': 'pensioner',
  'OTHER': 'unemployed',
};

class IdentityModel {
  const IdentityModel({
    required this.identityType,
    required this.identityNumber,
    this.identityPhotoPath,
    required this.employmentStatus,
  });

  final String identityType;
  final String identityNumber;
  final String? identityPhotoPath;
  final String employmentStatus;

  /// Backend `/cbhi/registration/step-2` expects lowercase snake_case.
  String get employmentStatusForApi =>
      kEmploymentStatusForApi[employmentStatus] ?? 'unemployed';

  Map<String, dynamic> toJson() {
    return {
      'identityType': identityType,
      'identityNumber': identityNumber,
      'employmentStatus': employmentStatus,
    };
  }

  factory IdentityModel.fromJson(Map<String, dynamic> json) {
    return IdentityModel(
      identityType: json['identityType']?.toString() ?? 'NATIONAL_ID',
      identityNumber: json['identityNumber']?.toString() ?? '',
      identityPhotoPath: json['identityPhotoPath']?.toString(),
      employmentStatus: json['employmentStatus']?.toString() ?? 'unemployed',
    );
  }
}
