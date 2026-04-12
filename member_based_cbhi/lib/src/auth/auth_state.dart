import 'package:equatable/equatable.dart';

import '../cbhi_data.dart';

enum AuthStatus { checking, unauthenticated, guest, authenticated }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    required this.isBusy,
    this.session,
    this.error,
  });

  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.checking, isBusy: false);
  }

  final AuthStatus status;
  final bool isBusy;
  final AuthSession? session;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;
  bool get isFamilyMember => session?.user.role?.toUpperCase() == 'BENEFICIARY';
  bool get isHouseholdHead =>
      session?.user.role?.toUpperCase() == 'HOUSEHOLD_HEAD';
  bool get isFacilityStaff =>
      session?.user.role?.toUpperCase() == 'HEALTH_FACILITY_STAFF';
  bool get isAdmin =>
      session?.user.role?.toUpperCase() == 'SYSTEM_ADMIN' ||
      session?.user.role?.toUpperCase() == 'CBHI_OFFICER';

  AuthState copyWith({
    AuthStatus? status,
    bool? isBusy,
    AuthSession? session,
    String? error,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isBusy: isBusy ?? this.isBusy,
      session: clearSession ? null : session ?? this.session,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, isBusy, session, error];
}
