# Project Structure

## Monorepo Layout

```
/
├── backend/                  # NestJS API
├── member_based_cbhi/        # Flutter member mobile/web app
├── cbhi_admin_desktop/       # Flutter admin web app
├── cbhi_facility_desktop/    # Flutter facility web app
├── supabase/                 # Supabase migrations and config
├── nginx/                    # nginx reverse proxy config
├── docker-compose.yml        # Multi-profile compose file
└── .kiro/                    # Kiro agent config and steering
```

---

## Backend (`backend/src/`)

NestJS feature-module architecture. Each domain has its own folder:

```
src/
├── app.module.ts             # Root module — wires all feature modules
├── main.ts                   # Bootstrap, global pipes/filters/interceptors
├── common/
│   ├── decorators/           # @CurrentUser, @Public, @Roles
│   ├── entities/             # AuditableEntity base class
│   ├── enums/                # cbhi.enums.ts — all shared enums
│   ├── filters/              # GlobalExceptionFilter
│   ├── guards/               # JwtAuthGuard, RolesGuard
│   ├── interceptors/         # TimeoutInterceptor
│   ├── cache/                # Redis cache service
│   └── logger/               # CbhiLoggerService
├── database/
│   ├── data-source.ts        # TypeORM DataSource (used by CLI)
│   └── migrations/           # TypeORM migration files
├── auth/                     # JWT + OTP + TOTP auth
├── users/                    # User entity
├── cbhi/                     # Core CBHI: registration, coverage, digital card
├── households/               # Household entity
├── beneficiaries/            # Beneficiary entity
├── coverages/                # Coverage entity
├── claims/                   # Claim entity + appeal
├── claim-items/              # Claim line items
├── payments/                 # Payment entity
├── payment-gateway/          # Chapa integration
├── grievances/               # Grievance workflow
├── indigent/                 # Indigent application workflow
├── benefit-packages/         # Benefit package management
├── health-facilities/        # Health facility registry
├── facility/                 # Facility-facing API (eligibility, claims)
├── facility-users/           # Facility staff accounts
├── cbhi-officers/            # CBHI officer accounts
├── admin/                    # Admin-facing API
├── locations/                # Region/woreda/kebele hierarchy
├── notifications/            # FCM + WebSocket notifications
├── sms/                      # Africa's Talking SMS
├── storage/                  # Supabase file storage
├── audit/                    # Audit log
├── jobs/                     # BullMQ scheduled jobs
├── integrations/             # Fayda ID + OpenIMIS
├── vision/                   # OCR/vision service
├── documents/                # Document entity
├── system-settings/          # Key-value system config
├── demo/                     # Demo/sandbox mode
└── health/                   # Health check endpoint
```

### Backend Conventions

- Each feature module contains: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.dto.ts`, `*.entity.ts`
- Entities extend `AuditableEntity` (adds `createdAt`, `updatedAt`, `createdBy`)
- All enums live in `common/enums/cbhi.enums.ts`
- DTOs use `class-validator` decorators for validation
- Controllers are protected by `JwtAuthGuard` + `RolesGuard` globally; use `@Public()` to opt out
- `NEVER` use `synchronize: true` in production — always use migrations
- API prefix: `/api/v1`

---

## Flutter Apps

All three apps follow the same internal layout:

```
lib/
├── main.dart                 # Entry point
└── src/
    ├── app.dart / cbhi_app.dart   # Root widget, MaterialApp + BlocProvider
    ├── data/                 # Repository class (HTTP + local DB)
    ├── blocs/                # Cubits (one per feature or screen)
    ├── screens/              # One file per screen
    ├── widgets/              # Shared reusable widgets
    ├── theme/                # ThemeData
    └── i18n/                 # AppLocalizations wrapper
```

**Member app** has additional structure:
```
lib/
├── l10n/                     # ARB files: app_en.arb, app_am.arb, app_om.arb
└── src/
    ├── cbhi_state.dart       # AppCubit + AppState (top-level state)
    ├── cbhi_data.dart        # CbhiRepository + CbhiSnapshot + local DB
    ├── models/               # Freezed/json_serializable models
    ├── registration/         # Multi-step registration flow
    │   ├── personal_info/
    │   ├── identity/
    │   ├── membership/
    │   └── confirmation/
    └── shared/               # Cross-cutting services (biometric, secure storage, sync)
```

### Flutter Conventions

- State management: **Cubit** (not full Bloc) — `emit()` new states, no events
- One `*_cubit.dart` + `*_state.dart` per feature; simple screens may inline state in the screen file
- Repository pattern: all API calls go through a repository class, never directly from widgets
- Web platform: use `SharedPreferences` instead of SQLite (no WASM worker)
- Localization: all user-facing strings must have entries in all three ARB files (`en`, `am`, `om`)
- API base URL injected via `--dart-define=CBHI_API_BASE_URL=...`; falls back to the Vercel deployment URL

---

## Supabase (`supabase/`)

```
supabase/
├── config.toml               # Supabase project config
└── migrations/               # SQL migration files (timestamped)
```

SQL migrations are separate from TypeORM migrations. TypeORM migrations handle the NestJS entity schema; Supabase migrations handle RLS policies and Supabase-specific setup.
