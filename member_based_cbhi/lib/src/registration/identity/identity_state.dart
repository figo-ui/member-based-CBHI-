part of 'identity_cubit.dart';

class IdentityState {
  final String identityNumber;
  final String employmentStatus;

  const IdentityState({
    this.identityNumber = '',
    this.employmentStatus = '',
  });

  IdentityState copyWith({
    String? identityNumber,
    String? employmentStatus,
  }) {
    return IdentityState(
      identityNumber: identityNumber ?? this.identityNumber,
      employmentStatus: employmentStatus ?? this.employmentStatus,
    );
  }
}