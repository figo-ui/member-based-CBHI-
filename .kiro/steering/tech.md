# Tech Stack

## Backend (`backend/`)

- **Runtime**: Node.js ≥ 20
- **Framework**: NestJS 11 (TypeScript 5)
- **ORM**: TypeORM 0.3 with PostgreSQL (pg)
- **Database**: PostgreSQL 16 via Supabase (production) or local Docker
- **Cache / Queue**: Redis 7 + BullMQ (optional — disabled on Vercel serverless)
- **Auth**: JWT (`@nestjs/jwt`), OTP via SMS, TOTP (2FA)
- **Notifications**: Firebase FCM, WebSockets (`socket.io`)
- **SMS**: Africa's Talking
- **Payments**: Chapa
- **Storage**: Supabase Storage
- **Monitoring**: Sentry (`@sentry/nestjs`)
- **Validation**: `class-validator` + `class-transformer`
- **API Docs**: Swagger (`@nestjs/swagger`) — dev only
- **Rate Limiting**: `@nestjs/throttler` (120 req/min default, 10 OTP/10 min)

## Flutter Apps

All three apps share the same toolchain:

- **Flutter SDK**: ^3.10.1 / Dart SDK ^3.10.1
- **State management**: `flutter_bloc` v8 (Cubit pattern) — **stay on v8**, v9 has breaking API changes
- **HTTP**: `http` package
- **Serialization**: `json_serializable` + `freezed` (member app only)
- **Local storage**: `sqflite` (mobile/desktop), `SharedPreferences` (web fallback)
- **Secure storage**: `flutter_secure_storage` v9 — **stay on v9**
- **Localization**: Flutter gen-l10n (`flutter_localizations`)
- **Fonts**: Outfit (bundled)
- **Animations**: `flutter_animate`
- **QR**: `qr_flutter` (display), `mobile_scanner` (facility app scan)
- **Biometrics**: `local_auth` v2 — **stay on v2**
- **File picking**: `file_picker` v10 — **stay on v10**
- **Deep links**: `app_links` v6 — **stay on v6**

## Infrastructure

- **Containerization**: Docker + docker-compose (profiles: `local`, `supabase`)
- **Reverse proxy**: nginx with Let's Encrypt TLS
- **Backend deploy**: Vercel (serverless, `backend/vercel.json`)
- **Frontend deploy**: Vercel (each Flutter app is a separate Vercel project)
- **CI**: GitHub Actions (`.github/workflows/ci.yml`)

---

## Common Commands

### Backend

```bash
# Install dependencies
cd backend && npm install

# Development (watch mode)
npm run start:dev

# Build
npm run build

# Production
npm run start:prod

# Run TypeORM migrations
npm run migration:run

# Generate a new migration
npm run migration:generate -- src/database/migrations/MigrationName

# Seed admin user
node scripts/seed-admin.js

# Lint + format
npm run lint
npm run format

# Tests
npm test                  # unit tests (jest)
npm run test:cov          # with coverage
npm run test:e2e          # e2e tests
```

### Flutter Apps

```bash
# Run in development (replace <app> with member_based_cbhi, cbhi_admin_desktop, or cbhi_facility_desktop)
cd <app>
flutter pub get
flutter run -d chrome     # web
flutter run               # native

# Build web release
flutter build web --release

# Generate l10n and code-gen (member app)
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze
flutter analyze
```

### Docker

```bash
# Local dev (Postgres + Redis + backend)
docker compose --profile local up -d

# Supabase mode (Redis + backend only)
docker compose --profile supabase up -d
```

## Environment Variables

Copy `backend/.env.example` to `backend/.env`. Key variables:

| Variable | Notes |
|----------|-------|
| `DATABASE_URL` | Full Postgres URL (takes precedence over individual DB_* vars) |
| `DB_HOST/PORT/USERNAME/PASSWORD/NAME` | Used when DATABASE_URL is not set |
| `DB_SSL` | `true` for Supabase |
| `AUTH_JWT_SECRET` | Min 32 chars |
| `REDIS_HOST` | If unset, BullMQ/JobsModule are disabled |
| `DEMO_MODE` | `true` to stub all external services |
| `NODE_ENV` | `production` disables Swagger and auto-sync |

Flutter apps receive the API URL via dart-define:
```bash
flutter build web --dart-define=CBHI_API_BASE_URL=https://your-api.com/api/v1
```
