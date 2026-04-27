import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

/** Maps HTTP status codes to their standard reason phrases. */
const HTTP_STATUS_TEXTS: Record<number, string> = {
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not Found',
  405: 'Method Not Allowed',
  408: 'Request Timeout',
  409: 'Conflict',
  410: 'Gone',
  422: 'Unprocessable Entity',
  429: 'Too Many Requests',
  500: 'Internal Server Error',
  502: 'Bad Gateway',
  503: 'Service Unavailable',
  504: 'Gateway Timeout',
};

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);
  private readonly isProduction = process.env.NODE_ENV === 'production';

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string = 'An unexpected error occurred.';
    let error = 'Internal Server Error';
    let retryable = false;

    if (exception instanceof HttpException) {
      statusCode = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'string') {
        message = exceptionResponse;
      } else if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const resp = exceptionResponse as Record<string, unknown>;
        const rawMessage = resp['message'];
        // class-validator returns message as string[] — join into a single string
        // so Flutter clients always receive a plain string in the message field
        if (Array.isArray(rawMessage)) {
          message = rawMessage.join(', ');
        } else {
          message = (rawMessage as string | undefined) ?? exception.message;
        }
        // Normalize error to standard HTTP reason phrase, not the exception class name
        error = (resp['error'] as string | undefined) ??
          HTTP_STATUS_TEXTS[statusCode] ??
          'Error';
      }
      // 429 Too Many Requests and 5xx errors are typically retryable
      retryable = statusCode === 429 || statusCode >= 500;
    } else if (exception instanceof Error) {
      const errorName = exception.constructor.name;
      
      // Handle common Database errors
      if (errorName.includes('QueryFailedError') || errorName.includes('Connection')) {
        statusCode = HttpStatus.SERVICE_UNAVAILABLE;
        message = 'The database is currently busy or unavailable. Please try again in a few seconds.';
        error = 'Database Error';
        retryable = true;
      } else {
        message = this.isProduction 
          ? 'A system error occurred. Our team has been notified.' 
          : exception.message;
      }

      this.logger.error(
        `Unhandled exception [${errorName}]: ${exception.message}`,
        this.isProduction ? undefined : exception.stack,
      );
      this.reportToSentry(exception, request);
    }

    const body = {
      statusCode,
      message,
      error,
      retryable,
      timestamp: new Date().toISOString(),
      path: request.url,
      // Provide developer-specific info in non-prod
      ...(this.isProduction ? {} : { stack: exception instanceof Error ? exception.stack : String(exception) }),
    };

    if (statusCode >= 500) {
      this.logger.error(`[${request.method}] ${request.url} → ${statusCode}`);
    }

    response.status(statusCode).json(body);
  }

  private reportToSentry(error: Error, request: Request): void {
    try {
      // Dynamic import to avoid hard dependency — Sentry is optional
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Sentry = require('@sentry/node') as typeof import('@sentry/node');
      Sentry.withScope((scope) => {
        scope.setTag('url', request.url);
        scope.setTag('method', request.method);
        scope.setExtra('headers', {
          'user-agent': request.headers['user-agent'],
          'content-type': request.headers['content-type'],
        });
        Sentry.captureException(error);
      });
    } catch {
      // Sentry not available — silently skip
    }
  }
}
