# Vercel Deployment Guide — Maya City CBHI

## Projects

| App | Vercel Project Name | Root Directory |
|-----|---------------------|----------------|
| Admin | `cbhi-admin` | `cbhi_admin_desktop` |
| Facility | `cbhi-facility` | `cbhi_facility_desktop` |
| Backend | `member-based-cbhi` | `backend` |

## One-Time Setup (do this once per project)

### Step 1 — Create Vercel projects linked to GitHub

1. Go to [vercel.com/new](https://vercel.com/new)
2. Import your GitHub repo
3. For the **Admin** project:
   - Project Name: `cbhi-admin`
   - Root Directory: `cbhi_admin_desktop`
   - Framework Preset: Other
   - Build Command: `bash ./vercel-build.sh`
   - Output Directory: `build/web`
4. Add environment variable:
   - `CBHI_API_BASE_URL` = `https://member-based-cbhi.vercel.app/api/v1`
5. Click Deploy

6. Repeat for **Facility** project:
   - Project Name: `cbhi-facility`
   - Root Directory: `cbhi_facility_desktop`
   - Same build settings
   - Same env var

### Step 2 — Get GitHub Actions secrets

You need 4 secrets in GitHub → Settings → Secrets → Actions:

| Secret | Where to get it |
|--------|----------------|
| `VERCEL_TOKEN` | vercel.com → Settings → Tokens → Create |
| `VERCEL_ORG_ID` | vercel.com → Settings → General → Team ID (or your personal account ID) |
| `VERCEL_ADMIN_PROJECT_ID` | Vercel `cbhi-admin` project → Settings → General → Project ID |
| `VERCEL_FACILITY_PROJECT_ID` | Vercel `cbhi-facility` project → Settings → General → Project ID |

### Step 3 — Add secrets to GitHub

Go to your repo → Settings → Secrets and variables → Actions → New repository secret

Add each of the 4 secrets above.

### Step 4 — Push to main

```bash
git add .
git commit -m "feat: wire all apps, FCM, deploy config"
git push origin main
```

GitHub Actions will:
1. Run tests for all 3 apps + backend
2. Deploy `cbhi-admin` to Vercel → `https://cbhi-admin.vercel.app`
3. Deploy `cbhi-facility` to Vercel → `https://cbhi-facility.vercel.app`

## After First Deploy — Update CORS

Once both apps are deployed, update `backend/.env` on Vercel:

```
CORS_ALLOWED_ORIGINS=*.vercel.app,https://cbhi-admin.vercel.app,https://cbhi-facility.vercel.app,https://member-based-cbhi.vercel.app,http://localhost:3000
```

This is already set in `backend/vercel.json` — just redeploy the backend.

## URLs After Deployment

| App | URL |
|-----|-----|
| Backend API | https://member-based-cbhi.vercel.app/api/v1 |
| Admin Portal | https://cbhi-admin.vercel.app |
| Facility Portal | https://cbhi-facility.vercel.app |
| Member App | Android APK (sideload) or Play Store |

## Login Credentials

| Role | Phone/Email | Password |
|------|-------------|----------|
| Admin | +251900000001 | Admin@1234 |
| Facility Staff | +251900000002 | Staff@1234 |
| Test Member | +251935092404 | OTP via SMS |
