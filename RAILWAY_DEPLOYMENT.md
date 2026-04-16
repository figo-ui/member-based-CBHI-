# Deploy NestJS Backend to Railway

## Why not Vercel?

Vercel is serverless — it deployed your Flutter web app, not the NestJS backend.
NestJS needs a persistent process (connection pool, Bull queues, WebSockets).
Railway runs it as a real server.

---

## Step 1 — Create Railway Project

1. Go to [railway.app](https://railway.app) → **New Project**
2. Click **Deploy from GitHub repo**
3. Authorize Railway to access your repo
4. Select your repo

---

## Step 2 — Set Root Directory (CRITICAL)

After selecting the repo, Railway shows a **"Configure"** screen.

**Before clicking Deploy:**
- Look for **"Root Directory"** field
- Type: `backend`
- Click **Deploy**

**If you already deployed without setting it:**
1. Go to your service → **Settings** tab
2. Scroll to **"Source"** section
3. Find **"Root Directory"** → set to `backend`
4. Click **Save** → Railway redeploys automatically

> The repo root also has a `railway.toml` now that uses `cd backend && ...`
> so even if Railway reads from root, it will still work.

---

## Step 3 — Add Environment Variables

Railway → your service → **Variables** tab → **Raw Editor** → paste this entire block:

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

Click **Update Variables** — Railway redeploys.

---

## Step 4 — Generate a Public Domain

Railway → Service → **Settings** → **Networking** → **Generate Domain**

You'll get: `something.up.railway.app`

Then add these two more variables (replace with your actual domain):

```
CORS_ALLOWED_ORIGINS=https://YOUR_DOMAIN.up.railway.app,http://localhost:3000,http://10.0.2.2:3000
APP_BASE_URL=https://YOUR_DOMAIN.up.railway.app
CHAPA_CALLBACK_URL=https://YOUR_DOMAIN.up.railway.app/api/v1/payments/webhook/chapa
CHAPA_RETURN_URL=https://YOUR_DOMAIN.up.railway.app/api/v1/payments/verify
```

---

## Step 5 — Verify

```bash
curl https://YOUR_DOMAIN.up.railway.app/api/v1/health
# → {"status":"ok","timestamp":"..."}

curl https://YOUR_DOMAIN.up.railway.app/api/v1/demo/status
# → {"demoMode":true,...}

curl -X POST https://YOUR_DOMAIN.up.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"+251900000001","password":"Admin@1234"}'
# → {"accessToken":"eyJ...","user":{"role":"SYSTEM_ADMIN",...}}
```

---

## Step 6 — Update Flutter Apps

Once you have the Railway URL, build each Flutter app with:

```bash
# Member app
flutter build apk --dart-define=CBHI_API_BASE_URL=https://YOUR_DOMAIN.up.railway.app/api/v1

# Admin desktop
flutter build windows --dart-define=CBHI_API_BASE_URL=https://YOUR_DOMAIN.up.railway.app/api/v1

# Facility desktop
flutter build windows --dart-define=CBHI_API_BASE_URL=https://YOUR_DOMAIN.up.railway.app/api/v1
```

---

## Credentials

| Role | Phone | Password |
|------|-------|----------|
| System Admin | +251900000001 | Admin@1234 |
| Facility Staff | +251900000002 | Staff@1234 |

---

## Troubleshooting

**"Cannot find module '../dist/database/data-source'"**
→ Build didn't complete. Check build logs. Make sure Root Directory = `backend`.

**"password authentication failed for user postgres"**
→ DB_PASSWORD was entered with quotes. In Railway Variables, enter the raw value:
  `v!GAPf#g,Maa@5r` (no quotes)

**Health check failing (app keeps restarting)**
→ Check deploy logs for the actual error
→ DB connection issues are the most common cause

**CORS error from Flutter**
→ Add your domain to CORS_ALLOWED_ORIGINS
