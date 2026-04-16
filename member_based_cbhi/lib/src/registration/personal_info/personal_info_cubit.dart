import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/personal_info_model.dart';

part 'personal_info_state.dart';

class PersonalInfoCubit extends Cubit<PersonalInfoState> {
  PersonalInfoCubit() : super(const PersonalInfoState());

  void updateField({
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
  }) {
    emit(state.copyWith(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      phone: phone,
      email: email,
      gender: gender,
      dateOfBirth: dateOfBirth,
      birthCertificateRef: birthCertificateRef,
      region: region,
      zone: zone,
      woreda: woreda,
      kebele: kebele,
      householdSize: householdSize,
    ));
  }

  bool isValid() {
    return state.firstName.trim().isNotEmpty &&
        state.middleName.trim().isNotEmpty &&
        state.lastName.trim().isNotEmpty &&
        state.phone.trim().isNotEmpty &&
        state.gender.isNotEmpty &&
        state.dateOfBirth != null &&
        state.region.isNotEmpty &&
        state.zone.isNotEmpty &&
        state.householdSize >= 1;
  }

  PersonalInfoModel toModel() {
    final dob = state.dateOfBirth!;
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    return PersonalInfoModel(
      firstName: state.firstName.trim(),
      middleName: state.middleName.trim(),
      lastName: state.lastName.trim(),
      age: age,
      phone: state.phone.trim(),
      email: state.email?.trim(),
      gender: state.gender,
      dateOfBirth: dob,
      birthCertificateRef: state.birthCertificateRef?.trim(),
      region: state.region,
      zone: state.zone,
      woreda: state.woreda?.trim(),
      kebele: state.kebele?.trim(),
      householdSize: state.householdSize,
    );
  }
}