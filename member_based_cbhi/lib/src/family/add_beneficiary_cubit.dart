import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cbhi_data.dart';

class AddBeneficiaryState extends Equatable {
  const AddBeneficiaryState({
    required this.isSubmitting,
    this.photoPath,
    this.error,
  });

  factory AddBeneficiaryState.initial({String? photoPath}) {
    return AddBeneficiaryState(isSubmitting: false, photoPath: photoPath);
  }

  final bool isSubmitting;
  final String? photoPath;
  final String? error;

  AddBeneficiaryState copyWith({
    bool? isSubmitting,
    String? photoPath,
    String? error,
    bool clearError = false,
  }) {
    return AddBeneficiaryState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      photoPath: photoPath ?? this.photoPath,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isSubmitting, photoPath, error];
}

class AddBeneficiaryCubit extends Cubit<AddBeneficiaryState> {
  AddBeneficiaryCubit(this.repository, {String? initialPhotoPath})
    : super(AddBeneficiaryState.initial(photoPath: initialPhotoPath));

  final CbhiRepository repository;

  void setPhotoPath(String? path) {
    emit(state.copyWith(photoPath: path, clearError: true));
  }

  Future<bool> submit({
    String? memberId,
    required FamilyMemberDraft draft,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      if (memberId == null) {
        await repository.addFamilyMember(draft);
      } else {
        await repository.updateFamilyMember(memberId, draft);
      }
      emit(state.copyWith(isSubmitting: false, clearError: true));
      return true;
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, error: error.toString()));
      return false;
    }
  }
}
