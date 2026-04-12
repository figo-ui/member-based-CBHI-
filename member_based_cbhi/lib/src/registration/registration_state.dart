part of 'registration_cubit.dart';

enum RegistrationStep {
  start,
  personalInfo,
  confirmation,
  identity,
  membership,
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

  const RegistrationState({
    this.currentStep = RegistrationStep.start,
    this.personalInfo,
    this.identity,
    this.membership,
    this.errorMessage,
    this.isLoading = false,
  });

  RegistrationState copyWith({
    RegistrationStep? currentStep,
    PersonalInfoModel? personalInfo,
    IdentityModel? identity,
    MembershipSelection? membership,
    String? errorMessage,
    bool? isLoading,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      personalInfo: personalInfo ?? this.personalInfo,
      identity: identity ?? this.identity,
      membership: membership ?? this.membership,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
