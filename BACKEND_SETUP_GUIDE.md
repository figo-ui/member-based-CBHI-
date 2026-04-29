# Backend Setup Guide

## Problem

The backend is not starting locally because:
1. It's trying to connect to the Supabase database which may have connection issues
2. Docker Desktop is not running (needed for local PostgreSQL)

## Solutions

You have **3 options** to run the system:

---

## Option 1: Use Vercel Backend (Recommended for Testing Apps)

**Pros:** No local backend needed, just run the Flutter apps
**Cons:** Vercel backend currently has errors that need to be fixed

### Steps:
1. The Flutter apps are already configured to use the Vercel backend
2. Just run the apps with the dart-define parameter:

```bash
# Member App
cd member_based_cbhi
flutter run --dart-define=CBHI_API_BASE_URL=https://member-based-cbhi.vercel.app/api/v1

# Admin App
cd cbhi_admin_desktop
flutter run -d windows --dart-define=CBHI_API_BASE_URL=https://member-based-cbhi.vercel.app/api/v1
```

**Note:** The Vercel backend is currently showing "FUNCTION_INVOCATION_FAILED" errors. This needs to be debugged on Vercel.

---

## Option 2: Run Backend Locally with Docker (Best for Development)

**Pros:** Full control, can debug, fastest development cycle
**Cons:** Requires Docker Desktop to be running

### Steps:

1. **Start Docker Desktop**
   - Open Docker Desktop application
   - Wait for it to fully start (whale icon in system tray should be steady)

2. **Start Local Database**
   ```bash
   cd C:\Users\hp\Desktop\Member_Based_CBHI
   docker compose --profile local up -d
   ```

3. **Update Backend .env for Local Database**
   Edit `backend/.env` and change these lines:
   ```env
   # Comment out Supabase settings
   # DB_HOST=aws-0-eu-west-1.pooler.supabase.com
   # DB_PORT=6543
   # DB_USERNAME=postgres.nauyjsrhykayyzqomiyx
   # DB_PASSWORD="v!GAPf#g,Maa@5r"
   # DB_NAME=postgres
   # DB_SSL=true

   # Use local Docker database instead
   DB_HOST=localhost
   DB_PORT=5432
   DB_USERNAME=cbhi_user
   DB_PASSWORD=cbhi_pass
   DB_NAME=cbhi_db
   DB_SSL=false
   NODE_ENV=development
   ```

4. **Run Database Migrations**
   ```bash
   cd backend
   npm run migration:run
   ```

5. **Seed Admin User**
   ```bash
   npm run db:seed
   ```

6. **Start Backend**
   ```bash
   npm run start:dev
   ```

7. **Test Backend**
   ```bash
   curl http://localhost:3000/api/v1/health
   ```

8. **Run Flutter Apps with Local Backend**
   ```bash
   # Member App
   cd member_based_cbhi
   flutter run --dart-define=CBHI_API_BASE_URL=http://localhost:3000/api/v1

   # Admin App
   cd cbhi_admin_desktop
   flutter run -d windows --dart-define=CBHI_API_BASE_URL=http://localhost:3000/api/v1
   ```

---

## Option 3: Fix Vercel Backend Deployment

**Pros:** Once fixed, everyone can use it without local setup
**Cons:** Requires debugging Vercel deployment issues

### Steps:

1. **Check Vercel Logs**
   ```bash
   # Install Vercel CLI if not already installed
   npm install -g vercel

   # Login to Vercel
   vercel login

   # Check logs
   vercel logs https://member-based-cbhi.vercel.app
   ```

2. **Common Vercel Issues:**
   - Database connection timeout (Supabase connection pooler issues)
   - Environment variables not set correctly
   - Cold start timeout (function takes too long to initialize)
   - Missing dependencies in production build

3. **Quick Fix - Redeploy:**
   ```bash
   cd backend
   vercel --prod
   ```

---

## Recommended Approach

For **immediate testing of the Flutter apps:**

1. **Start Docker Desktop** (if not running)
2. **Run Option 2** (Local Backend with Docker)
3. This gives you full control and fastest development cycle

For **production/deployment:**
- Fix the Vercel backend (Option 3)
- This allows the apps to work without local backend

---

## Current Status

✅ **Admin App:** Compiles successfully, ready to run
✅ **Member App:** Compiles successfully, ready to run
❌ **Backend (Local):** Needs Docker Desktop running + local database setup
❌ **Backend (Vercel):** Has deployment errors, needs debugging

---

## Quick Commands Reference

### Check if Docker is Running
```bash
docker ps
```

### Start Local Stack
```bash
docker compose --profile local up -d
```

### Stop Local Stack
```bash
docker compose --profile local down
```

### View Backend Logs (Local)
```bash
cd backend
npm run start:dev
# Logs will appear in console
```

### View Backend Logs (Vercel)
```bash
vercel logs https://member-based-cbhi.vercel.app --follow
```

### Test Backend Health
```bash
# Local
curl http://localhost:3000/api/v1/health

# Vercel
curl https://member-based-cbhi.vercel.app/api/v1/health
```

---

## Next Steps

1. **Choose your option** (I recommend Option 2 for development)
2. **Start Docker Desktop** if using Option 2
3. **Follow the steps** for your chosen option
4. **Run the Flutter apps** once backend is working
5. **Test the ID scanner feature** in the member app

---

## Need Help?

If you encounter issues:
1. Check Docker Desktop is running (for Option 2)
2. Verify database connection in `.env` file
3. Check backend logs for specific errors
4. Ensure all environment variables are set correctly
