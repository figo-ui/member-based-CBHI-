# Vercel Deployment — Full Stack CBHI

## Architecture

```
Vercel (backend)          Vercel (member app)
member-based-cbhi-        member-based-cbhi-
dwpejr0y4-figo-uis-  ←── dwpejr0y4-figo-uis-
projects.vercel.app       projects.vercel.app
        ↑
        │  (same project — backend IS the deployed URL)
        │
Supabase PostgreSQL
(aws-0-eu-west-1.pooler.supabase.com:6543)
```

**Backend URL:** `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app`
**API base:** `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1`

---

## Backend — Already Deployed

The NestJS backend is live at the URL above via `backend/api/index.ts` (serverless handler).

### Required Vercel Environment Variables (backend project)

Go to: Vercel Dashboard → backend project → **Settings** → **Environment Variables**

Add each of these (no quotes around values):

```
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
CBHI_PREMIUM_PER_MEMBER=120
DEFAULT_LANGUAGE=en
SUPPORTED_LANGUAGES=am,om,en
INDIGENT_INCOME_THRESHOLD=1000
INDIGENT_FAMILY_SIZE_THRESHOLD=5
INDIGENT_APPROVAL_THRESHOLD=70
APP_BASE_URL=https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app
CORS_ALLOWED_ORIGINS=https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app,http://localhost:3000,http://10.0.2.2:3000
CHAPA_CALLBACK_URL=https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1/payments/webhook/chapa
CHAPA_RETURN_URL=https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1/payments/verify
```

After adding → **Redeploy** the backend project.

### Verify Backend

```
https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1/health
→ {"status":"ok",...}

https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1/demo/status
→ {"demoMode":true,...}
```

---

## Member App — Redeploy with API URL

The member app was deployed from the same repo. It needs to be redeployed with the API URL set.

1. Vercel Dashboard → find the member app project
2. **Settings** → **Environment Variables** → Add:
   - `CBHI_API_BASE_URL` = `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1`
3. **Deployments** → latest → **⋯** → **Redeploy**

> The `vercel-build.sh` already falls back to the backend URL if `CBHI_API_BASE_URL` is not set, so this step is optional but recommended.

---

## Admin App — New Vercel Project

1. [vercel.com/new](https://vercel.com/new) → **Import Git Repository** → select your repo
2. **Root Directory** → type `cbhi_admin_desktop` → click **Continue**
3. Framework Preset: **Other**
4. **Environment Variables** → Add:
   - `CBHI_API_BASE_URL` = `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1`
5. Click **Deploy** (takes ~3-4 min — Flutter SDK downloads during build)

---

## Facility App — New Vercel Project

Same as Admin App but Root Directory = `cbhi_facility_desktop`.

1. [vercel.com/new](https://vercel.com/new) → Import repo
2. **Root Directory** → `cbhi_facility_desktop`
3. Add env var: `CBHI_API_BASE_URL` = `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1`
4. Deploy

---

## After Admin + Facility Are Deployed

Update `CORS_ALLOWED_ORIGINS` in the **backend** Vercel project to add the new URLs:

```
CORS_ALLOWED_ORIGINS=https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app,https://YOUR_ADMIN_URL.vercel.app,https://YOUR_FACILITY_URL.vercel.app,http://localhost:3000,http://10.0.2.2:3000
```

---

## Login Credentials

| Role | Phone | Password |
|------|-------|----------|
| System Admin | +251900000001 | Admin@1234 |
| Facility Staff | +251900000002 | Staff@1234 |

---

## Troubleshooting

**API returns 500 on first request (cold start)**
→ Normal — Vercel serverless has ~1-2s cold start. Retry once.

**"password authentication failed"**
→ `DB_PASSWORD` must be entered without quotes in Vercel Variables UI.
→ Value: `v!GAPf#g,Maa@5r` (raw, no quotes)

**Flutter app shows blank screen**
→ Open browser DevTools → Console tab → check for errors
→ Usually means `CBHI_API_BASE_URL` is wrong or missing

**CORS error in browser**
→ Add the Flutter app's Vercel URL to `CORS_ALLOWED_ORIGINS` in backend env vars
→ Redeploy the backend after updating

**Build fails: "flutter: command not found"**
→ The `vercel-build.sh` downloads Flutter automatically — check build logs for network errors
