import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'src/cbhi_app.dart';
import 'src/cbhi_data.dart';
import 'src/shared/background_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent flutter_animate from crashing when a widget is disposed
  // before its delayed animation fires (e.g., list items that scroll off-screen).
  Animate.restartOnHotReload = false;

  // Start background connectivity listener before anything else
  BackgroundSyncService.instance.start();

  final repository = await CbhiRepository.create();

  // FIX MJ-8: Initialize Sentry for Flutter error tracking.
  // Set SENTRY_DSN via --dart-define=SENTRY_DSN=https://... at build time.
  // Leave empty in development to disable.
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = const String.fromEnvironment(
          'APP_ENV',
          defaultValue: 'production',
        );
        options.tracesSampleRate = 0.1; // 10% of transactions
        options.attachScreenshot = false; // Disable for privacy
        options.attachViewHierarchy = false;
        // Scrub PII from breadcrumbs
        options.beforeBreadcrumb = (breadcrumb, hint) {
          // Don't log navigation to sensitive screens
          if (breadcrumb?.category == 'navigation') {
            final to = breadcrumb?.data?['to']?.toString() ?? '';
            if (to.contains('otp') || to.contains('payment')) {
              return null; // Drop this breadcrumb
            }
          }
          return breadcrumb;
        };
      },
      appRunner: () => runApp(CbhiApp(repository: repository)),
    );
  } else {
    runApp(CbhiApp(repository: repository));
  }
}
