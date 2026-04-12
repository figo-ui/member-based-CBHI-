import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../cbhi_data.dart';
import 'models/personal_info_model.dart';
import 'models/identity_model.dart';
import 'models/membership_type.dart';


part 'registration_state.dart';

class RegistrationCubit extends Cubit<RegistrationState> {
  final CBHIData apiService;

  RegistrationCubit(this.apiService) : super(const RegistrationState());

  void startRegistration() => emit(state.copyWith(currentStep: RegistrationStep.personalInfo));

  void submitPersonalInfo(PersonalInfoModel info) {
    emit(state.copyWith(personalInfo: info, currentStep: RegistrationStep.confirmation));
  }

  void confirmPersonalInfo() {
    emit(state.copyWith(currentStep: RegistrationStep.identity));
  }

  void submitIdentity(IdentityModel identityData) {
    emit(state.copyWith(identity: identityData, currentStep: RegistrationStep.membership));
  }

  Future<void> submitMembership(MembershipSelection membership) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // TODO: Integrate with your existing step-1 + step-2 API
      await apiService.registerFull(
        personal: state.personalInfo!,
        identity: state.identity!,
        membership: membership,
      );

      emit(state.copyWith(
        membership: membership,
        currentStep: RegistrationStep.completed,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      ));
    }
  }

  void reset() => emit(const RegistrationState());
}