import { join } from 'path';
import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { BullModule } from '@nestjs/bull';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminModule } from './admin/admin.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { BenefitPackageModule } from './benefit-packages/benefit-package.module';
import { CbhiModule } from './cbhi/cbhi.module';
import { CacheModule } from './common/cache/cache.module';
import { DemoModule } from './demo/demo.module';
import { GrievanceModule } from './grievances/grievance.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { RequestLoggerMiddleware } from './common/middleware/request-logger.middleware';
import { FacilityModule } from './facility/facility.module';
import { HealthFacilitiesModule } from './health-facilities/health-facilities.module';
import { HealthModule } from './health/health.module';
import { IndigentModule } from './indigent/indigent.module';
import { IntegrationsModule } from './integrations/integrations.module';
import { JobsModule } from './jobs/jobs.module';
import { LocationsModule } from './locations/locations.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PaymentGatewayModule } from './payment-gateway/payment-gateway.module';
import { SmsModule } from './sms/sms.module';
import { StorageModule } from './storage/storage.module';
import { VisionModule } from './vision/vision.module';

@Module({
  imports: [
    // ── Rate limiting ──────────────────────────────────────────────────────
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60_000,   // 1 minute window
        limit: 60,     // 60 requests per minute (general)
      },
      {
        name: 'otp',
        ttl: 600_000,  // 10 minute window
        limit: 5,      // 5 OTP requests per 10 minutes
      },
    ]),

    // FIX ME-7: Register Bull globally with Redis connection
    BullModule.forRoot({
      redis: {
        host: process.env.REDIS_HOST ?? 'localhost',
        port: Number(process.env.REDIS_PORT ?? 6379),
        password: process.env.REDIS_PASSWORD ?? undefined,
      },
    }),

    AdminModule,
    AuditModule,
    AuthModule,
    BenefitPackageModule,
    CacheModule,
    CbhiModule,
    DemoModule,
    FacilityModule,
    GrievanceModule,
    HealthFacilitiesModule,
    HealthModule,
    IndigentModule,
    IntegrationsModule,
    JobsModule,
    LocationsModule,
    NotificationsModule,
    PaymentGatewayModule,
    SmsModule,
    StorageModule,
    VisionModule,

    TypeOrmModule.forRoot({
      type: 'postgres',
      ...(process.env.DATABASE_URL
        ? {
            url: process.env.DATABASE_URL,
            ssl:
              process.env.DATABASE_URL.includes('sslmode=require') ||
              process.env.DB_SSL === 'true'
                ? { rejectUnauthorized: false }
                : false,
          }
        : {
            host: process.env.DB_HOST ?? 'localhost',
            port: Number(process.env.DB_PORT ?? 5432),
            username: process.env.DB_USERNAME ?? 'postgres',
            password: process.env.DB_PASSWORD ?? 'postgres',
            database: process.env.DB_NAME ?? 'cbhi_db',
            ssl:
              process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
          }),
      autoLoadEntities: true,
      entities: [join(__dirname, '**', '*.entity.{js,ts}')],
      // NEVER use synchronize:true in production — use migrations
      synchronize:
        process.env.TYPEORM_SYNCHRONIZE === 'true' ||
        process.env.NODE_ENV === 'development',
      logging: process.env.TYPEORM_LOGGING === 'true',
      // Connection pool — tune for your server capacity
      extra: {
        max: Number(process.env.DB_POOL_MAX ?? 20),
        min: Number(process.env.DB_POOL_MIN ?? 2),
        idleTimeoutMillis: 30_000,
        connectionTimeoutMillis: 5_000,
      },
    }),
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // ── Global rate limiting ───────────────────────────────────────────────
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    // ── Global JWT authentication (use @Public() to opt out) ──────────────
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    // ── Global role-based access control ──────────────────────────────────
    {
      provide: APP_GUARD,
      useClass: RolesGuard,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestLoggerMiddleware).forRoutes('*');
  }
}
