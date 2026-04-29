# CBHI System — Quick Start Guide

This guide will get you up and running with the full CBHI system in under 10 minutes.

---

## Prerequisites

- **Node.js** ≥ 20
- **Flutter** ≥ 3.10.1
- **PostgreSQL** 16 (or Supabase account)
- **Redis** 7 (optional — system works without it, but scheduled jobs won't run)

---

## Option 1: Local Development (Full Stack)

### Step 1: Clone & Install

```bash
# Clone the repository
git clone <your-repo-url>
cd cbhi-system

# Install backend dependencies
cd backend
npm install
```

### Step 2: Configure Environment

```bash
cd backend
cp .env.example .env
```

Edit `backend/.env` with your configuration:

**Minimum Required**:
```env
# Database (use Supabase or local PostgreSQL)
DB_HOST=aws-0-eu-west-1.pooler.supabase.com
DB_PORT=6543
DB_USERNAME=postgres.your-project
DB_PASSWORD=your-password
DB_NAME=postgres
DB_SSL=true

# Auth (generate with: openssl rand -hex 64)
AUTH_JWT_SECRET=your-strong-secret-min-32-chars
DIGITAL_CARD_SECRET=your-card-secret

# CORS (add your frontend URLs)
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:4200
```

**Optional (for full features)**:
```env
# Redis (for scheduled jobs)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# SMS (Africa's Talking)
AT_USERNAME=sandbox
AT_API_KEY=your-api-key
AT_SENDER_ID=CBHI

# Google Vision (for document validation)
GOOGLE_VISION_API_KEY=your-api-key

# Firebase FCM (for push notifications)
FCM_PROJECT_ID=your-project-id
FCM_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Chapa (for payments)
CHAPA_SECRET_KEY=CHASECK_TEST-your-test-key
CHAPA_WEBHOOK_SECRET=your-webhook-secret
```

### Step 3: Initialize Database

```bash
cd backend

# Run migrations
npm run migration:run

# Seed admin user
node scripts/seed-admin.js
```

**Default Admin Credentials**:
- Phone: `+251900000001`
- Password: `Admin@1234`
- Role: `SYSTEM_ADMIN`

**Default Facility Staff**:
- Phone: `+251900000002`
- Password: `Staff@1234`
- Role: `HEALTH_FACILITY_STAFF`

### Step 4: Start Backend

```bash
cd backend
npm run start:dev
```

Backend runs at: `http://localhost:3000`

**Test Health Endpoint**:
```bash
curl http://localhost:3000/api/v1/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-01-XX...",
  "uptime": 123,
  "checks": {
    "database": "ok",
    "cache": "in-memory",
    "sms": "configured",
    "vision": "configured",
    "fcm": "configured",
    "chapa": "configured"
  }
}
```

### Step 5: Start Member App

```bash
cd member_based_cbhi
flutter pub get
flutter gen-l10n
flutter run -d chrome --dart-define=CBHI_API_BASE_URL=http://localhost:3000/api/v1
```

**Test Registration**:
1. Click "Start New Registration"
2. Fill personal info
3. Upload identity document (or skip in demo mode)
4. Select membership type
5. Review and submit

### Step 6: Start Admin App

```bash
cd cbhi_admin_desktop
flutter pub get
flutter run -d chrome --dart-define=CBHI_API_BASE_URL=http://localhost:3000/api/v1
```

**Login**:
- Phone: `+251900000001`
- Password: `Admin@1234`
- **No 2FA required** ✅

**Test Features**:
- Overview dashboard
- Claims management
- Indigent application review
- Reports & CSV export

### Step 7: Start Facility App

```bash
cd cbhi_facility_desktop
flutter pub get
flutter run -d chrome --dart-define=CBHI_API_BASE_URL=http://localhost:3000/api/v1
```

**Login**:
- Phone: `+251900000002`
- Password: `Staff@1234`

**Test Features**:
- QR scanner (eligibility check)
- Claim submission

---

## Option 2: Production Deployment (Vercel + Supabase)

### Step 1: Setup Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Get your database credentials:
   - Go to **Settings** → **Database**
   - Copy **Connection Pooling** URL (port 6543)
3. Run migrations:
   ```bash
   cd backend
   npm run migration:run
   node scripts/seed-admin.js
   ```

### Step 2: Deploy Backend to Vercel

```bash
cd backend
vercel --prod
```

**Environment Variables** (set in Vercel dashboard):
- `DB_HOST`
- `DB_PORT`
- `DB_USERNAME`
- `DB_PASSWORD`
- `DB_NAME`
- `DB_SSL=true`
- `AUTH_JWT_SECRET`
- `DIGITAL_CARD_SECRET`
- `CORS_ALLOWED_ORIGINS` (add your frontend URLs)
- All optional service keys (SMS, Vision, FCM, Chapa)

**Note**: Redis is not available on Vercel serverless. Use Upstash Redis or disable scheduled jobs.

### Step 3: Deploy Member App to Vercel

```bash
cd member_based_cbhi
vercel --prod
```

**Build Command** (set in Vercel dashboard):
```bash
bash vercel-build.sh
```

**Environment Variables**:
- `CBHI_API_BASE_URL=https://your-backend.vercel.app/api/v1`

### Step 4: Deploy Admin App to Vercel

```bash
cd cbhi_admin_desktop
vercel --prod
```

**Build Command**:
```bash
bash vercel-build.sh
```

**Environment Variables**:
- `CBHI_API_BASE_URL=https://your-backend.vercel.app/api/v1`

### Step 5: Deploy Facility App to Vercel

```bash
cd cbhi_facility_desktop
vercel --prod
```

**Build Command**:
```bash
bash vercel-build.sh
```

**Environment Variables**:
- `CBHI_API_BASE_URL=https://your-backend.vercel.app/api/v1`

### Step 6: Update CORS

Update `backend/.env` (or Vercel environment variables):
```env
CORS_ALLOWED_ORIGINS=https://your-member-app.vercel.app,https://your-admin-app.vercel.app,https://your-facility-app.vercel.app
```

Redeploy backend:
```bash
cd backend
vercel --prod
```

---

## Option 3: Docker Compose (Local Full Stack)

### Step 1: Configure Environment

```bash
cd backend
cp .env.example .env
# Edit .env with your configuration
```

### Step 2: Start Services

**Local PostgreSQL + Redis + Backend**:
```bash
docker compose --profile local up -d
```

**Supabase (no local PostgreSQL)**:
```bash
docker compose --profile supabase up -d
```

### Step 3: Initialize Database

```bash
docker exec -it cbhi_backend npm run migration:run
docker exec -it cbhi_backend node scripts/seed-admin.js
```

### Step 4: Access Services

- Backend: `http://localhost:3000`
- PostgreSQL: `localhost:5432` (local profile only)
- Redis: `localhost:6379`

### Step 5: Start Flutter Apps

Follow steps 5-7 from **Option 1** above.

---

## Common Issues & Solutions

### Issue: "Database connection failed"

**Solution**: Check your database credentials in `backend/.env`:
```bash
# Test connection
psql "postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=require"
```

### Issue: "CORS error" in browser console

**Solution**: Add your frontend URL to `CORS_ALLOWED_ORIGINS` in `backend/.env`:
```env
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:4200,https://your-app.vercel.app
```

### Issue: "OTP not received"

**Solution**: Check SMS configuration:
1. Verify `AT_API_KEY` is set in `backend/.env`
2. Check backend logs for SMS errors
3. Use sandbox mode: OTP code is logged to console

### Issue: "Payment redirect fails"

**Solution**: Check Chapa configuration:
1. Verify `CHAPA_SECRET_KEY` is set
2. Verify `CHAPA_CALLBACK_URL` matches your backend URL
3. Use test mode: `CHASECK_TEST-...`

### Issue: "Scheduled jobs not running"

**Solution**: Redis is required for scheduled jobs:
```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your-password
```

Without Redis, the following features are disabled:
- Coverage expiry checks
- Renewal reminders
- Grievance escalation
- Claim escalation

### Issue: "Admin app asks for 2FA code"

**Solution**: 2FA has been removed from the admin app. If you see a 2FA prompt:
1. Pull the latest code
2. Verify `cbhi_admin_desktop/lib/src/screens/totp_setup_screen.dart` is deleted
3. Verify `login_screen.dart` has no TOTP logic
4. Clear browser cache and reload

---

## Testing the Full Flow

### 1. Member Registration → Payment → Coverage Active

1. **Member App**: Register a new household
2. **Member App**: Complete payment via Chapa (test mode)
3. **Member App**: Verify coverage status is "Active"
4. **Member App**: View digital card (QR code)

### 2. Facility Claim Submission → Admin Approval

1. **Facility App**: Scan member QR code
2. **Facility App**: Submit a service claim
3. **Admin App**: Review pending claim
4. **Admin App**: Approve claim
5. **Member App**: View approved claim in dashboard

### 3. Indigent Application → Admin Review

1. **Member App**: Submit indigent application
2. **Admin App**: Review pending indigent application
3. **Admin App**: Approve application
4. **Member App**: Verify coverage is active (free)

### 4. Grievance Submission → Admin Resolution

1. **Member App**: Submit a grievance
2. **Admin App**: View grievance
3. **Admin App**: Resolve grievance
4. **Member App**: View resolution notification

---

## API Endpoints Reference

### Authentication

- `POST /api/v1/auth/login` — Password login
- `POST /api/v1/auth/send-otp` — Send OTP via SMS
- `POST /api/v1/auth/verify-otp` — Verify OTP
- `POST /api/v1/auth/refresh` — Refresh access token
- `GET /api/v1/auth/me` — Get current user profile
- `POST /api/v1/auth/logout` — Logout

### CBHI (Member)

- `POST /api/v1/cbhi/register` — Register household
- `GET /api/v1/cbhi/coverage` — Get coverage status
- `GET /api/v1/cbhi/digital-card` — Get digital card
- `POST /api/v1/cbhi/renew` — Renew coverage

### Claims (Member)

- `GET /api/v1/claims` — Get my claims
- `POST /api/v1/claims/:id/appeal` — Appeal a claim

### Grievances (Member)

- `GET /api/v1/grievances` — Get my grievances
- `POST /api/v1/grievances` — Submit grievance

### Indigent (Member)

- `POST /api/v1/indigent/apply` — Submit indigent application
- `GET /api/v1/indigent/status` — Get application status

### Admin

- `GET /api/v1/admin/claims` — Get all claims
- `PATCH /api/v1/admin/claims/:id/decision` — Approve/reject claim
- `GET /api/v1/admin/indigent/pending` — Get pending indigent applications
- `PATCH /api/v1/admin/indigent/:id/review` — Approve/reject indigent application
- `GET /api/v1/admin/reports/summary` — Get summary report
- `GET /api/v1/admin/export` — Export CSV

### Facility

- `POST /api/v1/facility/verify-eligibility` — Verify member eligibility
- `POST /api/v1/facility/claims` — Submit service claim
- `GET /api/v1/facility/claims` — Get facility claims

### Health

- `GET /api/v1/health` — Health check

---

## Environment Variables Reference

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_HOST` | Database host | `aws-0-eu-west-1.pooler.supabase.com` |
| `DB_PORT` | Database port | `6543` |
| `DB_USERNAME` | Database username | `postgres.your-project` |
| `DB_PASSWORD` | Database password | `your-password` |
| `DB_NAME` | Database name | `postgres` |
| `DB_SSL` | Enable SSL | `true` |
| `AUTH_JWT_SECRET` | JWT signing secret | `openssl rand -hex 64` |
| `DIGITAL_CARD_SECRET` | Digital card signing secret | `openssl rand -hex 64` |

### Optional (External Services)

| Variable | Description | Default |
|----------|-------------|---------|
| `REDIS_HOST` | Redis host | In-memory cache |
| `AT_API_KEY` | Africa's Talking API key | Demo mode |
| `GOOGLE_VISION_API_KEY` | Google Vision API key | Demo mode |
| `FCM_PROJECT_ID` | Firebase project ID | Demo mode |
| `CHAPA_SECRET_KEY` | Chapa payment key | Demo mode |
| `GCS_BUCKET` | Google Cloud Storage bucket | Local disk |

### Optional (Configuration)

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Backend port | `3000` |
| `NODE_ENV` | Environment | `development` |
| `DEMO_MODE` | Enable demo mode | `false` |
| `CBHI_PREMIUM_PER_MEMBER` | Premium per member (ETB) | `120` |
| `INDIGENT_INCOME_THRESHOLD` | Indigent income threshold (ETB) | `1000` |
| `DEFAULT_LANGUAGE` | Default language | `en` |

---

## Support & Documentation

- **Full Documentation**: See `README.md`
- **Integration Verification**: See `INTEGRATION_VERIFICATION.md`
- **API Documentation**: `http://localhost:3000/api/docs` (dev only)
- **Health Check**: `http://localhost:3000/api/v1/health`

---

**Last Updated**: 2025-01-XX  
**Version**: 1.0.0
