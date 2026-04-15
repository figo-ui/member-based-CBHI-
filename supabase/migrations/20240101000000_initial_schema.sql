-- ============================================================
-- Maya City CBHI — Initial Database Schema
-- Supabase / PostgreSQL Migration
-- Generated from TypeORM entities
-- ============================================================

-- ── Enable required extensions ────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── ENUM TYPES ────────────────────────────────────────────────────────────────

CREATE TYPE user_role AS ENUM (
  'HOUSEHOLD_HEAD', 'BENEFICIARY', 'HEALTH_FACILITY_STAFF',
  'CBHI_OFFICER', 'SYSTEM_ADMIN'
);

CREATE TYPE identity_document_type AS ENUM (
  'NATIONAL_ID', 'PASSPORT', 'LOCAL_ID'
);

CREATE TYPE identity_verification_status AS ENUM (
  'PENDING', 'VERIFIED', 'FAILED'
);

CREATE TYPE preferred_language AS ENUM ('am', 'om', 'en');

CREATE TYPE membership_type AS ENUM ('indigent', 'paying');

CREATE TYPE gender AS ENUM ('MALE', 'FEMALE', 'OTHER', 'UNSPECIFIED');

CREATE TYPE relationship_to_household_head AS ENUM (
  'HEAD', 'SPOUSE', 'CHILD', 'PARENT', 'SIBLING', 'OTHER'
);

CREATE TYPE coverage_status AS ENUM (
  'ACTIVE', 'PENDING_RENEWAL', 'EXPIRED', 'SUSPENDED', 'REJECTED'
);

CREATE TYPE payment_method AS ENUM (
  'MOBILE_MONEY', 'BANK_CARD', 'EWALLET', 'BANK_TRANSFER'
);

CREATE TYPE payment_status AS ENUM (
  'PENDING', 'SUCCESS', 'FAILED', 'REFUNDED'
);

CREATE TYPE claim_status AS ENUM (
  'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'PAID'
);

CREATE TYPE document_type AS ENUM (
  'IDENTITY_DOCUMENT', 'BIRTH_CERTIFICATE', 'BENEFICIARY_PHOTO',
  'NATIONAL_ID', 'MEMBERSHIP_CARD', 'CLAIM_SUPPORTING', 'RECEIPT', 'OTHER'
);

CREATE TYPE notification_type AS ENUM (
  'RENEWAL_REMINDER', 'CLAIM_UPDATE', 'HEALTH_PROMOTION', 'SYSTEM_ALERT'
);

CREATE TYPE facility_user_role AS ENUM (
  'REGISTRAR', 'VERIFIER', 'CLAIMS_OFFICER', 'ADMIN'
);

CREATE TYPE indigent_employment_status AS ENUM (
  'farmer', 'merchant', 'daily_laborer', 'employed',
  'unemployed', 'student', 'homemaker', 'pensioner'
);

CREATE TYPE indigent_application_status AS ENUM (
  'PENDING', 'APPROVED', 'REJECTED'
);

CREATE TYPE location_level AS ENUM (
  'REGION', 'ZONE', 'WOREDA', 'KEBELE'
);

CREATE TYPE grievance_type AS ENUM (
  'CLAIM_REJECTION', 'FACILITY_DENIAL', 'ENROLLMENT_ISSUE',
  'PAYMENT_ISSUE', 'INDIGENT_REJECTION', 'OTHER'
);

CREATE TYPE grievance_status AS ENUM (
  'OPEN', 'UNDER_REVIEW', 'RESOLVED', 'CLOSED'
);

CREATE TYPE appeal_status AS ENUM (
  'PENDING', 'UNDER_REVIEW', 'UPHELD', 'OVERTURNED'
);

CREATE TYPE audit_action AS ENUM (
  'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'PAYMENT',
  'CLAIM_SUBMIT', 'CLAIM_REVIEW', 'INDIGENT_APPLY', 'INDIGENT_REVIEW',
  'COVERAGE_RENEW', 'MEMBER_ADD', 'MEMBER_REMOVE', 'SETTINGS_UPDATE'
);

-- ── TABLE: locations ──────────────────────────────────────────────────────────
CREATE TABLE locations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  name        VARCHAR(160) NOT NULL,
  "nameAmharic" VARCHAR(160),
  code        VARCHAR(80) NOT NULL UNIQUE,
  level       location_level NOT NULL,
  "isActive"  BOOLEAN NOT NULL DEFAULT TRUE,
  "parentId"  UUID REFERENCES locations(id) ON DELETE SET NULL
);

CREATE INDEX idx_locations_code ON locations(code);
CREATE INDEX idx_locations_level ON locations(level);
CREATE INDEX idx_locations_parent ON locations("parentId");

-- ── TABLE: users ──────────────────────────────────────────────────────────────
CREATE TABLE users (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "nationalId"                VARCHAR(32) UNIQUE,
  "firstName"                 VARCHAR(120) NOT NULL,
  "middleName"                VARCHAR(120),
  "lastName"                  VARCHAR(120),
  "phoneNumber"               VARCHAR(32) UNIQUE,
  email                       VARCHAR(160) UNIQUE,
  "passwordHash"              VARCHAR,
  "oneTimeCodeHash"           VARCHAR,
  "oneTimeCodePurpose"        VARCHAR(32),
  "oneTimeCodeTarget"         VARCHAR(160),
  "oneTimeCodeExpiresAt"      TIMESTAMPTZ,
  "identityType"              identity_document_type,
  "identityNumber"            VARCHAR(64) UNIQUE,
  "identityVerificationStatus" identity_verification_status NOT NULL DEFAULT 'PENDING',
  "identityVerifiedAt"        TIMESTAMPTZ,
  role                        user_role NOT NULL DEFAULT 'BENEFICIARY',
  "preferredLanguage"         preferred_language NOT NULL DEFAULT 'en',
  "isActive"                  BOOLEAN NOT NULL DEFAULT TRUE,
  "lastLoginAt"               TIMESTAMPTZ,
  "refreshTokenHash"          VARCHAR,
  "refreshTokenExpiresAt"     TIMESTAMPTZ,
  "totpSecret"                VARCHAR,
  "totpEnabled"               BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_users_national_id ON users("nationalId");
CREATE INDEX idx_users_phone ON users("phoneNumber");
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_refresh_token ON users("refreshTokenHash");
CREATE INDEX idx_users_role ON users(role);

-- ── TABLE: households ─────────────────────────────────────────────────────────
CREATE TABLE households (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "householdCode" VARCHAR(80) NOT NULL UNIQUE,
  region          VARCHAR(120) NOT NULL,
  zone            VARCHAR(120) NOT NULL,
  woreda          VARCHAR(120) NOT NULL,
  kebele          VARCHAR(120) NOT NULL,
  "phoneNumber"   VARCHAR(32),
  "membershipType" membership_type,
  "coverageStatus" coverage_status NOT NULL DEFAULT 'ACTIVE',
  "memberCount"   INT NOT NULL DEFAULT 0,
  "locationId"    UUID REFERENCES locations(id) ON DELETE SET NULL,
  "headUserId"    UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_households_code ON households("householdCode");
CREATE INDEX idx_households_head_user ON households("headUserId");
CREATE INDEX idx_households_coverage_status ON households("coverageStatus");

-- ── TABLE: beneficiaries ──────────────────────────────────────────────────────
CREATE TABLE beneficiaries (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "deletedAt"                 TIMESTAMPTZ,
  "memberNumber"              VARCHAR(80) NOT NULL UNIQUE,
  "fullName"                  VARCHAR(160) NOT NULL,
  "nationalId"                VARCHAR(32) UNIQUE,
  "dateOfBirth"               DATE,
  age                         INT,
  gender                      gender,
  "birthCertificateRef"       VARCHAR(64) UNIQUE,
  "identityType"              identity_document_type,
  "identityNumber"            VARCHAR(64),
  "relationshipToHouseholdHead" relationship_to_household_head NOT NULL DEFAULT 'OTHER',
  "isPrimaryHolder"           BOOLEAN NOT NULL DEFAULT FALSE,
  "isEligible"                BOOLEAN NOT NULL DEFAULT TRUE,
  "householdId"               UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  "userAccountId"             UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_beneficiaries_member_number ON beneficiaries("memberNumber");
CREATE INDEX idx_beneficiaries_household ON beneficiaries("householdId");
CREATE INDEX idx_beneficiaries_user_account ON beneficiaries("userAccountId");
CREATE INDEX idx_beneficiaries_deleted_at ON beneficiaries("deletedAt");

-- ── TABLE: coverages ──────────────────────────────────────────────────────────
CREATE TABLE coverages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "coverageNumber" VARCHAR(80) NOT NULL UNIQUE,
  "startDate"      DATE NOT NULL,
  "endDate"        DATE NOT NULL,
  status           coverage_status NOT NULL DEFAULT 'ACTIVE',
  "premiumAmount"  DECIMAL(12,2) NOT NULL DEFAULT 0,
  "paidAmount"     DECIMAL(12,2) NOT NULL DEFAULT 0,
  "nextRenewalDate" DATE,
  "householdId"    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE
);

CREATE INDEX idx_coverages_number ON coverages("coverageNumber");
CREATE INDEX idx_coverages_household ON coverages("householdId");
CREATE INDEX idx_coverages_status ON coverages(status);
CREATE INDEX idx_coverages_end_date ON coverages("endDate");

-- ── TABLE: payments ───────────────────────────────────────────────────────────
CREATE TABLE payments (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "transactionReference" VARCHAR(80) NOT NULL UNIQUE,
  amount                 DECIMAL(12,2) NOT NULL,
  method                 payment_method NOT NULL,
  status                 payment_status NOT NULL DEFAULT 'PENDING',
  "providerName"         VARCHAR(80),
  "receiptNumber"        VARCHAR(120),
  "paidAt"               TIMESTAMPTZ,
  "coverageId"           UUID NOT NULL REFERENCES coverages(id) ON DELETE CASCADE,
  "processedById"        UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_payments_tx_ref ON payments("transactionReference");
CREATE INDEX idx_payments_coverage ON payments("coverageId");
CREATE INDEX idx_payments_status ON payments(status);

-- ── TABLE: health_facilities ──────────────────────────────────────────────────
CREATE TABLE health_facilities (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  name           VARCHAR(160) NOT NULL,
  "facilityCode" VARCHAR(80) UNIQUE,
  "licenseNumber" VARCHAR(80),
  "serviceLevel" VARCHAR(120),
  "phoneNumber"  VARCHAR(32),
  email          VARCHAR(160),
  "addressLine"  VARCHAR(250),
  latitude       DECIMAL(10,6),
  longitude      DECIMAL(10,6),
  "isAccredited" BOOLEAN NOT NULL DEFAULT TRUE,
  "locationId"   UUID REFERENCES locations(id) ON DELETE SET NULL
);

CREATE INDEX idx_facilities_code ON health_facilities("facilityCode");
CREATE INDEX idx_facilities_accredited ON health_facilities("isAccredited");

-- ── TABLE: facility_services ──────────────────────────────────────────────────
CREATE TABLE facility_services (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "serviceName" VARCHAR(120) NOT NULL,
  "serviceCode" VARCHAR(80),
  description   VARCHAR(250),
  "isActive"    BOOLEAN NOT NULL DEFAULT TRUE,
  "facilityId"  UUID NOT NULL REFERENCES health_facilities(id) ON DELETE CASCADE
);

CREATE INDEX idx_facility_services_facility ON facility_services("facilityId");

-- ── TABLE: facility_users ─────────────────────────────────────────────────────
CREATE TABLE facility_users (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  role         facility_user_role NOT NULL DEFAULT 'REGISTRAR',
  "isActive"   BOOLEAN NOT NULL DEFAULT TRUE,
  "facilityId" UUID NOT NULL REFERENCES health_facilities(id) ON DELETE CASCADE,
  "userId"     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_facility_users_facility ON facility_users("facilityId");
CREATE INDEX idx_facility_users_user ON facility_users("userId");

-- ── TABLE: cbhi_officers ──────────────────────────────────────────────────────
CREATE TABLE cbhi_officers (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "officeName"        VARCHAR(160) NOT NULL,
  "officeLevel"       VARCHAR(80),
  "positionTitle"     VARCHAR(120),
  "canApproveClaims"  BOOLEAN NOT NULL DEFAULT TRUE,
  "canManageSettings" BOOLEAN NOT NULL DEFAULT TRUE,
  "officeLocationId"  UUID REFERENCES locations(id) ON DELETE SET NULL,
  "userId"            UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE
);

-- ── TABLE: claims ─────────────────────────────────────────────────────────────
CREATE TABLE claims (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "claimNumber"    VARCHAR(80) NOT NULL UNIQUE,
  status           claim_status NOT NULL DEFAULT 'DRAFT',
  "serviceDate"    DATE NOT NULL,
  "submittedAt"    TIMESTAMPTZ,
  "reviewedAt"     TIMESTAMPTZ,
  "claimedAmount"  DECIMAL(12,2) NOT NULL DEFAULT 0,
  "approvedAmount" DECIMAL(12,2) NOT NULL DEFAULT 0,
  "decisionNote"   TEXT,
  "householdId"    UUID REFERENCES households(id) ON DELETE SET NULL,
  "coverageId"     UUID REFERENCES coverages(id) ON DELETE SET NULL,
  "beneficiaryId"  UUID REFERENCES beneficiaries(id) ON DELETE SET NULL,
  "facilityId"     UUID REFERENCES health_facilities(id) ON DELETE SET NULL,
  "submittedById"  UUID REFERENCES users(id) ON DELETE SET NULL,
  "reviewedById"   UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_claims_number ON claims("claimNumber");
CREATE INDEX idx_claims_status ON claims(status);
CREATE INDEX idx_claims_household ON claims("householdId");
CREATE INDEX idx_claims_beneficiary ON claims("beneficiaryId");
CREATE INDEX idx_claims_facility ON claims("facilityId");
CREATE INDEX idx_claims_service_date ON claims("serviceDate");

-- ── TABLE: claim_items ────────────────────────────────────────────────────────
CREATE TABLE claim_items (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "serviceName" VARCHAR(160) NOT NULL,
  quantity      INT NOT NULL DEFAULT 1,
  "unitPrice"   DECIMAL(12,2) NOT NULL,
  "totalPrice"  DECIMAL(12,2) NOT NULL,
  notes         VARCHAR(250),
  "claimId"     UUID NOT NULL REFERENCES claims(id) ON DELETE CASCADE
);

CREATE INDEX idx_claim_items_claim ON claim_items("claimId");

-- ── TABLE: claim_appeals ──────────────────────────────────────────────────────
CREATE TABLE claim_appeals (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status        appeal_status NOT NULL DEFAULT 'PENDING',
  reason        TEXT NOT NULL,
  "reviewNote"  TEXT,
  "reviewedAt"  TIMESTAMPTZ,
  "claimId"     UUID NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
  "appellantId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "reviewedById" UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_claim_appeals_claim ON claim_appeals("claimId");
CREATE INDEX idx_claim_appeals_appellant ON claim_appeals("appellantId");

-- ── TABLE: documents ──────────────────────────────────────────────────────────
CREATE TABLE documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  type            document_type NOT NULL DEFAULT 'OTHER',
  "fileName"      VARCHAR(180) NOT NULL,
  "fileUrl"       VARCHAR(500) NOT NULL,
  "mimeType"      VARCHAR(120),
  "isVerified"    BOOLEAN NOT NULL DEFAULT FALSE,
  "beneficiaryId" UUID REFERENCES beneficiaries(id) ON DELETE CASCADE,
  "claimId"       UUID REFERENCES claims(id) ON DELETE CASCADE
);

CREATE INDEX idx_documents_beneficiary ON documents("beneficiaryId");
CREATE INDEX idx_documents_claim ON documents("claimId");
CREATE INDEX idx_documents_type ON documents(type);

-- ── TABLE: notifications ──────────────────────────────────────────────────────
CREATE TABLE notifications (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  type         notification_type NOT NULL,
  title        VARCHAR(160) NOT NULL,
  message      TEXT NOT NULL,
  payload      JSONB,
  "readAt"     TIMESTAMPTZ,
  "isRead"     BOOLEAN NOT NULL DEFAULT FALSE,
  language     preferred_language NOT NULL DEFAULT 'en',
  "recipientId" UUID REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_recipient ON notifications("recipientId");
CREATE INDEX idx_notifications_is_read ON notifications("isRead");
CREATE INDEX idx_notifications_type ON notifications(type);

-- ── TABLE: indigent_applications ──────────────────────────────────────────────
CREATE TABLE indigent_applications (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "userId"              UUID REFERENCES users(id) ON DELETE SET NULL,
  income                INT NOT NULL DEFAULT 0,
  "employmentStatus"    indigent_employment_status NOT NULL,
  "familySize"          INT NOT NULL DEFAULT 1,
  "hasProperty"         BOOLEAN NOT NULL DEFAULT FALSE,
  "disabilityStatus"    BOOLEAN NOT NULL DEFAULT FALSE,
  documents             JSONB NOT NULL DEFAULT '[]',
  "documentMeta"        JSONB,
  status                indigent_application_status NOT NULL DEFAULT 'PENDING',
  score                 INT NOT NULL DEFAULT 0,
  reason                TEXT NOT NULL DEFAULT '',
  "hasExpiredDocuments" BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_indigent_user ON indigent_applications("userId");
CREATE INDEX idx_indigent_status ON indigent_applications(status);

-- ── TABLE: system_settings ────────────────────────────────────────────────────
CREATE TABLE system_settings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  key          VARCHAR(120) NOT NULL UNIQUE,
  label        VARCHAR(160) NOT NULL,
  description  TEXT,
  value        JSONB NOT NULL DEFAULT '{}',
  "isSensitive" BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX idx_system_settings_key ON system_settings(key);

-- ── TABLE: audit_logs ─────────────────────────────────────────────────────────
CREATE TABLE audit_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "userId"     VARCHAR(36),
  "userEmail"  VARCHAR(120),
  "userRole"   VARCHAR(32),
  action       audit_action NOT NULL,
  "entityType" VARCHAR(80) NOT NULL,
  "entityId"   VARCHAR(36),
  "oldValue"   JSONB,
  "newValue"   JSONB,
  "ipAddress"  VARCHAR(45),
  "userAgent"  VARCHAR(250)
);

CREATE INDEX idx_audit_logs_user ON audit_logs("userId");
CREATE INDEX idx_audit_logs_entity_type ON audit_logs("entityType");
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs("createdAt");

-- ── TABLE: benefit_packages ───────────────────────────────────────────────────
CREATE TABLE benefit_packages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  name             VARCHAR(120) NOT NULL,
  description      TEXT,
  "isActive"       BOOLEAN NOT NULL DEFAULT TRUE,
  "premiumPerMember" DECIMAL(10,2) NOT NULL DEFAULT 120.00,
  "annualCeiling"  DECIMAL(12,2) NOT NULL DEFAULT 0.00
);

-- ── TABLE: benefit_items ──────────────────────────────────────────────────────
CREATE TABLE benefit_items (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "serviceName"      VARCHAR(160) NOT NULL,
  "serviceCode"      VARCHAR(32),
  category           VARCHAR(64) NOT NULL,
  "maxClaimAmount"   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  "coPaymentPercent" INT NOT NULL DEFAULT 0,
  "maxClaimsPerYear" INT NOT NULL DEFAULT 0,
  "isCovered"        BOOLEAN NOT NULL DEFAULT TRUE,
  notes              TEXT,
  "packageId"        UUID NOT NULL REFERENCES benefit_packages(id) ON DELETE CASCADE
);

CREATE INDEX idx_benefit_items_package ON benefit_items("packageId");
CREATE INDEX idx_benefit_items_category ON benefit_items(category);

-- ── TABLE: grievances ─────────────────────────────────────────────────────────
CREATE TABLE grievances (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "createdAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  type            grievance_type NOT NULL,
  status          grievance_status NOT NULL DEFAULT 'OPEN',
  subject         VARCHAR(200) NOT NULL,
  description     TEXT NOT NULL,
  "referenceId"   VARCHAR(36),
  "referenceType" VARCHAR(80),
  resolution      TEXT,
  "resolvedAt"    TIMESTAMPTZ,
  "submittedById" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "assignedToId"  UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_grievances_status ON grievances(status);
CREATE INDEX idx_grievances_submitted_by ON grievances("submittedById");
CREATE INDEX idx_grievances_type ON grievances(type);

-- ── TABLE: typeorm_migrations (required by TypeORM) ───────────────────────────
CREATE TABLE IF NOT EXISTS typeorm_migrations (
  id        SERIAL PRIMARY KEY,
  timestamp BIGINT NOT NULL,
  name      VARCHAR(255) NOT NULL
);

-- ── UPDATED_AT TRIGGER ────────────────────────────────────────────────────────
-- Auto-update updatedAt on every row modification

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updatedAt
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'users', 'households', 'beneficiaries', 'coverages', 'payments',
    'health_facilities', 'facility_services', 'facility_users', 'cbhi_officers',
    'claims', 'claim_items', 'claim_appeals', 'documents', 'notifications',
    'indigent_applications', 'system_settings', 'benefit_packages',
    'benefit_items', 'grievances', 'locations'
  ]
  LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_updated_at
       BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      t, t
    );
  END LOOP;
END;
$$;
