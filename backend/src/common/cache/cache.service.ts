import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';

/**
 * Distributed cache backed by Redis when REDIS_HOST is configured,
 * falling back to an in-process Map for local development.
 *
 * Redis setup (already in docker-compose.yml):
 *   REDIS_HOST=redis
 *   REDIS_PORT=6379
 *   REDIS_PASSWORD=cbhi_redis_pass
 *
 * This enables horizontal scaling — multiple backend instances share the same cache.
 */

interface CacheEntry<T> {
  value: T;
  expiresAt: number;
}

@Injectable()
export class CacheService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(CacheService.name);
  private readonly defaultTtlMs = 5 * 60 * 1000;

  // Redis client (dynamically imported to avoid hard dependency)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private redisClient: any = null;
  private useRedis = false;

  // In-memory fallback
  private readonly store = new Map<string, CacheEntry<unknown>>();

  async onModuleInit() {
    const host = process.env.REDIS_HOST;
    if (!host) {
      this.logger.warn('REDIS_HOST not set — using in-memory cache (not suitable for multi-instance)');
      return;
    }

    try {
      // Dynamic import so the app still starts without ioredis installed
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const ioredis = await import('ioredis');
      const Redis = ioredis.default ?? ioredis;
      this.redisClient = new (Redis as any)({
        host,
        port: Number(process.env.REDIS_PORT ?? 6379),
        password: process.env.REDIS_PASSWORD ?? undefined,
        lazyConnect: true,
        maxRetriesPerRequest: 3,
        connectTimeout: 5000,
        enableReadyCheck: true,
      });

      await this.redisClient.connect();
      this.useRedis = true;
      this.logger.log(`Redis cache connected at ${host}:${process.env.REDIS_PORT ?? 6379}`);
    } catch (error) {
      this.logger.warn(
        `Redis connection failed (${(error as Error).message}) — falling back to in-memory cache. ` +
        'Install ioredis: npm install ioredis',
      );
      this.redisClient = null;
      this.useRedis = false;
    }
  }

  async onModuleDestroy() {
    if (this.redisClient) {
      await this.redisClient.quit().catch(() => {});
    }
  }

  async get<T>(key: string): Promise<T | null> {
    if (this.useRedis && this.redisClient) {
      try {
        const raw = await this.redisClient.get(`cbhi:${key}`);
        if (!raw) return null;
        return JSON.parse(raw) as T;
      } catch (error) {
        this.logger.warn(`Redis GET failed for ${key}: ${(error as Error).message}`);
      }
    }

    // In-memory fallback
    const entry = this.store.get(key) as CacheEntry<T> | undefined;
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return entry.value;
  }

  async set<T>(key: string, value: T, ttlMs = this.defaultTtlMs): Promise<void> {
    if (this.useRedis && this.redisClient) {
      try {
        const ttlSeconds = Math.ceil(ttlMs / 1000);
        await this.redisClient.set(`cbhi:${key}`, JSON.stringify(value), 'EX', ttlSeconds);
        return;
      } catch (error) {
        this.logger.warn(`Redis SET failed for ${key}: ${(error as Error).message}`);
      }
    }

    this.store.set(key, { value, expiresAt: Date.now() + ttlMs });
  }

  async del(key: string): Promise<void> {
    if (this.useRedis && this.redisClient) {
      try {
        await this.redisClient.del(`cbhi:${key}`);
        return;
      } catch (error) {
        this.logger.warn(`Redis DEL failed for ${key}: ${(error as Error).message}`);
      }
    }
    this.store.delete(key);
  }

  async delByPrefix(prefix: string): Promise<void> {
    if (this.useRedis && this.redisClient) {
      try {
        const keys: string[] = await this.redisClient.keys(`cbhi:${prefix}*`);
        if (keys.length > 0) {
          await this.redisClient.del(...keys);
        }
        return;
      } catch (error) {
        this.logger.warn(`Redis DEL prefix failed for ${prefix}: ${(error as Error).message}`);
      }
    }

    for (const key of this.store.keys()) {
      if (key.startsWith(prefix)) this.store.delete(key);
    }
  }

  async getOrSet<T>(
    key: string,
    factory: () => Promise<T>,
    ttlMs = this.defaultTtlMs,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null) return cached;
    const value = await factory();
    await this.set(key, value, ttlMs);
    return value;
  }

  cleanup(): void {
    const now = Date.now();
    let cleaned = 0;
    for (const [key, entry] of this.store.entries()) {
      if (now > entry.expiresAt) {
        this.store.delete(key);
        cleaned++;
      }
    }
    if (cleaned > 0) {
      this.logger.debug(`In-memory cache cleanup: removed ${cleaned} expired entries`);
    }
  }
}
