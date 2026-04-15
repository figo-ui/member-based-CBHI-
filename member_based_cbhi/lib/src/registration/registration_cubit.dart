import 'package:flutter_bloc/flutter_bloc.dart';
import '../cbhi_data.dart';
import 'models/personal_info_model.dart';
import 'models/identity_model.dart';
import 'models/membership_type.dart';

part 'registration_state.dart';

class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit(this.repository) : super(const RegistrationState());

  final CbhiRepository repository;

  void startRegistration() =>
      emit(state.copyWith(currentStep: RegistrationStep.personalInfo, clearError: true));

  void submitPersonalInfo(PersonalInfoModel info) {
    emit(
      state.copyWith(
        personalInfo: info,
        currentStep: RegistrationStep.confirmation,
        clearError: true,
      ),
    );
  }

  void goBackToPersonalInfo() {
    emit(state.copyWith(currentStep: RegistrationStep.personalInfo, clearError: true));
  }

  void confirmPersonalInfo() {
    emit(state.copyWith(currentStep: RegistrationStep.identity, clearError: true));
  }

  void submitIdentity(IdentityModel identityData) {
    emit(
      state.copyWith(
        identity: identityData,
        currentStep: RegistrationStep.membership,
        clearError: true,
      ),
    );
  }

  Future<void> submitPayingMembership(MembershipSelection membership) async {
    await _runRegistration(membership, const []);
  }

  void beginIndigentProof(MembershipSelection membership) {
    emit(
      state.copyWith(
        membership: membership,
        currentStep: RegistrationStep.indigentProof,
        clearError: true,
      ),
    );
  }

  void cancelIndigentProof() {
    emit(
      state.copyWith(
        currentStep: RegistrationStep.membership,
        clearMembership: true,
        clearError: true,
      ),
    );
  }

  Future<void> submitIndigentProofs(List<String> proofPaths) async {
    final membership = state.membership;
    if (membership == null) {
      emit(state.copyWith(errorMessage: 'Membership selection missing.'));
      return;
    }
    if (proofPaths.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Add at least one supporting document for indigent membership.',
      ));
      return;
    }
    await _runRegistration(membership, proofPaths);
  }

  Future<void> _runRegistration(
    MembershipSelection membership,
    List<String> indigentProofPaths,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, errorMessage: null));

    try {
      await repository.registerFull(
        personalInfo: state.personalInfo!,
        identity: state.identity!,
        membership: membership,
        indigentProofPaths: indigentProofPaths,
      );

      // After registration, send a setup OTP to the registered phone so the
      // user can activate their account and set a password.
      final phone = state.personalInfo?.phone;
      OtpChallenge? challenge;
      if (phone != null && phone.isNotEmpty) {
        try {
          challenge = await repository.sendOtp(phoneNumber: phone);
        } catch (_) {
          // Non-fatal — user can resend from the setup screen
        }
      }

      emit(
        state.copyWith(
          membership: membership,
          currentStep: challenge != null
              ? RegistrationStep.setupAccount
              : RegistrationStep.completed,
          registeredPhone: phone,
          setupChallenge: challenge,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString(), isLoading: false));
    }
  }

  void reset() => emit(const RegistrationState());
}
