// FIX ME-4: BLoC for facility verify screen — replaces raw setState

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/facility_repository.dart';

class VerifyState extends Equatable {
  const VerifyState({
    required this.isLoading,
    this.result,
    this.error,
  });

  factory VerifyState.initial() =>
      const VerifyState(isLoading: false);

  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;

  bool get hasResult => result != null;
  bool get isEligible => result?['eligibility']?['isEligible'] == true;

  VerifyState copyWith({
    bool? isLoading,
    Map<String, dynamic>? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return VerifyState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, result, error];
}

class VerifyCubit extends Cubit<VerifyState> {
  VerifyCubit(this.repository) : super(VerifyState.initial());

  final FacilityRepository repository;

  Future<void> verify({
    String? membershipId,
    String? phoneNumber,
    String? householdCode,
    String? fullName,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearResult: true));
    try {
      final result = await repository.verifyEligibility(
        membershipId: membershipId,
        phoneNumber: phoneNumber,
        householdCode: householdCode,
        fullName: fullName,
      );
      emit(state.copyWith(isLoading: false, result: result));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void clear() {
    emit(VerifyState.initial());
  }
}
