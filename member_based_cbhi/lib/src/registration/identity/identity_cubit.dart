import 'package:flutter_bloc/flutter_bloc.dart';

part 'identity_state.dart';

class IdentityCubit extends Cubit<IdentityState> {
  IdentityCubit() : super(const IdentityState());

  void updateIdentityNumber(String number) {
    emit(state.copyWith(identityNumber: number));
  }

  void updateEmploymentStatus(String status) {
    emit(state.copyWith(employmentStatus: status));
  }
}