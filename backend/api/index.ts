/**
 * Vercel serverless entry point for NestJS.
 *
 * Limitations on Vercel vs a persistent server:
 *   - Bull/Redis job queues are disabled (no persistent process)
 *   - WebSockets are disabled (serverless is stateless)
 *   - File uploads go to /tmp (ephemeral — use GCS in production)
 *   - Cold starts add ~1-2s latency on first request
 *
 * All core API functionality (auth, CBHI, claims, payments, admin) works fine.
 */

// ── Env fallbacks — set BEFORE any imports that read process.env ──────────────
// These ensure the function doesn't crash when Vercel dashboard vars are missing.
// URL-encode special chars in DB_PASSWORD: ! → %21, # → %23, @ → %40, , → %2C
if (!process.env.DATABASE_URL && !process.env.DB_HOST) {
  process.env.DATABASE_URL =
    'postgresql://postgres.nauyjsrhykayyzqomiyx:v%21GAPf%23g%2CMaa%405r@aws-0-eu-west-1.pooler.supabase.com:6543/postgres?sslmode=require';
}
if (!process.env.AUTH_JWT_SECRET) {
  process.env.AUTH_JWT_SECRET =
    'b5b35c8d9e8318f3021fc2bf320c3029d6659013a2b0b5863c9c26f92073c9bfabf7ea8320fbd49f7f1f83c6dee4af21';
}
if (!process.env.DIGITAL_CARD_SECRET) {
  process.env.DIGITAL_CARD_SECRET =
    'c2c27af2ce4cb269b3870c89a10d66f862f3d269de620231eaf7d529df44d235';
}
if (!process.env.NODE_ENV) {
  process.env.NODE_ENV = 'production';
}

import 'dotenv/config';
import '../src/instrument';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import { AppModule } from '../src/app.module';
import { GlobalExceptionFilter } from '../src/common/filters/global-exception.filter';
import { TimeoutInterceptor } from '../src/common/interceptors/timeout.interceptor';
import { CbhiLogger } from '../src/common/logger/cbhi-logger.service';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import type { Request, Response } from 'express';

let cachedApp: NestExpressApplication | null = null;
let initError: Error | null = null;

// ── CORS helpers ──────────────────────────────────────────────────────────────

/**
 * Returns true if the given origin is allowed.
 * Rules (in order):
 *  1. No origin (mobile apps, curl, Postman) → always allow
 *  2. Any *.vercel.app deployment → always allow (covers all preview + prod deployments)
 *  3. Exact match in CORS_ALLOWED_ORIGINS env var
 *  4. Wildcard pattern match (e.g. "*.example.com" entries in the env var)
 */
function isOriginAllowed(origin: string | undefined): boolean {
  if (!origin) return true;

  // Always allow any Vercel deployment (preview + production)
  if (/^https:\/\/[^.]+\.vercel\.app$/.test(origin)) return true;

  const rawOrigins = (
    process.env.CORS_ALLOWED_ORIGINS ??
    'https://member-based-cbhi.vercel.app,https://members-cbhi-app.vercel.app,https://cbhi-admin.vercel.app,https://cbhi-facility.vercel.app,http://localhost:3000,http://localhost:4200,http://10.0.2.2:3000'
  )
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  if (rawOrigins.includes('*')) return true;
  if (rawOrigins.includes(origin)) return true;

  const wildcardPatterns = rawOrigins
    .filter((o) => o.startsWith('*.'))
    .map((o) => new RegExp(`^https?://${o.slice(2).replace(/\./g, '\\.')}$`));

  return wildcardPatterns.some((re) => re.test(origin));
}

function setCorsHeaders(res: Response, origin: string | undefined): void {
  if (origin && isOriginAllowed(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Credentials', 'true');
  }
}

// ── App factory (cached across warm invocations) ──────────────────────────────

async function createApp(): Promise<NestExpressApplication> {
  if (cachedApp) return cachedApp;
  if (initError) throw initError;

  try {
    const app = await NestFactory.create<NestExpressApplication>(AppModule, {
      cors: false,
      logger: new CbhiLogger(),
    });

    app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

    app.enableCors({
      origin: (origin, callback) => {
        if (isOriginAllowed(origin)) {
          return callback(null, true);
        }
        return callback(new Error(`CORS: origin ${origin} not allowed`), false);
      },
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true,
      preflightContinue: false,
      optionsSuccessStatus: 204,
    });

    app.setGlobalPrefix('api/v1');
    app.useGlobalFilters(new GlobalExceptionFilter());
    app.useGlobalInterceptors(new TimeoutInterceptor(25_000));
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true, forbidUnknownValues: false }),
    );

    // Swagger docs
    const config = new DocumentBuilder()
      .setTitle('Maya City CBHI API')
      .setDescription('Community-Based Health Insurance Digital Platform API')
      .setVersion('1.0')
      .addBearerAuth()
      .addTag('auth', 'Authentication & session management')
      .addTag('cbhi', 'Member registration & household management')
      .addTag('facility', 'Health facility staff operations')
      .addTag('admin', 'CBHI officer & admin operations')
      .addTag('indigent', 'Indigent application management')
      .addTag('vision', 'Document text extraction & validation')
      .addTag('health', 'System health checks')
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/v1/docs', app, document, {
      customSiteTitle: 'Maya City CBHI API Docs',
      swaggerOptions: { persistAuthorization: true },
    });

    await app.init();
    cachedApp = app;
    return app;
  } catch (err) {
    // Cache the error so subsequent requests fail fast instead of retrying
    initError = err as Error;
    console.error('[Vercel] App initialization failed:', err);
    throw err;
  }
}

// ── Vercel serverless handler ─────────────────────────────────────────────────

export default async function handler(req: Request, res: Response) {
  const origin = req.headers['origin'] as string | undefined;

  // Root path — lightweight health/info response, no NestJS boot needed
  if (req.url === '/' || req.url === '') {
    setCorsHeaders(res, origin);
    res.setHeader('Content-Type', 'application/json');
    res.status(200).json({
      name: 'Maya City CBHI API',
      version: '1.0.0',
      status: 'ok',
      docs: '/api/v1/docs',
    });
    return;
  }

  // Handle OPTIONS preflight BEFORE NestJS boots — eliminates cold-start latency
  if (req.method === 'OPTIONS') {
    if (isOriginAllowed(origin)) {
      res.setHeader('Access-Control-Allow-Origin', origin ?? '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
      res.setHeader('Access-Control-Allow-Credentials', 'true');
      res.setHeader('Access-Control-Max-Age', '86400');
      res.status(204).end();
    } else {
      res.status(403).json({ message: `CORS: origin ${origin} not allowed` });
    }
    return;
  }

  try {
    const app = await createApp();
    const expressApp = app.getHttpAdapter().getInstance();
    return expressApp(req, res);
  } catch (err) {
    // Return a proper JSON error instead of crashing the function
    const message = err instanceof Error ? err.message : 'Internal server error';
    console.error('[Vercel] Handler error:', message);
    setCorsHeaders(res, origin);
    res.setHeader('Content-Type', 'application/json');
    res.status(503).json({
      statusCode: 503,
      message: 'Service temporarily unavailable. Please try again.',
      error: process.env.NODE_ENV !== 'production' ? message : undefined,
    });
  }
}
