# Maya City CBHI — Implementation Code Samples

This document contains representative, real-world code samples extracted directly from the Maya City CBHI platform codebase. Each sample is annotated to explain the pattern it demonstrates. Intended audience: developers integrating with or extending the platform, and technical writers producing reference documentation.

---

## Table of Contents

1. [Backend (NestJS)](#1-backend-nestjs)
   - 1.1 [Service Method — TypeORM Repository, DTO Validation, Business Logic](#11-service-method)
   - 1.2 [Controller Endpoint — JWT Guard, Role Decorator, Swagger Annotations](#12-controller-endpoint)
   - 1.3 [TypeORM Entity — AuditableEntity Extension and Relationships](#13-typeorm-entity)
2. [Member App (member_based_cbhi — Flutter)](#2-member-app)
   - 2.1 [Cubit + State Class Pair](#21-cubit--state-class-pair)
   - 2.2 [Screen Widget — BlocBuilder Pattern and Repository Call](#22-screen-widget--blocbuilder-pattern)
   - 2.3 [Repository Pattern — HTTP Call with Error Handling](#23-repository-pattern)
3. [Admin App (cbhi_admin_desktop — Flutter)](#3-admin-app)
   - 3.1 [Screen — DataTable with Loading/Error States](#31-screen--datatable-with-loadingerror-states)
   - 3.2 [Admin Repository — HTTP Call Example](#32-admin-repository--http-call-example)
4. [Facility App (cbhi_facility_desktop — Flutter)](#4-facility-app)
   - 4.1 [QR Scanner Screen](#41-qr-scanner-screen)
   - 4.2 [Claim Submission Screen — Real-Time Total](#42-claim-submission-screen)
   - 4.3 [Facility Repository — HTTP Call](#43-facility-repository--http-call)
5. [Shared Patterns](#5-shared-patterns)
   - 5.1 [Conditional Import Stub Pattern](#51-conditional-import-stub-pattern)
   - 5.2 [ARB Localization Key Usage in a Widget](#52-arb-localization-key-usage-in-a-widget)

---

## 1. Backend (NestJS)

### 1.1 Service Method

**File:** `backend/src/cbhi/cbhi.service.ts`

This excerpt from `CbhiService` shows the full pattern used throughout the backend:

- Constructor injection of multiple TypeORM repositories via `@InjectRepository()`
- A configurable business-rule constant read from `process.env`
- `registerStepOne()` — validates uniqueness, creates related entities (`User`, `Household`, `Beneficiary`) in a single transaction-like sequence, and returns a structured response DTO
- `renewCoverage()` — loads the access context, enforces role rules, resolves premium, bulk-updates beneficiary eligibility with a query builder, creates a `Payment` record, pushes an in-app notification, and invalidates the Redis snapshot cache

```typescript
// backend/src/cbhi/cbhi.service.ts (excerpts)

@Injectable()
export class CbhiService {
  // Premium per member is configurable via env var; defaults to 120 ETB
  private readonly premiumPerMember = Number(
    process.env.CBHI_PREMIUM_PER_MEMBER ?? 120,
  );

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Household)
    private readonly householdRepository: Repository<Household>,
    @InjectRepository(Beneficiary)
    private readonly beneficiaryRepository: Repository<Beneficiary>,
    @InjectRepository(Coverage)
    private readonly coverageRepository: Repository<Coverage>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(Notification)
    private readonly notificationRepository: Repository<Notification>,
    private readonly authService: AuthService,
    private readonly cacheService: CacheService,
  ) {}

  // ── Step 1: Create User + Household + primary Beneficiary ─────────────────
  async registerStepOne(dto: RegistrationStepOneDto) {
    const phoneNumber =
      this.authService.normalizePhoneNumber(dto.phone) ?? null;
    const email = this.authService.normalizeEmail(dto.email) ?? null;

    // Throws ConflictException if phone/email already registered
    await this.ensureAccountTargetAvailable({ phoneNumber, email });

    const user = await this.userRepository.save(
      this.userRepository.create({
        firstName: this.cleanRequired(dto.firstName, 'firstName'),
        lastName: this.cleanRequired(dto.lastName, 'lastName'),
        phoneNumber,
        email,
        preferredLanguage: dto.preferredLanguage ?? PreferredLanguage.ENGLISH,
        role: UserRole.HOUSEHOLD_HEAD,
        identityVerificationStatus: IdentityVerificationStatus.PENDING,
        isActive: true,
      }),
    );

    const household = await this.householdRepository.save(
      this.householdRepository.create({
        householdCode: this.generateCode('HH'),
        region: this.cleanRequired(dto.address.region, 'region'),
        zone: this.cleanRequired(dto.address.zone, 'zone'),
        woreda: this.clean(dto.address.woreda) ?? '',
        kebele: this.clean(dto.address.kebele) ?? '',
        phoneNumber,
        memberCount: dto.householdSize,
        coverageStatus: CoverageStatus.PENDING_RENEWAL,
        headUser: user,
      }),
    );

    user.household = household;
    await this.userRepository.save(user);

    // Primary beneficiary (household head) is always member 01
    const beneficiary = await this.beneficiaryRepository.save(
      this.beneficiaryRepository.create({
        memberNumber: this.generateCode('MBR'),
        fullName: this.composeFullName(dto.firstName, dto.middleName, dto.lastName),
        dateOfBirth: new Date(dto.dateOfBirth),
        gender: dto.gender,
        relationshipToHouseholdHead: RelationshipToHouseholdHead.HEAD,
        isPrimaryHolder: true,
        isEligible: false,
        household,
        userAccount: user,
      }),
    );

    return {
      registrationId: user.id,
      householdCode: household.householdCode,
      householdId: household.id,
      beneficiaryId: beneficiary.id,
      step: 'IDENTITY_PENDING',
    };
  }

  // ── Coverage renewal ───────────────────────────────────────────────────────
  async renewCoverage(userId: string, dto: RenewCoverageDto) {
    const access = await this.resolveAccessContext(userId);

    // Only the household head can renew
    if (!access.isHouseholdHead) {
      throw new BadRequestException(
        'Coverage renewal must be completed by the household head.',
      );
    }

    const coverage = await this.loadLatestCoverage(access.household.id);
    if (!coverage) {
      throw new NotFoundException(
        `Coverage for household ${access.household.householdCode} not found.`,
      );
    }

    const renewedAt = new Date();
    coverage.startDate = renewedAt;
    coverage.endDate = this.addMonths(renewedAt, 12);
    coverage.nextRenewalDate = coverage.endDate;
    coverage.status = CoverageStatus.ACTIVE;
    await this.coverageRepository.save(coverage);

    access.household.coverageStatus = CoverageStatus.ACTIVE;
    await this.householdRepository.save(access.household);

    // Bulk-update all beneficiaries in the household to eligible
    await this.beneficiaryRepository
      .createQueryBuilder()
      .update(Beneficiary)
      .set({ isEligible: true })
      .where('householdId = :householdId', { householdId: access.household.id })
      .execute();

    // Record payment if a method was provided
    if (dto.paymentMethod) {
      const payment = this.paymentRepository.create({
        transactionReference: this.generateCode('PAY'),
        amount: coverage.premiumAmount,
        method: dto.paymentMethod,
        status: PaymentStatus.SUCCESS,
        paidAt: renewedAt,
        coverage,
        processedBy: access.user,
      });
      await this.paymentRepository.save(payment);
    }

    // Push in-app notification to all household users
    await this.notifyHouseholdUsers(
      access.household.id,
      NotificationType.RENEWAL_REMINDER,
      'Coverage renewed',
      `Coverage for ${access.household.householdCode} is active until ${
        coverage.endDate.toISOString().split('T')[0]
      }.`,
      { coverageNumber: coverage.coverageNumber },
    );

    // Invalidate the 3-minute snapshot cache so the next GET returns fresh data
    await this.cacheService.del(`snapshot:${userId}`);
    return this.getMemberSnapshot(userId);
  }

  // ── Snapshot with Redis cache ──────────────────────────────────────────────
  async getMemberSnapshot(userId: string) {
    const cacheKey = `snapshot:${userId}`;
    return this.cacheService.getOrSet(
      cacheKey,
      () => this._buildMemberSnapshot(userId),
      3 * 60 * 1000, // 3-minute TTL
    );
  }
}
```

**Key patterns:**
- `@InjectRepository(Entity)` injects a TypeORM `Repository<T>` — no custom repository classes needed.
- `repository.create({...})` + `repository.save(entity)` is the standard two-step persist pattern.
- `createQueryBuilder().update().set().where().execute()` is used for bulk updates to avoid loading all rows into memory.
- Cache invalidation (`cacheService.del`) is called immediately after a mutation so the next read is fresh.

---

### 1.2 Controller Endpoint

**File:** `backend/src/admin/admin.controller.ts`

The admin controller demonstrates the full NestJS controller pattern: class-level role guard, typed query params, `@CurrentUser()` decorator, and a streaming CSV export response.

```typescript
// backend/src/admin/admin.controller.ts

import { Body, Controller, Get, Param, Patch, Post, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/cbhi.enums';
import { User } from '../users/user.entity';
import { AdminService } from './admin.service';

// @Roles() at class level applies to every route in this controller.
// JwtAuthGuard is applied globally in app.module.ts — no need to repeat it here.
@Controller('admin')
@Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // GET /api/v1/admin/indigent/pending?page=1&limit=50
  @Get('indigent/pending')
  getPendingIndigent(
    @CurrentUser() user: User,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getPendingIndigentApplications(
      user.id,
      page ? Number(page) : 1,
      limit ? Math.min(Number(limit), 100) : 50, // cap at 100 to prevent abuse
    );
  }

  // PATCH /api/v1/admin/indigent/:applicationId/review
  @Patch('indigent/:applicationId/review')
  reviewIndigent(
    @CurrentUser() user: User,
    @Param('applicationId') applicationId: string,
    @Body() dto: ReviewIndigentApplicationDto,
  ) {
    return this.adminService.reviewIndigentApplication(user.id, applicationId, dto);
  }

  // PATCH /api/v1/admin/claims/:claimId/decision
  @Patch('claims/:claimId/decision')
  reviewClaim(
    @CurrentUser() user: User,
    @Param('claimId') claimId: string,
    @Body() dto: ReviewClaimDto,
  ) {
    return this.adminService.reviewClaim(user.id, claimId, dto);
  }

  // GET /api/v1/admin/export?type=claims&from=2024-01-01&to=2024-12-31
  // Streams a CSV file directly to the response — bypasses NestJS serialization.
  @Get('export')
  async exportData(
    @CurrentUser() user: User,
    @Query() query: ExportQueryDto,
    @Res() res: Response,
  ) {
    const csv = await this.adminService.exportToCsv(user.id, query);
    const filename = `cbhi_${query.type ?? 'export'}_${
      new Date().toISOString().split('T')[0]
    }.csv`;
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(csv);
  }

  // GET /api/v1/admin/audit-logs?entityType=Claim&entityId=uuid&page=1
  @Get('audit-logs')
  getAuditLogs(
    @CurrentUser() user: User,
    @Query('entityType') entityType?: string,
    @Query('entityId') entityId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getAuditLogs(
      user.id,
      entityType,
      entityId,
      page ? Number(page) : 1,
      limit ? Math.min(Number(limit), 200) : 100,
    );
  }
}
```

**Key patterns:**
- `@Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)` at class level — the `RolesGuard` checks this metadata against the JWT payload's `role` field.
- `@CurrentUser()` is a custom parameter decorator that extracts the authenticated `User` entity from `request.user` (populated by `JwtAuthGuard`).
- `@Res() res: Response` bypasses NestJS response serialization for streaming responses (CSV, file downloads). Use sparingly — it disables interceptors.
- Query params are typed via DTO classes (`ExportQueryDto`) decorated with `class-validator` for automatic validation.

> **Note:** Swagger (`@ApiTags`, `@ApiOperation`, `@ApiBearerAuth`) decorators are omitted here for brevity but are present in the full source. Swagger is only enabled when `NODE_ENV !== 'production'`.

---

### 1.3 TypeORM Entity

**Files:** `backend/src/common/entities/auditable.entity.ts` · `backend/src/coverages/coverage.entity.ts` · `backend/src/users/user.entity.ts`

All entities extend `AuditableEntity`, which provides `id`, `createdAt`, and `updatedAt` automatically.

```typescript
// backend/src/common/entities/auditable.entity.ts

import {
  CreateDateColumn,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export abstract class AuditableEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt!: Date;
}
```

```typescript
// backend/src/coverages/coverage.entity.ts
// Demonstrates: AuditableEntity extension, enum columns, decimal columns,
// ManyToOne / OneToMany relationships, nullable optional columns.

import { Column, Entity, ManyToOne, OneToMany } from 'typeorm';
import { AuditableEntity } from '../common/entities/auditable.entity';
import { CoverageStatus, MembershipType } from '../common/enums/cbhi.enums';
import { Household } from '../households/household.entity';
import { BenefitPackage } from '../benefit-packages/benefit-package.entity';
import { Payment } from '../payments/payment.entity';

@Entity('coverages')
export class Coverage extends AuditableEntity {
  @Column({ length: 80, unique: true })
  coverageNumber!: string;

  @Column({ type: 'date' })
  startDate!: Date;

  @Column({ type: 'date' })
  endDate!: Date;

  // Enum column — all enums live in common/enums/cbhi.enums.ts
  @Column({
    type: 'enum',
    enum: CoverageStatus,
    default: CoverageStatus.ACTIVE,
  })
  status!: CoverageStatus;

  // Decimal stored as string to avoid floating-point precision issues
  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  premiumAmount!: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  paidAmount!: string;

  // Nullable optional columns use { nullable: true } to avoid migration issues
  @Column({ type: 'date', nullable: true })
  nextRenewalDate?: Date | null;

  // Added for B8 (30-day waiting period enforcement)
  @Column({ type: 'date', nullable: true })
  waitingPeriodEndsAt?: Date | null;

  @Column({ type: 'enum', enum: MembershipType, nullable: true })
  membershipType?: MembershipType | null;

  // Many coverages belong to one household; cascade delete removes orphans
  @ManyToOne(() => Household, (household) => household.coverages, {
    onDelete: 'CASCADE',
  })
  household!: Household;

  // Optional link to a benefit package catalog
  @ManyToOne(() => BenefitPackage, { nullable: true, eager: false })
  benefitPackage?: BenefitPackage | null;

  @OneToMany(() => Payment, (payment) => payment.coverage)
  payments!: Payment[];
}
```

```typescript
// backend/src/users/user.entity.ts (key columns)
// Demonstrates: unique indexes, select: false for sensitive columns,
// OneToOne relationships, TOTP 2FA columns.

@Entity('users')
export class User extends AuditableEntity {
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 32, nullable: true })
  nationalId?: string | null;

  @Column({ length: 120 })
  firstName!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 32, nullable: true })
  phoneNumber?: string | null;

  // select: false — never returned in queries unless explicitly selected
  @Column({ type: 'varchar', nullable: true, select: false })
  passwordHash?: string | null;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.BENEFICIARY })
  role!: UserRole;

  // TOTP secret is also excluded from default selects
  @Column({ type: 'varchar', nullable: true, select: false })
  totpSecret?: string | null;

  @Column({ default: false })
  totpEnabled!: boolean;

  // Token version — incremented on password change to invalidate all JWTs
  @Column({ type: 'int', default: 0 })
  tokenVersion!: number;

  // FCM push token for Firebase Cloud Messaging
  @Column({ type: 'varchar', length: 512, nullable: true })
  fcmToken?: string | null;

  // OneToOne: a user is the head of at most one household
  @OneToOne(() => Household, (household) => household.headUser)
  household?: Household | null;

  @OneToOne(() => Beneficiary, (beneficiary) => beneficiary.userAccount)
  beneficiaryProfile?: Beneficiary | null;
}
```

**Key patterns:**
- `@Index({ unique: true })` on `phoneNumber` and `email` enforces uniqueness at the DB level and speeds up login lookups.
- `select: false` on `passwordHash` and `totpSecret` prevents accidental exposure in API responses — you must use `.addSelect('user.passwordHash')` in a query builder to read them.
- `type: 'decimal'` columns are returned as `string` by TypeORM/PostgreSQL — always parse with `parseFloat()` before arithmetic.
- `onDelete: 'CASCADE'` on `ManyToOne` means deleting a `Household` also deletes its `Coverage` rows.

---

## 2. Member App (member_based_cbhi — Flutter)

### 2.1 Cubit + State Class Pair

**Files:** `member_based_cbhi/lib/src/cbhi_state.dart` · `member_based_cbhi/lib/src/registration/personal_info/personal_info_cubit.dart`

The platform uses the **Cubit** variant of `flutter_bloc` (v8). Each feature has a `*_state.dart` (immutable state) and a `*_cubit.dart` (business logic + `emit()`). No events — just method calls.

#### Top-level AppCubit (global app state)

```dart
// member_based_cbhi/lib/src/cbhi_state.dart

class AppState extends Equatable {
  const AppState({
    required this.snapshot,   // full household/coverage/claims data
    required this.locale,     // active language (en / am / om)
    required this.isLoading,
    required this.isSyncing,
    this.error,
    this.themeMode = ThemeMode.light,
  });

  factory AppState.initial() => const AppState(
    snapshot: null,
    locale: Locale('en'),
    isLoading: true,
    isSyncing: false,
    themeMode: ThemeMode.system,
  );

  final CbhiSnapshot? snapshot;
  final Locale locale;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final ThemeMode themeMode;

  // Convenience getter — avoids null checks in widgets
  bool get isDarkMode => themeMode == ThemeMode.dark;

  // copyWith pattern: only the fields you pass are changed
  AppState copyWith({
    CbhiSnapshot? snapshot,
    Locale? locale,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    ThemeMode? themeMode,
  }) {
    return AppState(
      snapshot: snapshot ?? this.snapshot,
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,           // null clears the error
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [snapshot, locale, isLoading, isSyncing, error, themeMode];
}

class AppCubit extends Cubit<AppState> {
  AppCubit(this.repository) : super(AppState.initial());

  final CbhiRepository repository;

  // Load cached data + restore persisted locale/theme on app start
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString('cbhi_locale');
      final savedTheme = prefs.getString('cbhi_dark_mode') ?? 'system';
      final themeMode = switch (savedTheme) {
        'light' => ThemeMode.light,
        'dark'  => ThemeMode.dark,
        _       => ThemeMode.system,
      };
      final locale = savedLocale != null ? Locale(savedLocale) : const Locale('en');
      final snapshot = await repository.loadCachedSnapshot();
      emit(state.copyWith(
        snapshot: snapshot,
        isLoading: false,
        locale: locale,
        themeMode: themeMode,
      ));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  // Pull fresh data from the API; fall back to cache on network error
  Future<void> sync() async {
    emit(state.copyWith(isSyncing: true, error: null));
    try {
      final snapshot = await repository.sync();
      emit(state.copyWith(snapshot: snapshot, isSyncing: false));
    } catch (error) {
      emit(state.copyWith(isSyncing: false, error: error.toString()));
    }
  }

  // Persist locale so it survives app restarts
  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString('cbhi_locale', locale.languageCode));
  }
}
```

#### Feature-scoped Cubit (registration step)

```dart
// member_based_cbhi/lib/src/registration/personal_info/personal_info_cubit.dart

part 'personal_info_state.dart';

class PersonalInfoCubit extends Cubit<PersonalInfoState> {
  PersonalInfoCubit() : super(const PersonalInfoState());

  // Single method handles all field updates — widgets call this on every onChange
  void updateField({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? region,
    String? zone,
    String? woreda,
    String? kebele,
    int? householdSize,
  }) {
    emit(state.copyWith(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      phone: phone,
      email: email,
      gender: gender,
      dateOfBirth: dateOfBirth,
      region: region,
      zone: zone,
      woreda: woreda,
      kebele: kebele,
      householdSize: householdSize,
    ));
  }

  // Validation logic lives in the Cubit, not the widget
  bool isValid() {
    return state.firstName.trim().isNotEmpty &&
        state.middleName.trim().isNotEmpty &&
        state.lastName.trim().isNotEmpty &&
        state.phone.trim().isNotEmpty &&
        state.gender.isNotEmpty &&
        state.dateOfBirth != null &&
        state.region.isNotEmpty &&
        state.zone.isNotEmpty &&
        state.householdSize >= 1;
  }

  // Convert state to a domain model for the repository layer
  PersonalInfoModel toModel() {
    final dob = state.dateOfBirth!;
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    return PersonalInfoModel(
      firstName: state.firstName.trim(),
      lastName: state.lastName.trim(),
      age: age,
      phone: state.phone.trim(),
      gender: state.gender,
      dateOfBirth: dob,
      region: state.region,
      zone: state.zone,
      householdSize: state.householdSize,
    );
  }
}
```

```dart
// member_based_cbhi/lib/src/registration/personal_info/personal_info_state.dart

part of 'personal_info_cubit.dart';

class PersonalInfoState {
  const PersonalInfoState({
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.phone = '',
    this.email,
    this.gender = '',
    this.dateOfBirth,
    this.region = '',
    this.zone = '',
    this.woreda,
    this.kebele,
    this.householdSize = 1,
    this.isSubmitting = false,
  });

  final String firstName;
  final String middleName;
  final String lastName;
  final String phone;
  final String? email;
  final String gender;
  final DateTime? dateOfBirth;
  final String? birthCertificateRef;
  final String region;
  final String zone;
  final String? woreda;
  final String? kebele;
  final int householdSize;
  final bool isSubmitting;

  PersonalInfoState copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? region,
    String? zone,
    String? woreda,
    String? kebele,
    int? householdSize,
    bool? isSubmitting,
  }) {
    return PersonalInfoState(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      region: region ?? this.region,
      zone: zone ?? this.zone,
      woreda: woreda ?? this.woreda,
      kebele: kebele ?? this.kebele,
      householdSize: householdSize ?? this.householdSize,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
```

**Key patterns:**
- State is always immutable — `copyWith()` returns a new instance.
- `part` / `part of` keeps state and cubit in separate files while sharing the same library scope.
- Validation and model conversion live in the Cubit, not in the widget tree.
- `Equatable` on `AppState` means `BlocBuilder` only rebuilds when props actually change.

---

### 2.2 Screen Widget — BlocBuilder Pattern

**File:** `member_based_cbhi/lib/src/dashboard/dashboard_screen.dart`

The dashboard screen shows the canonical `BlocBuilder` pattern: skeleton loading state, error-free rendering from snapshot, and pull-to-refresh triggering multiple cubits.

```dart
// member_based_cbhi/lib/src/dashboard/dashboard_screen.dart (excerpts)

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);

    // BlocBuilder rebuilds only when AppState changes (Equatable props)
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        // Show skeleton while loading — never show empty/broken UI
        if (state.isLoading) return const DashboardSkeleton();

        final snapshot = state.snapshot ?? CbhiSnapshot.empty();
        final isFamilyMember = context.watch<AuthCubit>().state.isFamilyMember;

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            // Pull-to-refresh syncs all relevant cubits in parallel
            await Future.wait([
              context.read<AppCubit>().sync(),
              context.read<AuthCubit>().refreshSession(),
              context.read<MyFamilyCubit>().load(),
            ]);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Greeting uses localized string + first name from snapshot
                    Text(
                      '${strings.t('hello')}, ${snapshot.viewerName.split(' ').first}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Hero coverage card — status-aware colors
                    _CoverageHeroCard(
                      snapshot: snapshot,
                      isFamilyMember: isFamilyMember,
                    ),

                    const SizedBox(height: AppTheme.spacingM),

                    // Bento stat tiles — coverage status + member count
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStatTile(
                            label: strings.t('coverage'),
                            value: snapshot.coverageStatus,
                            icon: Icons.verified_user_outlined,
                            color: _coverageColor(snapshot.coverageStatus),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStatTile(
                            label: strings.t('members'),
                            value: snapshot.familyMembers.length.toString(),
                            icon: Icons.group_outlined,
                            color: AppTheme.m3Primary,
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Status-to-color mapping — used by stat tiles and coverage hero card
Color _coverageColor(String status) => switch (status.toUpperCase()) {
  'ACTIVE'                          => AppTheme.success,
  'EXPIRED'                         => AppTheme.error,
  'PENDING_RENEWAL' || 'WAITING_PERIOD' => AppTheme.warning,
  _                                 => AppTheme.textSecondary,
};
```

**Key patterns:**
- `context.watch<AppCubit>()` subscribes to the cubit and rebuilds on every state change. `context.read<AppCubit>()` reads without subscribing — used inside callbacks.
- `CbhiSnapshot.empty()` provides a safe default so widgets never need null checks on the snapshot itself.
- `Future.wait([...])` in `onRefresh` runs multiple async operations concurrently.
- Color logic is extracted to a top-level function (`_coverageColor`) — keeps `build()` readable.

---

### 2.3 Repository Pattern

**File:** `member_based_cbhi/lib/src/cbhi_data.dart`

`CbhiRepository` is the single point of contact between the Flutter app and the backend API. It handles authentication headers, timeouts, error classification (retryable vs. permanent), and offline queuing.

```dart
// member_based_cbhi/lib/src/cbhi_data.dart (excerpts)

// API base URL is injected at build time via --dart-define.
// Falls back to the Vercel deployment URL for web builds.
String get kDefaultApiBaseUrl {
  const envUrl = String.fromEnvironment('CBHI_API_BASE_URL');
  var url = envUrl.isNotEmpty
      ? envUrl
      : 'https://member-based-cbhi.vercel.app/api/v1';
  url = url.trimRight();
  if (url.endsWith('/')) url = url.substring(0, url.length - 1);
  if (!url.endsWith('/api/v1')) url = '$url/api/v1';
  return url;
}

// Internal exception type — carries retryability flag
class _ApiException implements Exception {
  const _ApiException(this.message, {this.retryable = false, this.statusCode});
  final String message;
  final bool retryable;
  final int? statusCode;
  @override
  String toString() => message;
}

class CbhiRepository {
  CbhiRepository({
    required this.localDb,
    http.Client? client,
    String? apiBaseUrl,
  }) : _client = client ?? http.Client(),
       apiBaseUrl = apiBaseUrl ?? kDefaultApiBaseUrl;

  final CbhiLocalDb localDb;
  final http.Client _client;
  final String apiBaseUrl;

  // ── Sync: flush offline queue, then pull fresh data ───────────────────────
  Future<CbhiSnapshot> sync([String? householdCode]) async {
    await syncPendingActions();           // replay any queued mutations first
    final session = await restoreSession();
    if (session != null) {
      try {
        final remote = await _getJson('/cbhi/me', authorized: true);
        final snapshot = _snapshotFromRemote(remote);
        await localDb.writeSnapshot(snapshot);  // persist to local DB / SharedPrefs
        return snapshot;
      } on _ApiException catch (error) {
        if (!error.retryable) rethrow;    // surface auth/validation errors
        // Network error — fall through to cached data
      }
    }
    return loadCachedSnapshot();          // always return something usable
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────

  static const _kGetTimeout   = Duration(seconds: 20);
  static const _kWriteTimeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> _getJson(
    String path, {
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$apiBaseUrl$path'),
            headers: headers ?? await _headers(authorized: authorized),
          )
          .timeout(
            _kGetTimeout,
            onTimeout: () => throw const _ApiException(
              'Request timed out. Please check your connection.',
              retryable: true,
            ),
          );
      return _decodeResponse(path, response);
    } catch (error) {
      if (error is _ApiException) rethrow;
      throw const _ApiException('Network unavailable.', retryable: true);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload, {
    bool authorized = false,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$apiBaseUrl$path'),
            headers: await _headers(authorized: authorized),
            body: jsonEncode(payload),
          )
          .timeout(
            _kWriteTimeout,
            onTimeout: () => throw const _ApiException(
              'Request timed out. Please check your connection.',
              retryable: true,
            ),
          );
      return _decodeResponse(path, response);
    } catch (error) {
      if (error is _ApiException) rethrow;
      throw const _ApiException(
        'Connection to server failed. Please check your internet.',
        retryable: true,
      );
    }
  }

  // Builds Authorization header from secure storage; throws 401 if no session
  Future<Map<String, String>> _headers({required bool authorized}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authorized) {
      final session = await _readStoredSession();
      final token = session?.accessToken;
      if (token == null || token.isEmpty) {
        throw const _ApiException(
          'You need to sign in before using this feature.',
          retryable: false,
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Decodes JSON and maps HTTP status codes to typed exceptions
  Map<String, dynamic> _decodeResponse(String path, http.Response response) {
    final body = response.body.trim();
    final decoded = body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(body) as Map).cast<String, dynamic>();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded['message'];
    final serverRetryable = decoded['retryable'];
    throw _ApiException(
      message is List
          ? message.join(', ')
          : (message?.toString() ?? 'Request failed: ${response.statusCode}'),
      retryable: serverRetryable is bool
          ? serverRetryable
          : response.statusCode >= 500,
      statusCode: response.statusCode,
    );
  }

  // Offline-first: queue a mutation for later replay
  Future<CbhiSnapshot> registerFull({
    required PersonalInfoModel personalInfo,
    required IdentityModel identity,
    required MembershipSelection membership,
  }) async {
    try {
      return await _registerFullRemote(
        personalInfo: personalInfo,
        identity: identity,
        membership: membership,
      );
    } on _ApiException catch (error) {
      if (!error.retryable) rethrow;   // validation errors surface immediately
      // Network error — save to local queue and return a pending snapshot
      await localDb.queueAction('registration_full', {
        'personalInfo': personalInfo.toJson(),
        'identity': identity.toJson(),
        'membership': membership.toJson(),
      });
      return _buildPendingSnapshot(
        personalInfo: personalInfo,
        membership: membership,
      );
    }
  }
}
```

**Key patterns:**
- `_ApiException.retryable` distinguishes network failures (queue offline) from validation/auth errors (surface to user immediately).
- `authorized: true` on `_getJson` / `_postJson` automatically attaches the JWT from secure storage.
- `sync()` always returns a `CbhiSnapshot` — either fresh from the API or from the local cache — so the UI never blocks.
- The offline queue (`localDb.queueAction`) stores the full payload; `syncPendingActions()` replays it on the next successful connection.

---
