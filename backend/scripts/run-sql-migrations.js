/**
 * Runs the three Supabase SQL migration files in order.
 * Usage: node scripts/run-sql-migrations.js
 */
require('dotenv').config();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const migrations = [
  path.join(__dirname, '../../supabase/migrations/20240101000000_initial_schema.sql'),
  path.join(__dirname, '../../supabase/migrations/20240101000001_seed_data.sql'),
  path.join(__dirname, '../../supabase/migrations/20240101000002_rls_policies.sql'),
];

async function main() {
  // Use individual params to avoid URL-encoding issues with special chars in password
  const client = new Client({
    host: 'aws-0-eu-west-1.pooler.supabase.com',
    port: 6543,
    user: 'postgres.nauyjsrhykayyzqomiyx',
    password: 'v!GAPf#g,Maa@5r',
    database: 'postgres',
    ssl: { rejectUnauthorized: false },
  });

  await client.connect();
  console.log('✅ Connected to Supabase');

  for (const file of migrations) {
    const name = path.basename(file);
    console.log(`\n▶ Running: ${name}`);
    const sql = fs.readFileSync(file, 'utf8');
    try {
      await client.query(sql);
      console.log(`✅ Done: ${name}`);
    } catch (err) {
      // Ignore "already exists" errors so re-runs are safe
      if (err.message.includes('already exists') || err.message.includes('duplicate')) {
        console.log(`⚠️  Skipped (already applied): ${name}`);
      } else {
        console.error(`❌ Error in ${name}:`, err.message);
        await client.end();
        process.exit(1);
      }
    }
  }

  await client.end();
  console.log('\n🎉 All migrations complete!');
}

main().catch(e => { console.error(e); process.exit(1); });
