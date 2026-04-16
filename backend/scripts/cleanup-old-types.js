/**
 * Cleans up leftover TypeORM _old enum types from failed synchronize attempts.
 * Run once: node scripts/cleanup-old-types.js
 */
require('dotenv').config({ path: '.env' });
const { Client } = require('pg');

async function main() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: false },
  });

  await client.connect();
  console.log('Connected to Supabase');

  // Find all _old types left by TypeORM synchronize
  const { rows } = await client.query(
    "SELECT typname FROM pg_type WHERE typname LIKE '%_old' AND typtype = 'e'"
  );

  if (rows.length === 0) {
    console.log('No leftover _old types found.');
  } else {
    console.log('Found leftover types:', rows.map(r => r.typname));
    for (const row of rows) {
      try {
        await client.query(`DROP TYPE IF EXISTS "${row.typname}" CASCADE`);
        console.log(`Dropped: ${row.typname}`);
      } catch (e) {
        console.error(`Failed to drop ${row.typname}: ${e.message}`);
      }
    }
  }

  await client.end();
  console.log('Done.');
}

main().catch(e => { console.error(e.message); process.exit(1); });
