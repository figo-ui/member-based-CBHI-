// FIX ME-4: BLoC state management for admin app claims screen.
// Replaces raw setState calls with proper Cubit-based state management.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ClaimsState extends Equatable {
  const ClaimsState({
    required this.claims,
    required this.isLoading,
    required this.isReviewing,
    this.filter = 'ALL',
    this.searchQuery = '',
    this.error,
    this.successMessage,
  });

  factory ClaimsState.initial() => const ClaimsState(
        claims: [],
        isLoading: false,
        isReviewing: false,
      );

  final List<Map<String, dynamic>> claims;
  final bool isLoading;
  final bool isReviewing;
  final String filter;
  final String searchQuery;
  final String? error;
  final String? successMessage;

  List<Map<String, dynamic>> get filtered {
    var list = filter == 'ALL'
        ? claims
        : claims.where((c) => c['status'] == filter).toList();

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((c) {
        final claimNum = c['claimNumber']?.toString().toLowerCase() ?? '';
        final beneficiary = c['beneficiaryName']?.toString().toLowerCase() ?? '';
        final household = c['householdCode']?.toString().toLowerCase() ?? '';
        return claimNum.contains(q) ||
            beneficiary.contains(q) ||
            household.contains(q);
      }).toList();
    }
    return list;
  }

  ClaimsState copyWith({
    List<Map<String, dynamic>>? claims,
    bool? isLoading,
    bool? isReviewing,
    String? filter,
    String? searchQuery,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ClaimsState(
      claims: claims ?? this.claims,
      isLoading: isLoading ?? this.isLoading,
      isReviewing: isReviewing ?? this.isReviewing,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      error: clearError ? null : error ?? this.error,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        claims,
        isLoading,
        isReviewing,
        filter,
        searchQuery,
        error,
        successMessage,
      ];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class ClaimsCubit extends Cubit<ClaimsState> {
  ClaimsCubit(this.repository) : super(ClaimsState.initial());

  final AdminRepository repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    try {
      final claims = await repository.getClaims();
      emit(state.copyWith(claims: claims, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setFilter(String filter) {
    emit(state.copyWith(filter: filter, clearError: true));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query.trim()));
  }

  Future<void> reviewClaim({
    required String claimId,
    required String status,
    double? approvedAmount,
    String? decisionNote,
  }) async {
    emit(state.copyWith(isReviewing: true, clearError: true, clearSuccess: true));
    try {
      await repository.reviewClaim(
        claimId: claimId,
        status: status,
        approvedAmount: approvedAmount,
        decisionNote: decisionNote,
      );
      await load();
      emit(state.copyWith(
        isReviewing: false,
        successMessage: 'Claim updated to $status',
      ));
    } catch (e) {
      emit(state.copyWith(isReviewing: false, error: e.toString()));
    }
  }
}
