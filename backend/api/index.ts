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

  // Wildcard '*' → allow everything
  if (rawOrigins.includes('*')) return true;

  // Exact match
  if (rawOrigins.includes(origin)) return true;

  // Wildcard pattern match (e.g. "*.example.com")
  const wildcardPatterns = rawOrigins
    .filter((o) => o.startsWith('*.'))
    .map((o) => new RegExp(`^https?://${o.slice(2).replace(/\./g, '\\.')}$`));

  return wildcardPatterns.some((re) => re.test(origin));
}

// ── App factory (cached across warm invocations) ──────────────────────────────

async function createApp(): Promise<NestExpressApplication> {
  if (cachedApp) return cachedApp;

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

  // Swagger — always enabled (useful for debugging on Vercel)
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
}

// ── Vercel serverless handler ─────────────────────────────────────────────────

export default async function handler(req: Request, res: Response) {
  const origin = req.headers['origin'] as string | undefined;

  // Root path — lightweight health/info response, no NestJS boot needed
  if (req.url === '/' || req.url === '') {
    if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Content-Type', 'application/json');
    res.status(200).json({
      name: 'Maya City CBHI API',
      version: '1.0.0',
      status: 'ok',
      docs: '/api/v1/docs',
    });
    return;
  }

  // Handle OPTIONS preflight BEFORE NestJS boots.
  // This eliminates cold-start latency from blocking browser preflight checks.
  if (req.method === 'OPTIONS') {
    if (isOriginAllowed(origin)) {
      res.setHeader('Access-Control-Allow-Origin', origin ?? '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
      res.setHeader('Access-Control-Allow-Credentials', 'true');
      res.setHeader('Access-Control-Max-Age', '86400'); // cache preflight for 24h
      res.status(204).end();
    } else {
      res.status(403).json({ message: `CORS: origin ${origin} not allowed` });
    }
    return;
  }

  const app = await createApp();
  const expressApp = app.getHttpAdapter().getInstance();
  return expressApp(req, res);
}
