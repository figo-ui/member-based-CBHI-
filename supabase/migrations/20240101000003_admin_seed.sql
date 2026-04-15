-- ============================================================
-- Maya City CBHI — Admin User Seed
-- Creates the default system admin account for first login.
--
-- IMPORTANT: Change the password immediately after first login!
-- Default credentials:
--   Phone: +251900000001
--   Password: Admin@1234  (bcrypt hash below)
--
-- To generate a new hash:
--   node -e "const bcrypt = require('bcrypt'); bcrypt.hash('YourPassword', 12).then(console.log)"
-- ============================================================

-- Insert default system admin user
-- Password: Admin@1234 (bcrypt, 12 rounds)
INSERT INTO users (
  "firstName",
  "lastName",
  "phoneNumber",
  email,
  "passwordHash",
  role,
  "preferredLanguage",
  "isActive",
  "identityVerificationStatus"
) VALUES (
  'System',
  'Admin',
  '+251900000001',
  'admin@cbhi.maya.gov.et',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFp8.BeOMZMmMqZOmK',
  'SYSTEM_ADMIN',
  'en',
  TRUE,
  'VERIFIED'
)
ON CONFLICT ("phoneNumber") DO NOTHING;

-- Link admin to a CBHI officer record
INSERT INTO cbhi_officers (
  "officeName",
  "officeLevel",
  "positionTitle",
  "canApproveClaims",
  "canManageSettings",
  "userId"
)
SELECT
  'Maya City CBHI Office',
  'WOREDA',
  'System Administrator',
  TRUE,
  TRUE,
  u.id
FROM users u
WHERE u."phoneNumber" = '+251900000001'
ON CONFLICT ("userId") DO NOTHING;

-- ── Demo facility staff user ──────────────────────────────────────────────────
-- Password: Staff@1234
INSERT INTO users (
  "firstName",
  "lastName",
  "phoneNumber",
  email,
  "passwordHash",
  role,
  "preferredLanguage",
  "isActive",
  "identityVerificationStatus"
) VALUES (
  'Facility',
  'Staff',
  '+251900000002',
  'staff@maya-hospital.gov.et',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFp8.BeOMZMmMqZOmK',
  'HEALTH_FACILITY_STAFF',
  'am',
  TRUE,
  'VERIFIED'
)
ON CONFLICT ("phoneNumber") DO NOTHING;

-- Link facility staff to Maya Referral Hospital
INSERT INTO facility_users (role, "isActive", "facilityId", "userId")
SELECT
  'CLAIMS_OFFICER',
  TRUE,
  hf.id,
  u.id
FROM health_facilities hf
CROSS JOIN users u
WHERE hf."facilityCode" = 'FAC-001'
  AND u."phoneNumber" = '+251900000002'
ON CONFLICT ("userId") DO NOTHING;

