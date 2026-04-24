part of 'registration_cubit.dart';

enum RegistrationStep {
  start,
  personalInfo,
  confirmation,
  identity,
  membership,
  indigentProof,
  payment,
  /// New: after registration succeeds, user must set up account via SMS code
  setupAccount,
  completed,
  error,
}

class RegistrationState {
  final RegistrationStep currentStep;
  final PersonalInfoModel? personalInfo;
  final IdentityModel? identity;
  final MembershipSelection? membership;
  final String? errorMessage;
  final bool isLoading;
  final bool isOffline;
  final String? registeredPhone;
  final OtpChallenge? setupChallenge;
  final CbhiSnapshot? registrationSnapshot;

  const RegistrationState({
    this.currentStep = RegistrationStep.start,
    this.personalInfo,
    this.identity,
    this.membership,
    this.errorMessage,
    this.isLoading = false,
    this.isOffline = false,
    this.registeredPhone,
    this.setupChallenge,
    this.registrationSnapshot,
  });

  RegistrationState copyWith({
    RegistrationStep? currentStep,
    PersonalInfoModel? personalInfo,
    IdentityModel? identity,
    MembershipSelection? membership,
    String? errorMessage,
    bool? isLoading,
    bool? isOffline,
    bool clearError = false,
    bool clearMembership = false,
    String? registeredPhone,
    OtpChallenge? setupChallenge,
    CbhiSnapshot? registrationSnapshot,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      personalInfo: personalInfo ?? this.personalInfo,
      identity: identity ?? this.identity,
      membership: clearMembership ? null : membership ?? this.membership,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      registeredPhone: registeredPhone ?? this.registeredPhone,
      setupChallenge: setupChallenge ?? this.setupChallenge,
      registrationSnapshot: registrationSnapshot ?? this.registrationSnapshot,
    );
  }
}
