class IdentityModel {
  final String identityType; // NATIONAL_ID, PASSPORT, LOCAL_ID
  final String identityNumber;
  final String? identityPhotoPath;
  final String employmentStatus;

  IdentityModel({
    required this.identityType,
    required this.identityNumber,
    this.identityPhotoPath,
    required this.employmentStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'identityType': identityType,
      'identityNumber': identityNumber,
      'employmentStatus': employmentStatus,
    };
  }
}