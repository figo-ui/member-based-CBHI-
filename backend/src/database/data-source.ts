/**
 * TypeORM DataSource for CLI migrations.
 *
 * Supports both local PostgreSQL and Supabase (via DATABASE_URL or individual vars).
 * Handles URL-encoded passwords and Supabase pgBouncer pooler correctly.
 *
 * Usage:
 *   npx typeorm migration:run -d src/database/data-source.ts
 *   npx typeorm migration:revert -d src/database/data-source.ts
 */
import 'dotenv/config';
import { join } from 'path';
import { DataSource, DataSourceOptions } from 'typeorm';

function parseConnectionUrl(rawUrl: string): {
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
  ssl: boolean;
} {
  const u = new URL(rawUrl);
  return {
    host: u.hostname,
    port: u.port ? Number(u.port) : 5432,
    // decodeURIComponent handles %23 → #, %40 → @, %2C → , etc.
    username: decodeURIComponent(u.username),
    password: decodeURIComponent(u.password),
    database: u.pathname.replace(/^\//, ''),
    ssl: u.searchParams.get('sslmode') === 'require' || u.searchParams.get('sslmode') === 'verify-ca',
  };
}

function buildDataSourceOptions(): DataSourceOptions {
  const databaseUrl = process.env.DATABASE_URL;

  if (databaseUrl) {
    const conn = parseConnectionUrl(databaseUrl);
    const isPooler = conn.port === 6543; // Supabase transaction pooler port

    return {
      type: 'postgres',
      host: conn.host,
      port: conn.port,
      username: conn.username,
      password: conn.password,
      database: conn.database,
      ssl: conn.ssl ? { rejectUnauthorized: false } : false,
      entities: [join(__dirname, '..', '**', '*.entity.{js,ts}')],
      migrations: [join(__dirname, 'migrations', '*.{js,ts}')],
      synchronize: false,
      logging: process.env.TYPEORM_LOGGING === 'true',
      // pgBouncer transaction pooler requires this
      ...(isPooler ? { extra: { options: '-c statement_timeout=30000' } } : {}),
    };
  }

  // Individual environment variables (local dev / Docker)
  return {
    type: 'postgres',
    host: process.env.DB_HOST ?? 'localhost',
    port: Number(process.env.DB_PORT ?? 5432),
    username: process.env.DB_USERNAME ?? 'postgres',
    password: process.env.DB_PASSWORD ?? 'postgres',
    database: process.env.DB_NAME ?? 'cbhi_db',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    entities: [join(__dirname, '..', '**', '*.entity.{js,ts}')],
    migrations: [join(__dirname, 'migrations', '*.{js,ts}')],
    synchronize: false,
    logging: process.env.TYPEORM_LOGGING === 'true',
  };
}

export const AppDataSource = new DataSource(buildDataSourceOptions());
