// FIX ME-4: BLoC for facility claim tracker screen — replaces raw setState

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/facility_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ClaimTrackerState extends Equatable {
  const ClaimTrackerState({
    required this.claims,
    required this.isLoading,
    this.error,
  });

  factory ClaimTrackerState.initial() => const ClaimTrackerState(
        claims: [],
        isLoading: false,
      );

  final List<Map<String, dynamic>> claims;
  final bool isLoading;
  final String? error;

  ClaimTrackerState copyWith({
    List<Map<String, dynamic>>? claims,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClaimTrackerState(
      claims: claims ?? this.claims,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [claims, isLoading, error];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class ClaimTrackerCubit extends Cubit<ClaimTrackerState> {
  ClaimTrackerCubit(this.repository) : super(ClaimTrackerState.initial());

  final FacilityRepository repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final claims = await repository.getClaims();
      emit(state.copyWith(claims: claims, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
