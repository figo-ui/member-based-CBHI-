import { ConsoleLogger, Injectable, LogLevel } from '@nestjs/common';

/**
 * FIX MJ-8: Structured JSON logger for production.
 * - Development: pretty-prints to console with colors
 * - Production: outputs newline-delimited JSON for log aggregators
 *   (CloudWatch, Datadog, Loki, etc.)
 *
 * Log fields follow the OpenTelemetry semantic conventions:
 *   level, timestamp, context, message, pid, env, version
 */
@Injectable()
export class CbhiLogger extends ConsoleLogger {
  private readonly isProduction = process.env.NODE_ENV === 'production';
  private readonly appVersion = process.env.npm_package_version ?? '1.0.0';
  private readonly appEnv = process.env.NODE_ENV ?? 'development';

  protected formatMessage(
    logLevel: LogLevel,
    message: unknown,
    pidMessage: string,
    formattedLogLevel: string,
    contextMessage: string,
    timestampDiff: string,
  ): string {
    if (!this.isProduction) {
      return super.formatMessage(
        logLevel,
        message,
        pidMessage,
        formattedLogLevel,
        contextMessage,
        timestampDiff,
      );
    }

    // Structured JSON for production — one JSON object per line
    const entry: Record<string, unknown> = {
      level: logLevel,
      timestamp: new Date().toISOString(),
      context: this.context ?? 'App',
      message: typeof message === 'string' ? message : JSON.stringify(message),
      pid: process.pid,
      env: this.appEnv,
      version: this.appVersion,
    };

    // Attach error stack if message is an Error
    if (message instanceof Error) {
      entry.message = message.message;
      entry.stack = message.stack;
      entry.errorName = message.name;
    }

    return JSON.stringify(entry) + '\n';
  }

  /**
   * Log a structured event with additional metadata fields.
   * Use this for business-critical events (payment, claim, auth).
   */
  logEvent(
    event: string,
    data: Record<string, unknown>,
    context?: string,
  ): void {
    const entry: Record<string, unknown> = {
      level: 'log',
      timestamp: new Date().toISOString(),
      context: context ?? this.context ?? 'App',
      event,
      pid: process.pid,
      env: this.appEnv,
      version: this.appVersion,
      ...data,
    };

    if (this.isProduction) {
      process.stdout.write(JSON.stringify(entry) + '\n');
    } else {
      this.log(`[${event}] ${JSON.stringify(data)}`, context);
    }
  }
}
