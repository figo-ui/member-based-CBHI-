/**
 * Production migration runner — uses compiled dist/ (no ts-node required).
 * Called by railway.toml startCommand and Dockerfile CMD before starting the server.
 *
 * Works with both:
 *   - Railway (env vars injected directly — no .env file)
 *   - Docker / local (reads from .env file via dotenv)
 *
 * Usage: node scripts/run-migrations-prod.js
 */

// Only load .env file if not already set by the platform (Railway injects vars directly)
if (!process.env.DB_HOST && !process.env.DATABASE_URL) {
  try {
    require('dotenv').config({ path: '.env' });
  } catch (_) {
    // dotenv not available — env vars must be set by the platform
  }
}

const { AppDataSource } = require('../dist/database/data-source');

async function main() {
  console.log('[MIGRATION] Connecting to database...');

  await AppDataSource.initialize();
  console.log('[MIGRATION] Connected.');

  const pending = await AppDataSource.showMigrations();
  if (!pending) {
    console.log('[MIGRATION] All migrations already applied. Nothing to do.');
    await AppDataSource.destroy();
    return;
  }

  console.log('[MIGRATION] Running pending migrations...');
  const ran = await AppDataSource.runMigrations({ transaction: 'each' });
  console.log(`[MIGRATION] Applied ${ran.length} migration(s):`, ran.map(m => m.name));

  await AppDataSource.destroy();
  console.log('[MIGRATION] Done.');
}

main().catch(err => {
  console.error('[MIGRATION] FAILED:', err.message);
  process.exit(1);
});
