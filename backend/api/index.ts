  /**
 * Vercel serverless entry point for NestJS.
 * Wraps the NestJS app as an Express handler for Vercel's serverless runtime.
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

async function createApp(): Promise<NestExpressApplication> {
  if (cachedApp) return cachedApp;

  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    cors: false,
    logger: new CbhiLogger(),
  });

  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

  const allowedOrigins = (
    process.env.CORS_ALLOWED_ORIGINS ??
    'https://member-based-cbhi.vercel.app,https://cbhi-admin.vercel.app,https://cbhi-facility.vercel.app'
  )
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  // Wildcard patterns (e.g. "*.vercel.app") extracted separately
  const wildcardPatterns = allowedOrigins
    .filter((o) => o.startsWith('*.'))
    .map((o) => new RegExp(`^https?://${o.slice(2).replace(/\./g, '\\.')}$`));

  const exactOrigins = allowedOrigins.filter((o) => !o.startsWith('*.'));

  app.enableCors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      // Exact match or wildcard '*'
      if (exactOrigins.includes(origin) || exactOrigins.includes('*')) {
        return callback(null, true);
      }
      // Wildcard pattern match (e.g. *.vercel.app)
      if (wildcardPatterns.some((re) => re.test(origin))) {
        return callback(null, true);
      }
      // Always allow all *.vercel.app preview deployments
      if (/^https:\/\/[^.]+\.vercel\.app$/.test(origin)) {
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

  // --- Swagger Configuration ---
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
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  await app.init();
  cachedApp = app;
  return app;
}

// Vercel serverless handler
export default async function handler(req: Request, res: Response) {
  // Root path — return API info without going through NestJS
  if (req.url === '/' || req.url === '') {
    res.setHeader('Content-Type', 'application/json');
    res.status(200).json({
      name: 'Maya City CBHI API',
      version: '1.0.0',
      status: 'ok',
      docs: '/api/v1/docs',
    });
    return;
  }

  // Handle OPTIONS preflight immediately — before NestJS boots.
  // This prevents cold-start latency from blocking CORS preflight checks.
  if (req.method === 'OPTIONS') {
    const origin = req.headers['origin'] as string | undefined;
    const isAllowed =
      !origin ||
      /^https:\/\/[^.]+\.vercel\.app$/.test(origin) ||
      (process.env.CORS_ALLOWED_ORIGINS ?? '')
        .split(',')
        .map((o) => o.trim())
        .includes(origin);

    if (isAllowed || !origin) {
      res.setHeader('Access-Control-Allow-Origin', origin ?? '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
      res.setHeader('Access-Control-Allow-Credentials', 'true');
      res.setHeader('Access-Control-Max-Age', '86400'); // 24h preflight cache
      res.status(204).end();
      return;
    }
  }

  const app = await createApp();
  const expressApp = app.getHttpAdapter().getInstance();
  return expressApp(req, res);
}
