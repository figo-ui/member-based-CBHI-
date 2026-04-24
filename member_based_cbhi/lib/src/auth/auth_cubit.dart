import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cbhi_data.dart';
import '../registration/models/personal_info_model.dart';
import '../shared/fcm_service.dart';
import 'auth_state.dart';

const _kWasGuestKey = 'cbhi_was_guest';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this.repository) : super(AuthState.initial());

  final CbhiRepository repository;

  Future<void> _registerFcmToken() async {
    try {
      final token = await FcmService.instance.init();
      if (token != null && token.isNotEmpty) {
        await repository.registerFcmToken(token);
        FcmService.instance.onTokenRefresh((newToken) async {
          try {
            await repository.registerFcmToken(newToken);
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  /// After registration, the API may persist a session — pick it up without OTP.
  /// If online registration succeeded, the session is already stored.
  /// If offline, we create a minimal local session so the dashboard opens.
  Future<void> adoptRegisteredSession({
    PersonalInfoModel? personalInfo,
    CbhiSnapshot? offlineSnapshot,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWasGuestKey);

    emit(state.copyWith(isBusy: true, clearError: true));

    // Try to get the real session (stored by _storeAuthIfPresent during online registration)
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      final session = await repository.restoreSession();
      if (session != null) {
        emit(state.copyWith(
          isBusy: false,
          status: AuthStatus.authenticated,
          session: session,
          clearError: true,
        ));
        return;
      }
    }

    // No real session — build a minimal local session from registration data
    // so the dashboard opens immediately (online or offline).
    // The real session will be established when the user signs in next time.
    if (personalInfo != null) {
      final localSession = AuthSession(
        accessToken: 'pending-sync',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        user: AppUserProfile(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          displayName: '${personalInfo.firstName} ${personalInfo.lastName}',
          firstName: personalInfo.firstName,
          lastName: personalInfo.lastName,
          phoneNumber: personalInfo.phone,
          email: personalInfo.email,
          role: 'HOUSEHOLD_HEAD',
          householdCode: offlineSnapshot?.householdCode,
        ),
      );
      emit(state.copyWith(
        isBusy: false,
        status: AuthStatus.authenticated,
        session: localSession,
        clearError: true,
      ));
      return;
    }

    // Absolute fallback — stay unauthenticated
    emit(state.copyWith(isBusy: false));
  }

  Future<void> bootstrap() async {
    emit(state.copyWith(status: AuthStatus.checking, clearError: true));
    try {
      final session = await repository.restoreSession();
      final isAuth = session != null;

      if (!isAuth) {
        // On web, a page refresh loses in-memory state.
        // Restore guest/registration mode from persisted flag.
        final prefs = await SharedPreferences.getInstance();
        final wasGuest = prefs.getBool(_kWasGuestKey) ?? false;
        if (wasGuest) {
          emit(state.copyWith(status: AuthStatus.guest, clearError: true));
          return;
        }
      }

      emit(state.copyWith(
        status: isAuth ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        session: session,
        clearError: true,
      ));
      if (isAuth) unawaited(_registerFcmToken());
    } catch (error) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: error.toString(),
      ));
    }
  }

  Future<void> refreshSession() async {
    try {
      final session = await repository.restoreSession();
      emit(state.copyWith(
        status: session == null
            ? (state.isGuest ? AuthStatus.guest : AuthStatus.unauthenticated)
            : AuthStatus.authenticated,
        session: session,
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> continueAsGuest() async {
    // Persist so web refresh restores registration mode
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWasGuestKey, true);
    emit(state.copyWith(
      status: AuthStatus.guest,
      clearSession: true,
      clearError: true,
    ));
  }

  Future<void> leaveGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWasGuestKey);
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      clearSession: true,
      clearError: true,
    ));
  }

  Future<OtpChallenge?> sendOtp({String? phoneNumber, String? email}) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final challenge = await repository.sendOtp(
        phoneNumber: phoneNumber,
        email: email,
      );
      emit(state.copyWith(isBusy: false, clearError: true));
      return challenge;
    } catch (error) {
      emit(state.copyWith(isBusy: false, error: error.toString()));
      return null;
    }
  }

  Future<OtpChallenge?> requestFamilyMemberOtp({
    required String phoneNumber,
    String? membershipId,
    String? householdCode,
    String? fullName,
  }) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final challenge = await repository.requestFamilyMemberOtp(
        phoneNumber: phoneNumber,
        membershipId: membershipId,
        householdCode: householdCode,
        fullName: fullName,
      );
      emit(state.copyWith(isBusy: false, clearError: true));
      return challenge;
    } catch (error) {
      emit(state.copyWith(isBusy: false, error: error.toString()));
      return null;
    }
  }

  Future<OtpChallenge?> forgotPassword(String identifier) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final challenge = await repository.forgotPassword(identifier);
      emit(state.copyWith(isBusy: false, clearError: true));
      return challenge;
    } catch (error) {
      emit(state.copyWith(isBusy: false, error: error.toString()));
      return null;
    }
  }

  Future<bool> verifyOtp({
    String? phoneNumber,
    String? email,
    required String code,
  }) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final session = await repository.verifyOtp(
        phoneNumber: phoneNumber,
        email: email,
        code: code,
      );
      emit(state.copyWith(
        isBusy: false,
        status: AuthStatus.authenticated,
        session: session,
        clearError: true,
      ));
      return true;
    } catch (error) {
      emit(state.copyWith(isBusy: false, error: error.toString()));
      return false;
    }
  }

  Future<bool> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final session = await repository.loginWithPassword(
        identifier: identifier,
        password: password,
      );
      emit(state.copyWith(
        isBusy: false,
        status: AuthStatus.authenticated,
        session: session,
        clearError: true,
      ));
      return true;
    } catch (error) {
      emit(state.copyWith(isBusy: false, error: error.toString()));
      return false;
    }
  }

  Future<bool> loginFamilyMemberWithPassword({
    required String phoneNumber,
    String? membershipId,
    String? householdCode,
    String? fullName,
    required String password,
  }) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final session = await repository.loginFamilyMemberWithPassword(
        phoneNumber: phoneNumber,
        membershipId: membershipId,
        householdCode: householdCode,
        fullName: fullName,
        password: password,
      );
      emit(state.copyWith(
        isBusy: false,
        status: AuthStatus.authenticated,
        session: session,
        clearError: true,
      ));
      return true;
    } catch (error) {
      emit(state.copyWith(isBusy: false, error: error.toString()));
      return false;
    }
  }

  Future<bool> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      await repository.resetPassword(
        identifier: identifier,
        code: code,
        newPassword: newPassword,
      );
      emit(state.copyWith(isBusy: false, clearError: true));
      return true;
    } catch (error) {
      emit(state.copyWith(isBusy: false, error: error.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWasGuestKey);
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      clearSession: true,
      clearError: true,
    ));
  }

  Future<bool> loginWithStoredToken(String accessToken) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final session = await repository.restoreSessionFromToken(accessToken);
      if (session == null) {
        emit(state.copyWith(
          isBusy: false,
          error: 'Session expired. Please sign in again.',
        ));
        return false;
      }
      emit(state.copyWith(
        isBusy: false,
        status: AuthStatus.authenticated,
        session: session,
        clearError: true,
      ));
      return true;
    } catch (error) {
      emit(state.copyWith(isBusy: false, error: error.toString()));
      return false;
    }
  }
}
