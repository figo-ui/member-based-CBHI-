/**
 * Seeds the default admin and facility staff users with correct PBKDF2 password hashes.
 * Uses the same hashing algorithm as auth.service.ts.
 *
 * Run: node scripts/seed-admin.js
 */
require('dotenv').config({ path: '.env' });
const { Client } = require('pg');
const { createHash, pbkdf2Sync, randomBytes } = require('crypto');

function hashPassword(password) {
  const salt = createHash('sha256')
    .update(randomBytes(32))
    .update(`${Date.now()}:${Math.random()}`)
    .digest('hex');
  const hash = pbkdf2Sync(password, salt, 120000, 64, 'sha512').toString('hex');
  return `${salt}:${hash}`;
}

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

  const adminHash = hashPassword('Admin@1234');
  const staffHash = hashPassword('Staff@1234');

  // Upsert system admin
  await client.query(`
    INSERT INTO users (
      "firstName", "lastName", "phoneNumber", email,
      "passwordHash", role, "preferredLanguage", "isActive",
      "identityVerificationStatus"
    ) VALUES (
      'System', 'Admin', '+251900000001', 'admin@cbhi.maya.gov.et',
      $1, 'SYSTEM_ADMIN', 'en', TRUE, 'VERIFIED'
    )
    ON CONFLICT ("phoneNumber") DO UPDATE SET
      "passwordHash" = EXCLUDED."passwordHash",
      "isActive" = TRUE
  `, [adminHash]);
  console.log('✓ Admin user seeded (+251900000001 / Admin@1234)');

  // Link admin to CBHI officer record
  await client.query(`
    INSERT INTO cbhi_officers (
      "officeName", "officeLevel", "positionTitle",
      "canApproveClaims", "canManageSettings", "userId"
    )
    SELECT
      'Maya City CBHI Office', 'WOREDA', 'System Administrator',
      TRUE, TRUE, u.id
    FROM users u WHERE u."phoneNumber" = '+251900000001'
    ON CONFLICT ("userId") DO NOTHING
  `);
  console.log('✓ Admin CBHI officer record linked');

  // Upsert facility staff
  await client.query(`
    INSERT INTO users (
      "firstName", "lastName", "phoneNumber", email,
      "passwordHash", role, "preferredLanguage", "isActive",
      "identityVerificationStatus"
    ) VALUES (
      'Facility', 'Staff', '+251900000002', 'staff@maya-hospital.gov.et',
      $1, 'HEALTH_FACILITY_STAFF', 'am', TRUE, 'VERIFIED'
    )
    ON CONFLICT ("phoneNumber") DO UPDATE SET
      "passwordHash" = EXCLUDED."passwordHash",
      "isActive" = TRUE
  `, [staffHash]);
  console.log('✓ Facility staff seeded (+251900000002 / Staff@1234)');

  // Link facility staff to Maya Referral Hospital
  await client.query(`
    INSERT INTO facility_users (role, "isActive", "facilityId", "userId")
    SELECT 'CLAIMS_OFFICER', TRUE, hf.id, u.id
    FROM health_facilities hf
    CROSS JOIN users u
    WHERE hf."facilityCode" = 'FAC-001'
      AND u."phoneNumber" = '+251900000002'
    ON CONFLICT ("userId") DO NOTHING
  `);
  console.log('✓ Facility staff linked to Maya Referral Hospital');

  await client.end();
  console.log('\nDone! You can now log in with:');
  console.log('  Admin:  +251900000001 / Admin@1234');
  console.log('  Staff:  +251900000002 / Staff@1234');
}

main().catch(e => { console.error('Error:', e.message); process.exit(1); });
