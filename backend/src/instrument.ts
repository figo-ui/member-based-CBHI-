/**
 * FIX MJ-8: Sentry error tracking initialization.
 * This file MUST be imported at the very top of main.ts (before any other imports)
 * so Sentry can instrument all modules correctly.
 *
 * Set SENTRY_DSN in your .env to enable. Leave empty to disable.
 */
import * as Sentry from '@sentry/node';

const dsn = process.env.SENTRY_DSN;

if (dsn) {
  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV ?? 'development',
    release: process.env.npm_package_version ?? '1.0.0',
    // Capture 100% of transactions in development, 10% in production
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    // Capture 100% of errors
    sampleRate: 1.0,
    // Scrub PII from error reports
    beforeSend(event) {
      // Remove sensitive headers
      if (event.request?.headers) {
        delete event.request.headers['authorization'];
        delete event.request.headers['cookie'];
      }
      return event;
    },
    integrations: [
      Sentry.httpIntegration(),
      Sentry.expressIntegration(),
    ],
  });

  console.log(`[Sentry] Initialized for environment: ${process.env.NODE_ENV}`);
} else {
  console.log('[Sentry] SENTRY_DSN not set — error tracking disabled.');
}
