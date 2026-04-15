import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Initial schema migration for Maya City CBHI.
 * Creates all tables, enums, indexes, and triggers.
 *
 * This migration is idempotent — safe to run multiple times.
 * Generated from TypeORM entities and validated against Supabase.
 */
export class InitialSchema1704067200000 implements MigrationInterface {
  name = 'InitialSchema1704067200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // ── Extensions ──────────────────────────────────────────────────────────
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "pgcrypto"`);

    // ── ENUM TYPES ───────────────────────────────────────────────────────────
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE user_role AS ENUM (
          'HOUSEHOLD_HEAD','BENEFICIARY','HEALTH_FACILITY_STAFF','CBHI_OFFICER','SYSTEM_ADMIN'
        );
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE identity_document_type AS ENUM ('NATIONAL_ID','PASSPORT','LOCAL_ID');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE identity_verification_status AS ENUM ('PENDING','VERIFIED','FAILED');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE preferred_language AS ENUM ('am','om','en');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE membership_type AS ENUM ('indigent','paying');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE gender AS ENUM ('MALE','FEMALE','OTHER','UNSPECIFIED');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE relationship_to_household_head AS ENUM ('HEAD','SPOUSE','CHILD','PARENT','SIBLING','OTHER');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE coverage_status AS ENUM ('ACTIVE','PENDING_RENEWAL','EXPIRED','SUSPENDED','REJECTED');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE payment_method AS ENUM ('MOBILE_MONEY','BANK_CARD','EWALLET','BANK_TRANSFER');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE payment_status AS ENUM ('PENDING','SUCCESS','FAILED','REFUNDED');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE claim_status AS ENUM ('DRAFT','SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','PAID');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE document_type AS ENUM (
          'IDENTITY_DOCUMENT','BIRTH_CERTIFICATE','BENEFICIARY_PHOTO',
          'NATIONAL_ID','MEMBERSHIP_CARD','CLAIM_SUPPORTING','RECEIPT','OTHER'
        );
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE notification_type AS ENUM ('RENEWAL_REMINDER','CLAIM_UPDATE','HEALTH_PROMOTION','SYSTEM_ALERT');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE facility_user_role AS ENUM ('REGISTRAR','VERIFIER','CLAIMS_OFFICER','ADMIN');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE indigent_employment_status AS ENUM (
          'farmer','merchant','daily_laborer','employed','unemployed','student','homemaker','pensioner'
        );
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE indigent_application_status AS ENUM ('PENDING','APPROVED','REJECTED');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE location_level AS ENUM ('REGION','ZONE','WOREDA','KEBELE');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE grievance_type AS ENUM (
          'CLAIM_REJECTION','FACILITY_DENIAL','ENROLLMENT_ISSUE',
          'PAYMENT_ISSUE','INDIGENT_REJECTION','OTHER'
        );
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE grievance_status AS ENUM ('OPEN','UNDER_REVIEW','RESOLVED','CLOSED');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE appeal_status AS ENUM ('PENDING','UNDER_REVIEW','UPHELD','OVERTURNED');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE audit_action AS ENUM (
          'CREATE','UPDATE','DELETE','LOGIN','LOGOUT','PAYMENT',
          'CLAIM_SUBMIT','CLAIM_REVIEW','INDIGENT_APPLY','INDIGENT_REVIEW',
          'COVERAGE_RENEW','MEMBER_ADD','MEMBER_REMOVE','SETTINGS_UPDATE'
        );
      EXCEPTION WHEN duplicate_object THEN NULL; END $$
    `);

    // ── TABLES ───────────────────────────────────────────────────────────────

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS locations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        name VARCHAR(160) NOT NULL,
        "nameAmharic" VARCHAR(160),
        code VARCHAR(80) NOT NULL UNIQUE,
        level location_level NOT NULL,
        "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
        "parentId" UUID REFERENCES locations(id) ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_locations_code ON locations(code)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_locations_level ON locations(level)`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "nationalId" VARCHAR(32) UNIQUE,
        "firstName" VARCHAR(120) NOT NULL,
        "middleName" VARCHAR(120),
        "lastName" VARCHAR(120),
        "phoneNumber" VARCHAR(32) UNIQUE,
        email VARCHAR(160) UNIQUE,
        "passwordHash" VARCHAR,
        "oneTimeCodeHash" VARCHAR,
        "oneTimeCodePurpose" VARCHAR(32),
        "oneTimeCodeTarget" VARCHAR(160),
        "oneTimeCodeExpiresAt" TIMESTAMPTZ,
        "identityType" identity_document_type,
        "identityNumber" VARCHAR(64) UNIQUE,
        "identityVerificationStatus" identity_verification_status NOT NULL DEFAULT 'PENDING',
        "identityVerifiedAt" TIMESTAMPTZ,
        role user_role NOT NULL DEFAULT 'BENEFICIARY',
        "preferredLanguage" preferred_language NOT NULL DEFAULT 'en',
        "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
        "lastLoginAt" TIMESTAMPTZ,
        "refreshTokenHash" VARCHAR,
        "refreshTokenExpiresAt" TIMESTAMPTZ,
        "totpSecret" VARCHAR,
        "totpEnabled" BOOLEAN NOT NULL DEFAULT FALSE
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_users_phone ON users("phoneNumber")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_users_refresh_token ON users("refreshTokenHash")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS households (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "householdCode" VARCHAR(80) NOT NULL UNIQUE,
        region VARCHAR(120) NOT NULL,
        zone VARCHAR(120) NOT NULL,
        woreda VARCHAR(120) NOT NULL,
        kebele VARCHAR(120) NOT NULL,
        "phoneNumber" VARCHAR(32),
        "membershipType" membership_type,
        "coverageStatus" coverage_status NOT NULL DEFAULT 'ACTIVE',
        "memberCount" INT NOT NULL DEFAULT 0,
        "locationId" UUID REFERENCES locations(id) ON DELETE SET NULL,
        "headUserId" UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_households_code ON households("householdCode")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_households_coverage_status ON households("coverageStatus")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS beneficiaries (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "deletedAt" TIMESTAMPTZ,
        "memberNumber" VARCHAR(80) NOT NULL UNIQUE,
        "fullName" VARCHAR(160) NOT NULL,
        "nationalId" VARCHAR(32) UNIQUE,
        "dateOfBirth" DATE,
        age INT,
        gender gender,
        "birthCertificateRef" VARCHAR(64) UNIQUE,
        "identityType" identity_document_type,
        "identityNumber" VARCHAR(64),
        "relationshipToHouseholdHead" relationship_to_household_head NOT NULL DEFAULT 'OTHER',
        "isPrimaryHolder" BOOLEAN NOT NULL DEFAULT FALSE,
        "isEligible" BOOLEAN NOT NULL DEFAULT TRUE,
        "householdId" UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
        "userAccountId" UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_beneficiaries_household ON beneficiaries("householdId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_beneficiaries_deleted_at ON beneficiaries("deletedAt")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS coverages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "coverageNumber" VARCHAR(80) NOT NULL UNIQUE,
        "startDate" DATE NOT NULL,
        "endDate" DATE NOT NULL,
        status coverage_status NOT NULL DEFAULT 'ACTIVE',
        "premiumAmount" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "paidAmount" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "nextRenewalDate" DATE,
        "householdId" UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_coverages_household ON coverages("householdId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_coverages_status ON coverages(status)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_coverages_end_date ON coverages("endDate")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "transactionReference" VARCHAR(80) NOT NULL UNIQUE,
        amount DECIMAL(12,2) NOT NULL,
        method payment_method NOT NULL,
        status payment_status NOT NULL DEFAULT 'PENDING',
        "providerName" VARCHAR(80),
        "receiptNumber" VARCHAR(120),
        "paidAt" TIMESTAMPTZ,
        "coverageId" UUID NOT NULL REFERENCES coverages(id) ON DELETE CASCADE,
        "processedById" UUID REFERENCES users(id) ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_payments_coverage ON payments("coverageId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status)`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS health_facilities (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        name VARCHAR(160) NOT NULL,
        "facilityCode" VARCHAR(80) UNIQUE,
        "licenseNumber" VARCHAR(80),
        "serviceLevel" VARCHAR(120),
        "phoneNumber" VARCHAR(32),
        email VARCHAR(160),
        "addressLine" VARCHAR(250),
        latitude DECIMAL(10,6),
        longitude DECIMAL(10,6),
        "isAccredited" BOOLEAN NOT NULL DEFAULT TRUE,
        "locationId" UUID REFERENCES locations(id) ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_facilities_code ON health_facilities("facilityCode")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS facility_services (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "serviceName" VARCHAR(120) NOT NULL,
        "serviceCode" VARCHAR(80),
        description VARCHAR(250),
        "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
        "facilityId" UUID NOT NULL REFERENCES health_facilities(id) ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS facility_users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        role facility_user_role NOT NULL DEFAULT 'REGISTRAR',
        "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
        "facilityId" UUID NOT NULL REFERENCES health_facilities(id) ON DELETE CASCADE,
        "userId" UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS cbhi_officers (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "officeName" VARCHAR(160) NOT NULL,
        "officeLevel" VARCHAR(80),
        "positionTitle" VARCHAR(120),
        "canApproveClaims" BOOLEAN NOT NULL DEFAULT TRUE,
        "canManageSettings" BOOLEAN NOT NULL DEFAULT TRUE,
        "officeLocationId" UUID REFERENCES locations(id) ON DELETE SET NULL,
        "userId" UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS claims (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "claimNumber" VARCHAR(80) NOT NULL UNIQUE,
        status claim_status NOT NULL DEFAULT 'DRAFT',
        "serviceDate" DATE NOT NULL,
        "submittedAt" TIMESTAMPTZ,
        "reviewedAt" TIMESTAMPTZ,
        "claimedAmount" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "approvedAmount" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "decisionNote" TEXT,
        "householdId" UUID REFERENCES households(id) ON DELETE SET NULL,
        "coverageId" UUID REFERENCES coverages(id) ON DELETE SET NULL,
        "beneficiaryId" UUID REFERENCES beneficiaries(id) ON DELETE SET NULL,
        "facilityId" UUID REFERENCES health_facilities(id) ON DELETE SET NULL,
        "submittedById" UUID REFERENCES users(id) ON DELETE SET NULL,
        "reviewedById" UUID REFERENCES users(id) ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_claims_number ON claims("claimNumber")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_claims_status ON claims(status)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_claims_household ON claims("householdId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_claims_beneficiary ON claims("beneficiaryId")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS claim_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "serviceName" VARCHAR(160) NOT NULL,
        quantity INT NOT NULL DEFAULT 1,
        "unitPrice" DECIMAL(12,2) NOT NULL,
        "totalPrice" DECIMAL(12,2) NOT NULL,
        notes VARCHAR(250),
        "claimId" UUID NOT NULL REFERENCES claims(id) ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_claim_items_claim ON claim_items("claimId")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS claim_appeals (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        status appeal_status NOT NULL DEFAULT 'PENDING',
        reason TEXT NOT NULL,
        "reviewNote" TEXT,
        "reviewedAt" TIMESTAMPTZ,
        "claimId" UUID NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
        "appellantId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        "reviewedById" UUID REFERENCES users(id) ON DELETE SET NULL
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS documents (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        type document_type NOT NULL DEFAULT 'OTHER',
        "fileName" VARCHAR(180) NOT NULL,
        "fileUrl" VARCHAR(500) NOT NULL,
        "mimeType" VARCHAR(120),
        "isVerified" BOOLEAN NOT NULL DEFAULT FALSE,
        "beneficiaryId" UUID REFERENCES beneficiaries(id) ON DELETE CASCADE,
        "claimId" UUID REFERENCES claims(id) ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_documents_beneficiary ON documents("beneficiaryId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_documents_claim ON documents("claimId")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        type notification_type NOT NULL,
        title VARCHAR(160) NOT NULL,
        message TEXT NOT NULL,
        payload JSONB,
        "readAt" TIMESTAMPTZ,
        "isRead" BOOLEAN NOT NULL DEFAULT FALSE,
        language preferred_language NOT NULL DEFAULT 'en',
        "recipientId" UUID REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications("recipientId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications("isRead")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS indigent_applications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "userId" UUID REFERENCES users(id) ON DELETE SET NULL,
        income INT NOT NULL DEFAULT 0,
        "employmentStatus" indigent_employment_status NOT NULL,
        "familySize" INT NOT NULL DEFAULT 1,
        "hasProperty" BOOLEAN NOT NULL DEFAULT FALSE,
        "disabilityStatus" BOOLEAN NOT NULL DEFAULT FALSE,
        documents JSONB NOT NULL DEFAULT '[]',
        "documentMeta" JSONB,
        status indigent_application_status NOT NULL DEFAULT 'PENDING',
        score INT NOT NULL DEFAULT 0,
        reason TEXT NOT NULL DEFAULT '',
        "hasExpiredDocuments" BOOLEAN NOT NULL DEFAULT FALSE
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_indigent_user ON indigent_applications("userId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_indigent_status ON indigent_applications(status)`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS system_settings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        key VARCHAR(120) NOT NULL UNIQUE,
        label VARCHAR(160) NOT NULL,
        description TEXT,
        value JSONB NOT NULL DEFAULT '{}',
        "isSensitive" BOOLEAN NOT NULL DEFAULT FALSE
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "userId" VARCHAR(36),
        "userEmail" VARCHAR(120),
        "userRole" VARCHAR(32),
        action audit_action NOT NULL,
        "entityType" VARCHAR(80) NOT NULL,
        "entityId" VARCHAR(36),
        "oldValue" JSONB,
        "newValue" JSONB,
        "ipAddress" VARCHAR(45),
        "userAgent" VARCHAR(250)
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs("userId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type ON audit_logs("entityType")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS benefit_packages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        name VARCHAR(120) NOT NULL,
        description TEXT,
        "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
        "premiumPerMember" DECIMAL(10,2) NOT NULL DEFAULT 120.00,
        "annualCeiling" DECIMAL(12,2) NOT NULL DEFAULT 0.00
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS benefit_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "serviceName" VARCHAR(160) NOT NULL,
        "serviceCode" VARCHAR(32),
        category VARCHAR(64) NOT NULL,
        "maxClaimAmount" DECIMAL(10,2) NOT NULL DEFAULT 0.00,
        "coPaymentPercent" INT NOT NULL DEFAULT 0,
        "maxClaimsPerYear" INT NOT NULL DEFAULT 0,
        "isCovered" BOOLEAN NOT NULL DEFAULT TRUE,
        notes TEXT,
        "packageId" UUID NOT NULL REFERENCES benefit_packages(id) ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_benefit_items_package ON benefit_items("packageId")`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS grievances (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        type grievance_type NOT NULL,
        status grievance_status NOT NULL DEFAULT 'OPEN',
        subject VARCHAR(200) NOT NULL,
        description TEXT NOT NULL,
        "referenceId" VARCHAR(36),
        "referenceType" VARCHAR(80),
        resolution TEXT,
        "resolvedAt" TIMESTAMPTZ,
        "submittedById" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        "assignedToId" UUID REFERENCES users(id) ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_grievances_status ON grievances(status)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_grievances_submitted_by ON grievances("submittedById")`);

    // ── updatedAt trigger ────────────────────────────────────────────────────
    await queryRunner.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW."updatedAt" = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);

    const tables = [
      'users', 'households', 'beneficiaries', 'coverages', 'payments',
      'health_facilities', 'facility_services', 'facility_users', 'cbhi_officers',
      'claims', 'claim_items', 'claim_appeals', 'documents', 'notifications',
      'indigent_applications', 'system_settings', 'benefit_packages',
      'benefit_items', 'grievances', 'locations',
    ];

    for (const table of tables) {
      await queryRunner.query(`
        DROP TRIGGER IF EXISTS trg_${table}_updated_at ON ${table};
        CREATE TRIGGER trg_${table}_updated_at
          BEFORE UPDATE ON ${table}
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
      `);
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop tables in reverse dependency order
    const tables = [
      'grievances', 'benefit_items', 'benefit_packages', 'audit_logs',
      'system_settings', 'indigent_applications', 'notifications', 'documents',
      'claim_appeals', 'claim_items', 'claims', 'cbhi_officers', 'facility_users',
      'facility_services', 'health_facilities', 'payments', 'coverages',
      'beneficiaries', 'households', 'users', 'locations',
    ];

    for (const table of tables) {
      await queryRunner.query(`DROP TABLE IF EXISTS ${table} CASCADE`);
    }

    // Drop enum types
    const enums = [
      'user_role', 'identity_document_type', 'identity_verification_status',
      'preferred_language', 'membership_type', 'gender',
      'relationship_to_household_head', 'coverage_status', 'payment_method',
      'payment_status', 'claim_status', 'document_type', 'notification_type',
      'facility_user_role', 'indigent_employment_status',
      'indigent_application_status', 'location_level', 'grievance_type',
      'grievance_status', 'appeal_status', 'audit_action',
    ];

    for (const e of enums) {
      await queryRunner.query(`DROP TYPE IF EXISTS ${e} CASCADE`);
    }

    await queryRunner.query(`DROP FUNCTION IF EXISTS update_updated_at_column CASCADE`);
  }
}
