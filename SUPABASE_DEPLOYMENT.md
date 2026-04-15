# Maya City CBHI — Supabase Deployment Guide

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- [Docker](https://docs.docker.com/get-docker/) installed (for local dev)
- Node.js 20+ installed
- A Supabase account at [supabase.com](https://supabase.com)

---

## 1. Create a Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click **New project**
3. Set:
   - **Name**: `cbhi-maya-city`
   - **Database password**: generate a strong password and save it
   - **Region**: choose the closest to Ethiopia (e.g., `eu-central-1`)
4. Wait for the project to provision (~2 minutes)

---

## 2. Get Your Connection Details

From your project dashboard → **Settings → Database**:

| Variable | Where to find it |
|---|---|
| `DB_HOST` | `db.<project-ref>.supabase.co` |
| `DB_PORT` | `5432` (direct) or `6543` (pooled) |
| `DB_USERNAME` | `postgres` |
| `DB_PASSWORD` | The password you set in step 1 |
| `DB_NAME` | `postgres` |
| `DATABASE_URL` | Connection string (copy from dashboard) |

---

## 3. Configure Environment Variables

Copy `.env.example` to `.env` and fill in the Supabase values:

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env`:

```dotenv
# Supabase connection
DATABASE_URL=postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres?sslmode=require
DB_SSL=true

# Disable auto-sync in production
TYPEORM_SYNCHRONIZE=false
NODE_ENV=production
```

---

## 4. Run Migrations

### Option A: Supabase CLI (recommended)

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref <project-ref>

# Push all migrations
supabase db push
```

### Option B: SQL Editor (manual)

1. Open your project → **SQL Editor**
2. Run each migration file in order:
   - `supabase/migrations/20240101000000_initial_schema.sql`
   - `supabase/migrations/20240101000001_seed_data.sql`
   - `supabase/migrations/20240101000002_rls_policies.sql`
   - `supabase/migrations/20240101000003_admin_seed.sql`
   - `supabase/migrations/20240101000004_storage_buckets.sql`

### Option C: TypeORM CLI

```bash
cd backend
DATABASE_URL="postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres?sslmode=require" \
  npx typeorm migration:run -d src/database/data-source.ts
```

---

## 5. Verify the Schema

In Supabase SQL Editor, run:

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

You should see 21 tables including `users`, `households`, `claims`, `benefit_packages`, etc.

---

## 6. First Login Credentials

After running the admin seed migration:

| Field | Value |
|---|---|
| Phone | `+251900000001` |
| Password | `Admin@1234` |
| Role | `SYSTEM_ADMIN` |

**Change this password immediately after first login.**

Facility staff demo account:

| Field | Value |
|---|---|
| Phone | `+251900000002` |
| Password | `Staff@1234` |
| Role | `HEALTH_FACILITY_STAFF` |

---

## 7. Deploy the Backend

### Docker Compose (VPS / on-prem)

```bash
# Set your environment variables
export DATABASE_URL="postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres?sslmode=require"
export DB_SSL=true

# Start the backend (no local postgres needed — using Supabase)
docker compose up -d backend nginx redis
```

> The `postgres` and `pg-backup` services in `docker-compose.yml` are only needed
> for local development. When using Supabase, skip them.

### Environment Variables for Production

Set these as GitHub Actions secrets or in your server's `.env`:

```
DATABASE_URL=postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres?sslmode=require
SUPABASE_ACCESS_TOKEN=<your-supabase-access-token>
STAGING_DATABASE_URL=<staging-db-url>
PROD_DATABASE_URL=<prod-db-url>
AUTH_JWT_SECRET=<strong-random-secret>
DIGITAL_CARD_SECRET=<strong-random-secret>
CHAPA_SECRET_KEY=<chapa-production-key>
AT_API_KEY=<africastalking-key>
```

---

## 8. Configure Supabase Storage

The storage buckets are created by migration `20240101000004_storage_buckets.sql`.

To use Supabase Storage instead of local disk:

1. Get your **Service Role Key** from Settings → API
2. Add to `.env`:
   ```dotenv
   SUPABASE_URL=https://<project-ref>.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
   ```
3. The `StorageModule` in the backend will automatically use Supabase Storage
   when `SUPABASE_URL` is set, falling back to local disk otherwise.

---

## 9. CI/CD with GitHub Actions

The `.github/workflows/ci.yml` pipeline automatically:

1. Runs backend tests (with a local Postgres service)
2. Runs Flutter tests for all 3 apps
3. On push to `develop` → deploys to staging + runs Supabase migrations
4. On push to `main` → deploys to production + runs Supabase migrations

Required GitHub Secrets:

| Secret | Description |
|---|---|
| `SUPABASE_ACCESS_TOKEN` | From supabase.com/dashboard/account/tokens |
| `STAGING_DATABASE_URL` | Staging Supabase connection string |
| `PROD_DATABASE_URL` | Production Supabase connection string |
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub password or access token |
| `STAGING_HOST` | Staging server IP/hostname |
| `STAGING_USER` | SSH username |
| `STAGING_SSH_KEY` | SSH private key |
| `PROD_HOST` | Production server IP/hostname |
| `PROD_USER` | SSH username |
| `PROD_SSH_KEY` | SSH private key |
| `DOMAIN` | Production domain (e.g., `cbhi.maya.gov.et`) |

---

## 10. Local Development with Supabase

```bash
# Start local Supabase stack
supabase start

# Apply migrations to local Supabase
supabase db reset

# The local Supabase Studio is at: http://localhost:54323
# Local API is at: http://localhost:54321
```

Or use the existing Docker Compose setup (no Supabase CLI needed):

```bash
docker compose up -d postgres redis
cd backend && npm run start:dev
```

---

## Troubleshooting

**SSL connection errors:**
```
Error: self signed certificate
```
Set `DB_SSL=true` and ensure `rejectUnauthorized: false` in your config.

**Migration already applied:**
The migrations use `IF NOT EXISTS` and `ON CONFLICT DO NOTHING` — safe to re-run.

**Password hash mismatch:**
Generate a new bcrypt hash:
```bash
node -e "const bcrypt = require('bcrypt'); bcrypt.hash('YourNewPassword', 12).then(console.log)"
```
Then update `supabase/migrations/20240101000003_admin_seed.sql`.

**Connection pool exhausted (Supabase free tier):**
Supabase free tier allows 60 connections. Use the pooled connection string
(port `6543`) and reduce `DB_POOL_MAX` to `10`.
