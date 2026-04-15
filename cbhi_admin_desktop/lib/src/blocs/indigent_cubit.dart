// FIX ME-4: BLoC for admin indigent applications screen

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';

class IndigentState extends Equatable {
  const IndigentState({
    required this.applications,
    required this.isLoading,
    required this.isReviewing,
    this.error,
    this.successMessage,
  });

  factory IndigentState.initial() => const IndigentState(
        applications: [],
        isLoading: false,
        isReviewing: false,
      );

  final List<Map<String, dynamic>> applications;
  final bool isLoading;
  final bool isReviewing;
  final String? error;
  final String? successMessage;

  IndigentState copyWith({
    List<Map<String, dynamic>>? applications,
    bool? isLoading,
    bool? isReviewing,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return IndigentState(
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      isReviewing: isReviewing ?? this.isReviewing,
      error: clearError ? null : error ?? this.error,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [applications, isLoading, isReviewing, error, successMessage];
}

class IndigentCubit extends Cubit<IndigentState> {
  IndigentCubit(this.repository) : super(IndigentState.initial());

  final AdminRepository repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final apps = await repository.getPendingIndigent();
      emit(state.copyWith(applications: apps, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> review({
    required String applicationId,
    required String status,
    String? reason,
  }) async {
    emit(state.copyWith(isReviewing: true, clearError: true));
    try {
      await repository.reviewIndigent(
        applicationId: applicationId,
        status: status,
        reason: reason,
      );
      await load();
      emit(state.copyWith(isReviewing: false, successMessage: 'Application $status'));
    } catch (e) {
      emit(state.copyWith(isReviewing: false, error: e.toString()));
    }
  }
}
