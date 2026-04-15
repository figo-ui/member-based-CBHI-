/**
 * FIX MJ-5: Enforced migration runner.
 * Run before starting the server in production.
 * Fails fast if migrations cannot be applied.
 *
 * Usage: node scripts/run-migrations.js
 * Or via npm: npm run migration:run
 */
require('dotenv/config');
const { execSync } = require('child_process');

const isProduction = process.env.NODE_ENV === 'production';

if (process.env.TYPEORM_SYNCHRONIZE === 'true' && isProduction) {
  console.error(
    '[MIGRATION] FATAL: TYPEORM_SYNCHRONIZE=true is not allowed in production. ' +
    'Use migrations instead. Set TYPEORM_SYNCHRONIZE=false and run: npm run migration:run',
  );
  process.exit(1);
}

console.log('[MIGRATION] Running pending database migrations...');

try {
  execSync(
    'npx typeorm-ts-node-commonjs migration:run -d src/database/data-source.ts',
    { stdio: 'inherit' },
  );
  console.log('[MIGRATION] All migrations applied successfully.');
} catch (error) {
  console.error('[MIGRATION] Migration failed:', error.message);
  process.exit(1);
}
