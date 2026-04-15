/**
 * TypeORM DataSource for CLI migrations.
 *
 * Supports both local PostgreSQL and Supabase (via DATABASE_URL or individual vars).
 *
 * Usage:
 *   npx typeorm migration:generate src/database/migrations/MyMigration -d src/database/data-source.ts
 *   npx typeorm migration:run -d src/database/data-source.ts
 *   npx typeorm migration:revert -d src/database/data-source.ts
 *
 * For Supabase, set DATABASE_URL in your environment:
 *   DATABASE_URL=postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres?sslmode=require
 */
import 'dotenv/config';
import { join } from 'path';
import { DataSource, DataSourceOptions } from 'typeorm';

function buildDataSourceOptions(): DataSourceOptions {
  const databaseUrl = process.env.DATABASE_URL;

  if (databaseUrl) {
    // Supabase / any Postgres connection string
    return {
      type: 'postgres',
      url: databaseUrl,
      ssl: databaseUrl.includes('sslmode=require') || process.env.DB_SSL === 'true'
        ? { rejectUnauthorized: false }
        : false,
      entities: [join(__dirname, '..', '**', '*.entity.{js,ts}')],
      migrations: [join(__dirname, 'migrations', '*.{js,ts}')],
      synchronize: false,
      logging: process.env.TYPEORM_LOGGING === 'true',
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
    synchronize: false, // NEVER true in production
    logging: process.env.TYPEORM_LOGGING === 'true',
  };
}

export const AppDataSource = new DataSource(buildDataSourceOptions());
