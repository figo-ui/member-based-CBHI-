import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cbhi_data.dart';

// SharedPreferences keys for persisted UI preferences
const _kLocaleKey = 'cbhi_locale';
const _kDarkModeKey = 'cbhi_dark_mode';

class AppState extends Equatable {
  const AppState({
    required this.snapshot,
    required this.locale,
    required this.isLoading,
    required this.isSyncing,
    this.error,
    this.themeMode = ThemeMode.light,
  });

  factory AppState.initial() {
    return const AppState(
      snapshot: null,
      locale: Locale('en'),
      isLoading: true,
      isSyncing: false,
      themeMode: ThemeMode.system,
    );
  }

  final CbhiSnapshot? snapshot;
  final Locale locale;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final ThemeMode themeMode;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  AppState copyWith({
    CbhiSnapshot? snapshot,
    Locale? locale,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    ThemeMode? themeMode,
  }) {
    return AppState(
      snapshot: snapshot ?? this.snapshot,
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [
    snapshot,
    locale,
    isLoading,
    isSyncing,
    error,
    themeMode,
  ];
}

class AppCubit extends Cubit<AppState> {
  AppCubit(this.repository) : super(AppState.initial());

  final CbhiRepository repository;


  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // Restore persisted locale and dark mode preference
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_kLocaleKey);
      final savedTheme = prefs.getString(_kDarkModeKey) ?? 'system';
      final ThemeMode themeMode = switch (savedTheme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.system,
      };
      final locale = savedLocale != null ? Locale(savedLocale) : const Locale('en');

      final snapshot = await repository.loadCachedSnapshot();
      emit(state.copyWith(
        snapshot: snapshot,
        isLoading: false,
        locale: locale,
        themeMode: themeMode,
      ));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> sync() async {
    emit(state.copyWith(isSyncing: true, error: null));
    try {
      final householdCode = state.snapshot?.householdCode;
      final snapshot = await repository.sync(
        householdCode?.isEmpty ?? true ? null : householdCode,
      );
      emit(state.copyWith(snapshot: snapshot, isSyncing: false));
    } catch (error) {
      emit(state.copyWith(isSyncing: false, error: error.toString()));
    }
  }

  Future<void> renewCoverage({
    String? paymentMethod,
    String? providerName,
    String? receiptNumber,
  }) async {
    emit(state.copyWith(isSyncing: true, error: null));
    try {
      final snapshot = await repository.renewCoverage(
        paymentMethod: paymentMethod,
        providerName: providerName,
        receiptNumber: receiptNumber,
      );
      emit(state.copyWith(snapshot: snapshot, isSyncing: false));
    } catch (error) {
      emit(state.copyWith(isSyncing: false, error: error.toString()));
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      final notifications = await repository.markNotificationRead(notificationId);
      final currentSnapshot = state.snapshot ?? CbhiSnapshot.empty();
      emit(
        state.copyWith(
          snapshot: currentSnapshot.copyWith(notifications: notifications),
        ),
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
    // Persist locale so it survives app restarts
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_kLocaleKey, locale.languageCode),
    );
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_kDarkModeKey, mode.name),
    );
  }

  void toggleDarkMode() {
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  Future<void> refreshFromCache() async {
    final snapshot = await repository.loadCachedSnapshot();
    emit(state.copyWith(snapshot: snapshot));
  }
}
