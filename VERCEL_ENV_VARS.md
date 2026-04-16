# Vercel Environment Variables

Backend URL: `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app`

---

## For Each Flutter App — Add This ONE Variable

Go to each Vercel project → **Settings** → **Environment Variables** → Add:

| Key | Value |
|-----|-------|
| `CBHI_API_BASE_URL` | `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1` |

---

## Member App (already deployed — needs redeploy with API URL)

Project: `member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app`

1. Vercel Dashboard → find this project → **Settings** → **Environment Variables**
2. Add: `CBHI_API_BASE_URL` = `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1`
3. **Deployments** tab → latest deployment → **⋯** → **Redeploy**

---

## Admin App — New Deployment

1. [vercel.com/new](https://vercel.com/new) → Import your repo
2. **Root Directory** → `cbhi_admin_desktop`
3. Framework: **Other**
4. Add env var: `CBHI_API_BASE_URL` = `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1`
5. Deploy

---

## Facility App — New Deployment

1. [vercel.com/new](https://vercel.com/new) → Import your repo
2. **Root Directory** → `cbhi_facility_desktop`
3. Framework: **Other**
4. Add env var: `CBHI_API_BASE_URL` = `https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app/api/v1`
5. Deploy

---

## Backend Vercel Env Vars (already deployed project)

Go to the backend Vercel project → **Settings** → **Environment Variables** → add all of these:

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

After adding all vars → **Redeploy** the backend.

---

## After Admin + Facility Are Deployed

Update `CORS_ALLOWED_ORIGINS` in the backend Vercel project to add the new URLs:

```
CORS_ALLOWED_ORIGINS=https://member-based-cbhi-dwpejr0y4-figo-uis-projects.vercel.app,https://YOUR_ADMIN_URL.vercel.app,https://YOUR_FACILITY_URL.vercel.app,http://localhost:3000,http://10.0.2.2:3000
```
