import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/app_localizations.dart';

/// Public API for member-app strings (en / am / om).
///
/// All UI code should import THIS file only and call:
///   CbhiLocalizations.of(context).t('key')
///   CbhiLocalizations.of(context).f('key', {'param': value})
abstract final class CbhiLocalizations {
  CbhiLocalizations._();

  static AppLocalizations of(BuildContext context) =>
      AppLocalizations.of(context);

  static Locale resolveFrameworkLocale(Locale locale) =>
      switch (locale.languageCode) {
        'am' => const Locale('am'),
        'om' => const Locale('om'),
        _ => const Locale('en'),
      };

  static List<Locale> get frameworkSupportedLocales =>
      AppLocalizations.supportedLocales;

  static List<Locale> get supportedLocales =>
      AppLocalizations.supportedLocales;

  /// Returns all localization delegates needed for MaterialApp.
  static List<LocalizationsDelegate<dynamic>> get delegates => [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static LocalizationsDelegate<AppLocalizations> delegateFor(Locale locale) =>
      AppLocalizations.delegate;
}
