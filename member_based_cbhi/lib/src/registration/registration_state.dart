part of 'registration_cubit.dart';

enum RegistrationStep {
  start,
  personalInfo,
  confirmation,
  identity,
  membership,
  indigentProof,
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
  /// Phone number used during registration — needed for account setup OTP
  final String? registeredPhone;
  /// OTP challenge returned after registration — drives AccountSetupScreen
  final OtpChallenge? setupChallenge;

  const RegistrationState({
    this.currentStep = RegistrationStep.start,
    this.personalInfo,
    this.identity,
    this.membership,
    this.errorMessage,
    this.isLoading = false,
    this.registeredPhone,
    this.setupChallenge,
  });

  RegistrationState copyWith({
    RegistrationStep? currentStep,
    PersonalInfoModel? personalInfo,
    IdentityModel? identity,
    MembershipSelection? membership,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    bool clearMembership = false,
    String? registeredPhone,
    OtpChallenge? setupChallenge,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      personalInfo: personalInfo ?? this.personalInfo,
      identity: identity ?? this.identity,
      membership: clearMembership ? null : membership ?? this.membership,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      registeredPhone: registeredPhone ?? this.registeredPhone,
      setupChallenge: setupChallenge ?? this.setupChallenge,
    );
  }
}
