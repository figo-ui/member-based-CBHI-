# Deploy Backend to Railway

## Why Railway (not Vercel)

Vercel is serverless — it can't run NestJS because the app needs:
- Persistent process (WebSockets, Bull queues)
- Long-lived DB connections (TypeORM connection pool)
- File upload storage (`/uploads/`)
- Stateful in-memory cache fallback

Railway runs your app as a persistent container, exactly like a VPS but with zero DevOps.

---

## Step 1 — Create Railway Account

Go to [railway.app](https://railway.app) → Sign up with GitHub.

---

## Step 2 — New Project from GitHub

1. Click **New Project**
2. Select **Deploy from GitHub repo**
3. Choose your repo (`Member_Based_CBHI` or whatever it's named)
4. Railway will detect the `backend/railway.toml` automatically

> If Railway asks which folder to deploy from, set the **Root Directory** to `backend`

---

## Step 3 — Set Environment Variables

In Railway → your service → **Variables** tab, add each variable below.

**Copy these exact key=value pairs** (no quotes around values):

```
PORT=3000
NODE_ENV=production

DB_HOST=aws-0-eu-west-1.pooler.supabase.com
DB_PORT=6543
DB_USERNAME=postgres.nauyjsrhykayyzqomiyx
DB_PASSWORD=v!GAPf#g,Maa@5r
DB_NAME=postgres
DB_SSL=true
TYPEORM_SYNCHRONIZE=false
TYPEORM_LOGGING=false
DB_POOL_MAX=10
DB_POOL_MIN=2

AUTH_JWT_SECRET=b5b35c8d9e8318f3021fc2bf320c3029d6659013a2b0b5863c9c26f92073c9bfabf7ea8320fbd49f7f1f83c6dee4af21
AUTH_ACCESS_TOKEN_TTL_SECONDS=86400
DIGITAL_CARD_SECRET=c2c27af2ce4cb269b3870c89a10d66f862f3d269de620231eaf7d529df44d235

DEMO_MODE=true
AT_USERNAME=sandbox
AT_API_KEY=
AT_SENDER_ID=CBHI
GOOGLE_VISION_API_KEY=
GCS_BUCKET=
GCS_PROJECT_ID=
GCS_CLIENT_EMAIL=
GCS_PRIVATE_KEY=
FCM_PROJECT_ID=
FCM_CLIENT_EMAIL=
FCM_PRIVATE_KEY=
CHAPA_SECRET_KEY=
CHAPA_WEBHOOK_SECRET=

INDIGENT_INCOME_THRESHOLD=1000
INDIGENT_FAMILY_SIZE_THRESHOLD=5
INDIGENT_APPROVAL_THRESHOLD=70

OPENIMIS_BASE_URL=
NATIONAL_ID_API_BASE_URL=
NATIONAL_ID_API_KEY=

DEFAULT_LANGUAGE=en
SUPPORTED_LANGUAGES=am,om,en
CBHI_PREMIUM_PER_MEMBER=120
```

> **CORS and APP_BASE_URL** — set these AFTER Railway gives you a domain (Step 5)

---

## Step 4 — Deploy

Click **Deploy** (or push to your main branch — Railway auto-deploys on push).

Railway will:
1. Run `npm install --legacy-peer-deps && npm run build`
2. Start with `node scripts/run-migrations-prod.js && node dist/main`
3. Health-check `GET /api/v1/health` every 30s

Watch the build logs — it takes ~2 minutes.

---

## Step 5 — Set Your Railway Domain

After deploy succeeds:

1. Railway → Service → **Settings** → **Networking** → **Generate Domain**
2. You'll get something like: `cbhi-backend-production.up.railway.app`
3. Go back to **Variables** and update:

```
CORS_ALLOWED_ORIGINS=https://cbhi-backend-production.up.railway.app,http://localhost:3000,http://10.0.2.2:3000
APP_BASE_URL=https://cbhi-backend-production.up.railway.app
CHAPA_CALLBACK_URL=https://cbhi-backend-production.up.railway.app/api/v1/payments/webhook/chapa
CHAPA_RETURN_URL=https://cbhi-backend-production.up.railway.app/api/v1/payments/verify
```

4. Railway will redeploy automatically.

---

## Step 6 — Verify

```bash
# Health check
curl https://cbhi-backend-production.up.railway.app/api/v1/health

# Demo status
curl https://cbhi-backend-production.up.railway.app/api/v1/demo/status

# Admin login
curl -X POST https://cbhi-backend-production.up.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"+251900000001","password":"Admin@1234"}'
```

Expected health response:
```json
{"status":"ok","timestamp":"...","uptime":...}
```

---

## Step 7 — Update Flutter Apps

Once you have the Railway URL, update the API base URL in each Flutter app.

In each app's `main.dart` or build config, set:
```
CBHI_API_BASE_URL=https://cbhi-backend-production.up.railway.app/api/v1
```

Or pass it at build time:
```bash
flutter build apk --dart-define=CBHI_API_BASE_URL=https://cbhi-backend-production.up.railway.app/api/v1
```

---

## Credentials

| Role | Phone | Password |
|------|-------|----------|
| System Admin | +251900000001 | Admin@1234 |
| Facility Staff | +251900000002 | Staff@1234 |

---

## Troubleshooting

**Build fails with "Cannot find module"**
→ Make sure Root Directory is set to `backend` in Railway settings

**DB connection error on startup**
→ Check DB_PASSWORD has no surrounding quotes in Railway Variables
→ The Supabase pooler password `v!GAPf#g,Maa@5r` must be entered as-is

**Health check fails (503)**
→ Check deploy logs for startup errors
→ Increase `healthcheckTimeout` in `railway.toml` if DB connection is slow

**CORS errors from Flutter app**
→ Add your Railway domain to `CORS_ALLOWED_ORIGINS`
