# Maya City CBHI — Backend API

NestJS backend for the Maya City Community-Based Health Insurance platform.
Connected to Supabase (PostgreSQL) with full REST API for all three Flutter apps.

## Quick Start (Local Dev)

```bash
cp .env.example .env   # fill in your values
npm install
npm run start:dev      # http://localhost:3000
```

## Quick Start (Supabase — current setup)

The backend is already configured to connect to Supabase. Just run:

```bash
npm run start:prod     # uses dist/ — build first with: npm run build
```

Or in dev watch mode:
```bash
npm run start:dev
```

## Credentials (Demo)

| Role | Phone | Password |
|------|-------|----------|
| System Admin | +251900000001 | Admin@1234 |
| Facility Staff | +251900000002 | Staff@1234 |

## Key Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/health` | Health check (public) |
| `GET /api/v1/demo/status` | Demo mode status (public) |
| `POST /api/v1/auth/login` | Password login |
| `POST /api/v1/auth/send-otp` | OTP login (member app) |
| `GET /api/v1/cbhi/me` | Member snapshot |
| `GET /api/v1/admin/claims` | Admin claims list |
| `GET /api/v1/facility/eligibility` | Facility eligibility check |

Full API: `GET /api/docs` (dev mode only)

## Scripts

```bash
npm run build                    # compile TypeScript
npm run start:prod               # run compiled dist/
npm run start:dev                # watch mode
npm run migration:run            # run pending TypeORM migrations
node scripts/seed-admin.js       # seed admin + facility staff users
node scripts/cleanup-old-types.js  # clean up leftover TypeORM enum types
```

## Deploy with Docker (Supabase)

```bash
# Build and start (Supabase mode — no local postgres)
docker compose --profile supabase up -d

# Or local dev mode (with local postgres)
docker compose --profile local up -d
```

## Environment Variables

See `.env.example` for all variables. Key ones:

| Variable | Description |
|----------|-------------|
| `DB_HOST` | Supabase pooler host |
| `DB_PORT` | 6543 (pooler) or 5432 (direct) |
| `DB_USERNAME` | `postgres.<project-ref>` |
| `DB_PASSWORD` | Supabase DB password (quote if it contains # or @) |
| `DB_SSL` | `true` for Supabase |
| `AUTH_JWT_SECRET` | Strong random secret (min 32 chars) |
| `DEMO_MODE` | `true` to use demo responses for all external services |
| `NODE_ENV` | `production` to disable auto-sync and Swagger |
