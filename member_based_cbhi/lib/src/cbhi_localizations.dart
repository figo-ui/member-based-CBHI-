import 'package:flutter/material.dart';

import 'i18n/app_localizations.dart' as i18n;

/// Public API for member-app strings (en / am / om).
///
/// Implementation lives in `i18n/app_localizations.dart`; UI and tests should
/// import **this** file only, not `i18n/app_localizations.dart` directly.
abstract final class CbhiLocalizations {
  CbhiLocalizations._();

  static i18n.AppLocalizations of(BuildContext context) =>
      i18n.AppLocalizations.of(context);

  static Locale resolveFrameworkLocale(Locale locale) =>
      i18n.AppLocalizations.resolveFrameworkLocale(locale);

  static List<Locale> get frameworkSupportedLocales =>
      i18n.AppLocalizations.frameworkSupportedLocales;

  static List<Locale> get supportedLocales => i18n.AppLocalizations.supportedLocales;

  static LocalizationsDelegate<i18n.AppLocalizations> delegateFor(Locale locale) =>
      i18n.AppLocalizations.delegateFor(locale);
}
