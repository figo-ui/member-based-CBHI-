// FIX ME-4: BLoC for admin overview/dashboard screen

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';

class OverviewState extends Equatable {
  const OverviewState({
    required this.report,
    required this.isLoading,
    this.error,
  });

  factory OverviewState.initial() => const OverviewState(
        report: {},
        isLoading: false,
      );

  final Map<String, dynamic> report;
  final bool isLoading;
  final String? error;

  OverviewState copyWith({
    Map<String, dynamic>? report,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OverviewState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [report, isLoading, error];
}

class OverviewCubit extends Cubit<OverviewState> {
  OverviewCubit(this.repository) : super(OverviewState.initial());

  final AdminRepository repository;

  Future<void> load({String? from, String? to}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final report = await repository.getSummaryReport(from: from, to: to);
      emit(state.copyWith(report: report, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
