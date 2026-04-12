part of 'personal_info_cubit.dart';

class PersonalInfoState {
  final String firstName;
  final String middleName;
  final String lastName;
  final String phone;
  final String? email;
  final String gender;
  final DateTime? dateOfBirth;
  final String? birthCertificateRef;
  final String region;
  final String zone;
  final String? woreda;
  final String? kebele;
  final int householdSize;
  final bool isSubmitting;

  const PersonalInfoState({
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.phone = '',
    this.email,
    this.gender = '',
    this.dateOfBirth,
    this.birthCertificateRef,
    this.region = '',
    this.zone = '',
    this.woreda,
    this.kebele,
    this.householdSize = 1,
    this.isSubmitting = false,
  });

  PersonalInfoState copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? birthCertificateRef,
    String? region,
    String? zone,
    String? woreda,
    String? kebele,
    int? householdSize,
    bool? isSubmitting,
  }) {
    return PersonalInfoState(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      birthCertificateRef: birthCertificateRef ?? this.birthCertificateRef,
      region: region ?? this.region,
      zone: zone ?? this.zone,
      woreda: woreda ?? this.woreda,
      kebele: kebele ?? this.kebele,
      householdSize: householdSize ?? this.householdSize,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}