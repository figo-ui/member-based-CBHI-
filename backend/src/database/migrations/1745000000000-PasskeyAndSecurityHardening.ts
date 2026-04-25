import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Migration: Passkey support and security hardening.
 *
 * Changes:
 * - Adds token_version, otp_fail_count, otp_rate_limit_count,
 *   otp_rate_limit_window_start columns to the users table.
 * - Creates the passkey_credentials table for WebAuthn/FIDO2 passkey storage.
 */
export class PasskeyAndSecurityHardening1745000000000
  implements MigrationInterface
{
  name = 'PasskeyAndSecurityHardening1745000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // ── Security-hardening columns on users ──────────────────────────────────
    await queryRunner.query(`
      ALTER TABLE users
        ADD COLUMN IF NOT EXISTS token_version INT NOT NULL DEFAULT 0
    `);

    await queryRunner.query(`
      ALTER TABLE users
        ADD COLUMN IF NOT EXISTS otp_fail_count INT NOT NULL DEFAULT 0
    `);

    await queryRunner.query(`
      ALTER TABLE users
        ADD COLUMN IF NOT EXISTS otp_rate_limit_count INT NOT NULL DEFAULT 0
    `);

    await queryRunner.query(`
      ALTER TABLE users
        ADD COLUMN IF NOT EXISTS otp_rate_limit_window_start TIMESTAMPTZ
    `);

    // ── passkey_credentials table ────────────────────────────────────────────
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS passkey_credentials (
        id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id           UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        credential_id     VARCHAR(512) NOT NULL,
        public_key        TEXT         NOT NULL,
        sign_count        BIGINT       NOT NULL DEFAULT 0,
        rp_id             VARCHAR(255) NOT NULL,
        device_name       VARCHAR(255),
        last_used_at      TIMESTAMPTZ,
        created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
        updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
        created_by        VARCHAR(255)
      )
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_passkey_credentials_user_id
        ON passkey_credentials(user_id)
    `);

    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_passkey_credentials_credential_id
        ON passkey_credentials(credential_id)
    `);

    // updatedAt trigger for passkey_credentials
    await queryRunner.query(`
      DROP TRIGGER IF EXISTS trg_passkey_credentials_updated_at
        ON passkey_credentials;
      CREATE TRIGGER trg_passkey_credentials_updated_at
        BEFORE UPDATE ON passkey_credentials
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop passkey_credentials table
    await queryRunner.query(
      `DROP TABLE IF EXISTS passkey_credentials CASCADE`,
    );

    // Remove security-hardening columns from users
    await queryRunner.query(`
      ALTER TABLE users
        DROP COLUMN IF EXISTS otp_rate_limit_window_start,
        DROP COLUMN IF EXISTS otp_rate_limit_count,
        DROP COLUMN IF EXISTS otp_fail_count,
        DROP COLUMN IF EXISTS token_version
    `);
  }
}
