import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'auth/onboarding_screen.dart';
import 'auth/privacy_consent_screen.dart';
import 'payment/payment_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'auth/auth_cubit.dart';
import 'auth/auth_state.dart';
import 'auth/welcome_screen.dart';
import 'cbhi_data.dart';
import 'cbhi_localizations.dart';
import 'cbhi_state.dart';
import 'family/my_family_cubit.dart';
import 'family/my_family_screen.dart';
import 'registration/registration_cubit.dart';
import 'registration/registration_flow.dart';
import 'shared/animated_widgets.dart';
import 'claims/member_claims_screen.dart';
import 'facilities/facility_finder_screen.dart';
import 'shared/biometric_service.dart';
import 'shared/help_screen.dart';
import 'shared/skeleton_widgets.dart';
import 'staff/facility_staff_screen.dart';
import 'theme/app_theme.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

String _formatDateLabel(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return 'Not available';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final month = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][parsed.month - 1];
  return '${parsed.day.toString().padLeft(2, '0')} $month ${parsed.year}';
}

// ─── Renew Coverage Sheet ───────────────────────────────────────────────────

Future<void> _showRenewCoverageSheet(
  BuildContext context,
  CbhiSnapshot snapshot,
  CbhiRepository repository,
) async {
  // If premium > 0, use Chapa payment gateway
  if (snapshot.premiumAmount > 0) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          repository: repository,
          snapshot: snapshot,
          onPaymentComplete: () async {
            Navigator.of(context).pop();
            await context.read<AppCubit>().sync();
          },
        ),
      ),
    );
    return;
  }

  // Indigent/free renewal — confirm without payment
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.autorenew, color: AppTheme.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirm Free Renewal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This household qualifies for subsidized coverage. Tap confirm to extend your coverage for another year at no cost.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await context.read<AppCubit>().renewCoverage();
                if (context.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm Free Renewal'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CbhiApp
// ═══════════════════════════════════════════════════════════════════════════

class CbhiApp extends StatelessWidget {
  const CbhiApp({super.key, required this.repository});

  final CbhiRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppCubit>(create: (_) => AppCubit(repository)),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit(repository)),
        BlocProvider<RegistrationCubit>(
          create: (_) => RegistrationCubit(repository),
        ),
        BlocProvider<MyFamilyCubit>(create: (_) => MyFamilyCubit(repository)),
      ],
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final appLocale = state.locale;
          final frameworkLocale = CbhiLocalizations.resolveFrameworkLocale(
            appLocale,
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: frameworkLocale,
            supportedLocales: CbhiLocalizations.frameworkSupportedLocales,
            localizationsDelegates: [
              CbhiLocalizations.delegateFor(appLocale),
              GlobalWidgetsLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const _BootstrapScreen(),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bootstrap
// ═══════════════════════════════════════════════════════════════════════════

class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  bool _showOnboarding = false;
  bool _showConsent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appCubit = context.read<AppCubit>();
      final authCubit = context.read<AuthCubit>();
      await appCubit.load();
      await authCubit.bootstrap();

      // Check consent first, then onboarding
      final consented = await hasGivenConsent();
      if (!consented && mounted) {
        setState(() => _showConsent = true);
        return;
      }

      final seen = await hasSeenOnboarding();
      if (!seen && mounted) {
        setState(() => _showOnboarding = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show privacy consent for first-time users
    if (_showConsent) {
      return PrivacyConsentScreen(
        onDone: () async {
          setState(() => _showConsent = false);
          final seen = await hasSeenOnboarding();
          if (!seen && mounted) {
            setState(() => _showOnboarding = true);
          }
        },
      );
    }

    // Show onboarding for first-time users before the auth flow
    if (_showOnboarding) {
      return OnboardingScreen(
        onDone: () => setState(() => _showOnboarding = false),
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) async {
            final appCubit = context.read<AppCubit>();
            final familyCubit = context.read<MyFamilyCubit>();
            final registrationCubit = context.read<RegistrationCubit>();
            if (state.status == AuthStatus.authenticated) {
              if (state.isFacilityStaff || state.isAdmin) {
                familyCubit.clear();
                return;
              }
              await appCubit.sync();
              await familyCubit.load();
              return;
            }
            if (state.status == AuthStatus.guest) {
              registrationCubit.reset();
              return;
            }
            if (state.status == AuthStatus.unauthenticated) {
              familyCubit.clear();
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState.status == AuthStatus.checking) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1500.ms, color: AppTheme.accent.withValues(alpha: 0.3)),
                    const SizedBox(height: 24),
                    Text(
                      'Maya City CBHI',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading your health coverage...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          if (authState.status == AuthStatus.guest) {
            return const RegistrationFlow();
          }

          if (authState.status == AuthStatus.authenticated) {
            // Admin and facility staff should use the dedicated desktop apps
            if (authState.isFacilityStaff || authState.isAdmin) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.desktop_windows_outlined, size: 56, color: AppTheme.warning),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          authState.isAdmin ? 'Admin Portal' : 'Facility Staff Portal',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          authState.isAdmin
                              ? 'CBHI Officers and Admins use the dedicated desktop application.\n\nInstall: cbhi_admin_desktop'
                              : 'Health Facility Staff use the dedicated desktop application.\n\nInstall: cbhi_facility_desktop',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.read<AuthCubit>().logout(),
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const _HomeShell();
          }

          return WelcomeScreen(authCubit: context.read<AuthCubit>());
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Home Shell
// ═══════════════════════════════════════════════════════════════════════════

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);

    final repository = context.read<AppCubit>().repository;

    final pages = [
      const _DashboardPage(),
      const MyFamilyScreen(),
      const _CardPage(),
      const _ClaimsPage(),
      FacilityFinderScreen(repository: repository),
      const _ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(strings.t('appTitle')),
          ],
        ),
        actions: [
          BlocBuilder<AppCubit, AppState>(
            builder: (context, state) {
              final snapshot = state.snapshot;
              final isPendingSync = snapshot?.isPendingSync ?? false;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Offline indicator
                  if (isPendingSync)
                    Semantics(
                      label: 'Offline — changes pending sync',
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_outlined, color: AppTheme.warning, size: 14),
                            SizedBox(width: 4),
                            Text('Offline', style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),

                  // Sync button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      tooltip: strings.t('syncNow'),
                      onPressed: state.isSyncing
                          ? null
                          : () async {
                              final appCubit = context.read<AppCubit>();
                              final authCubit = context.read<AuthCubit>();
                              final familyCubit = context.read<MyFamilyCubit>();
                              await appCubit.sync();
                              await authCubit.refreshSession();
                              await familyCubit.load();
                            },
                      icon: state.isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.family_restroom_outlined),
              selectedIcon: Icon(Icons.family_restroom),
              label: 'Family',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge_outlined),
              selectedIcon: Icon(Icons.badge),
              label: 'Card',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Claims',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_hospital_outlined),
              selectedIcon: Icon(Icons.local_hospital),
              label: 'Facilities',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Dashboard
// ═══════════════════════════════════════════════════════════════════════════

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    final authState = context.watch<AuthCubit>().state;
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        // Show skeleton while loading
        if (state.isLoading) {
          return const DashboardSkeleton();
        }

        final snapshot = state.snapshot ?? CbhiSnapshot.empty();
        final currentMember = snapshot.currentMember;
        final eligibility = snapshot.eligibility ?? const <String, dynamic>{};
        final canRenew = !authState.isFamilyMember;

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            final appCubit = context.read<AppCubit>();
            final authCubit = context.read<AuthCubit>();
            final familyCubit = context.read<MyFamilyCubit>();
            await appCubit.sync();
            await authCubit.refreshSession();
            await familyCubit.load();
          },
          child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          children: [
            // Hero card
            AnimatedHeroCard(
              icon: authState.isFamilyMember
                  ? Icons.person
                  : Icons.home_work_outlined,
              title: authState.isFamilyMember
                  ? 'Beneficiary Profile'
                  : strings.t('household'),
              subtitle: snapshot.householdCode.isEmpty
                  ? 'No household synced yet'
                  : '${snapshot.viewerName} • ${snapshot.householdCode}',
              value: snapshot.householdCode.isEmpty
                  ? 'Guest Session'
                  : snapshot.coverageStatus,
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            // Metrics row
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: strings.t('coverage'),
                    value: snapshot.coverageStatus,
                    icon: Icons.verified_outlined,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: authState.isFamilyMember ? 'Eligibility' : 'Members',
                    value: authState.isFamilyMember
                        ? (eligibility['approved'] == true
                            ? 'Eligible'
                            : 'Pending')
                        : snapshot.familyMembers.length.toString(),
                    icon: authState.isFamilyMember
                        ? Icons.verified_user_outlined
                        : Icons.family_restroom_outlined,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms)
                .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: strings.t('premium'),
                    value: '${snapshot.premiumAmount.toStringAsFixed(0)} ETB',
                    icon: Icons.payments_outlined,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: strings.t('paid'),
                    value: '${snapshot.paidAmount.toStringAsFixed(0)} ETB',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 250.ms)
                .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 250.ms),

            const SizedBox(height: 20),

            // Sync / eligibility card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (snapshot.isPendingSync
                                  ? AppTheme.warning
                                  : AppTheme.success)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          snapshot.isPendingSync
                              ? Icons.cloud_upload_outlined
                              : Icons.cloud_done_outlined,
                          color: snapshot.isPendingSync
                              ? AppTheme.warning
                              : AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.isPendingSync
                                  ? 'Offline queue active'
                                  : 'Household synced',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              snapshot.isPendingSync
                                  ? 'Changes are waiting to sync.'
                                  : 'Data and digital card are up to date.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    authState.isFamilyMember
                        ? 'Personal Eligibility'
                        : 'Renewal Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    eligibility['reason']?.toString() ??
                        'Coverage eligibility details will appear after sync.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (currentMember != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(
                          label: currentMember.relationshipToHouseholdHead ??
                              'MEMBER',
                        ),
                        StatusBadge(
                          label: eligibility['canLoginIndependently'] == true
                              ? 'Independent access'
                              : 'Household-managed',
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                  if (canRenew) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: state.isSyncing
                          ? null
                          : () => _showRenewCoverageSheet(
                              context,
                              snapshot,
                              context.read<AppCubit>().repository,
                            ),
                      icon: const Icon(Icons.autorenew),
                      label: Text(
                        snapshot.premiumAmount > 0
                            ? 'Renew Coverage'
                            : 'Confirm Renewal',
                      ),
                    ),
                  ],
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 350.ms)
                .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 350.ms),

            const SizedBox(height: 24),

            // Payment History
            const SectionHeader(title: 'Payment History'),
            const SizedBox(height: 4),
            ...snapshot.payments.take(3).toList().asMap().entries.map(
              (entry) {
                final payment = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: AppTheme.gold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${payment['amount']?.toString() ?? '0'} ETB',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${payment['method']?.toString().replaceAll('_', ' ') ?? 'Payment'} • ${_formatDateLabel(payment['paidAt'] ?? payment['createdAt'])}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label:
                              payment['status']?.toString() ?? 'UNKNOWN',
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: 350.ms,
                        delay: (450 + entry.key * 80).ms,
                      )
                      .slideX(
                        begin: 0.05,
                        end: 0,
                        duration: 350.ms,
                        delay: (450 + entry.key * 80).ms,
                      ),
                );
              },
            ),
            if (snapshot.payments.isEmpty)
              EmptyState(
                icon: Icons.payments_outlined,
                title: 'No payments recorded',
                subtitle:
                    'Renewal and contribution transactions will appear here.',
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 450.ms),

            const SizedBox(height: 24),

            // Notifications
            const SectionHeader(title: 'Recent Notifications'),
            const SizedBox(height: 4),
            ...snapshot.notifications.take(3).toList().asMap().entries.map(
              (entry) {
                final notification = entry.value;
                final isRead = notification['isRead'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: notification['id'] == null
                        ? null
                        : () => context.read<AppCubit>().markNotificationRead(
                            notification['id'].toString()),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isRead
                                    ? AppTheme.textSecondary
                                    : AppTheme.accent)
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.notifications_active_outlined,
                            color:
                                isRead ? AppTheme.textSecondary : AppTheme.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['title']?.toString() ??
                                    'Notification',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notification['message']?.toString() ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: 350.ms,
                        delay: (550 + entry.key * 80).ms,
                      )
                      .slideX(
                        begin: 0.05,
                        end: 0,
                        duration: 350.ms,
                        delay: (550 + entry.key * 80).ms,
                      ),
                );
              },
            ),
            if (snapshot.notifications.isEmpty)
              EmptyState(
                icon: Icons.notifications_outlined,
                title: 'No notifications yet',
                subtitle:
                    'Coverage alerts and benefit updates will appear here.',
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 550.ms),

            // View all notifications link
            if (snapshot.notifications.length >= 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  onPressed: () => _showAllNotificationsSheet(context, snapshot),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View all notifications'),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
        );
      },
    );
  }

  void _showAllNotificationsSheet(BuildContext context, CbhiSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'All Notifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.notifications.length,
                itemBuilder: (_, index) {
                  final n = snapshot.notifications[index];
                  return ListTile(
                    leading: Icon(
                      n['isRead'] == true
                          ? Icons.mark_email_read_outlined
                          : Icons.notifications_active_outlined,
                      color: n['isRead'] == true
                          ? AppTheme.textSecondary
                          : AppTheme.accent,
                    ),
                    title: Text(n['title']?.toString() ?? ''),
                    subtitle: Text(n['message']?.toString() ?? ''),
                    onTap: n['id'] == null
                        ? null
                        : () => context
                            .read<AppCubit>()
                            .markNotificationRead(n['id'].toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Card Page (Digital CBHI Card)
// ═══════════════════════════════════════════════════════════════════════════

class _CardPage extends StatelessWidget {
  const _CardPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final snapshot = state.snapshot ?? CbhiSnapshot.empty();
        final cards = snapshot.digitalCards.isEmpty
            ? [
                {
                  'memberName': snapshot.viewerName,
                  'membershipId': snapshot.viewerMembershipId,
                  'coverageStatus': snapshot.coverageStatus,
                  'token': snapshot.cardToken,
                },
              ]
            : snapshot.digitalCards;

        return ListView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          children: [
            const SectionHeader(title: 'Digital CBHI Cards'),
            const SizedBox(height: 8),
            ...cards.toList().asMap().entries.map(
              (entry) {
                final card = entry.value;
                final hasToken =
                    (card['token']?.toString() ?? '').isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.health_and_safety,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Maya City CBHI',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const Spacer(),
                              StatusBadge(
                                label: card['coverageStatus']?.toString() ??
                                    snapshot.coverageStatus,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            card['memberName']?.toString() ??
                                snapshot.viewerName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _CardInfoChip(
                                label: 'Household',
                                value: snapshot.householdCode.isEmpty
                                    ? '—'
                                    : snapshot.householdCode,
                              ),
                              const SizedBox(width: 16),
                              if ((card['membershipId']?.toString() ?? '')
                                  .isNotEmpty)
                                _CardInfoChip(
                                  label: 'Member ID',
                                  value: card['membershipId'].toString(),
                                ),
                            ],
                          ),
                          if (snapshot.coverageNumber.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _CardInfoChip(
                              label: 'Coverage',
                              value: snapshot.coverageNumber,
                            ),
                          ],
                          const SizedBox(height: 20),
                          // QR Code
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusM),
                              ),
                              child: hasToken
                                  ? QrImageView(
                                      data: card['token']!.toString(),
                                      size: 200,
                                    )
                                  : SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2,
                                            size: 64,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No digital card cached yet',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              hasToken
                                  ? 'Encrypted QR token • Tap card to verify'
                                  : 'Complete sync to generate QR token',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Share / Save card info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  final info = [
                                    'Maya City CBHI Membership Card',
                                    'Name: ${card['memberName'] ?? snapshot.viewerName}',
                                    'Household: ${snapshot.householdCode}',
                                    'Member ID: ${card['membershipId'] ?? snapshot.viewerMembershipId}',
                                    'Coverage: ${card['coverageStatus'] ?? snapshot.coverageStatus}',
                                    'Coverage #: ${snapshot.coverageNumber}',
                                  ].join('\n');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Card details copied — share with facility staff if needed.'),
                                      action: SnackBarAction(label: 'OK', onPressed: () {}),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                icon: const Icon(Icons.share_outlined, size: 16),
                                label: const Text('Share Card Info'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: (entry.key * 100).ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        delay: (entry.key * 100).ms,
                        curve: Curves.easeOutCubic,
                      ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CardInfoChip extends StatelessWidget {
  const _CardInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Claims Page
// ═══════════════════════════════════════════════════════════════════════════

class _ClaimsPage extends StatelessWidget {
  const _ClaimsPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final snapshot = state.snapshot ?? CbhiSnapshot.empty();
        return MemberClaimsScreen(snapshot: snapshot);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Profile Page
// ═══════════════════════════════════════════════════════════════════════════

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final session = authState.session;
    final snapshot =
        context.watch<AppCubit>().state.snapshot ?? CbhiSnapshot.empty();
    final member = snapshot.currentMember;
    final eligibility = snapshot.eligibility ?? const <String, dynamic>{};

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      children: [
        // Profile header
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.user.displayName ?? 'Member',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    if ((session?.user.phoneNumber ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        session!.user.phoneNumber!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                    if ((session?.user.membershipId ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${session!.user.membershipId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

        const SizedBox(height: 20),

        // Profile details card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _ProfileRow(
                icon: Icons.home_work_outlined,
                label: 'Household',
                value: snapshot.householdCode.isEmpty
                    ? 'Not synced'
                    : snapshot.householdCode,
              ),
              _ProfileRow(
                icon: Icons.verified_outlined,
                label: 'Coverage',
                value: snapshot.coverageStatus,
              ),
              if (member?.dateOfBirth != null)
                _ProfileRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of birth',
                  value: _formatDateLabel(member?.dateOfBirth),
                ),
              if ((member?.relationshipToHouseholdHead ?? '').isNotEmpty)
                _ProfileRow(
                  icon: Icons.people_outline,
                  label: 'Relationship',
                  value: member!.relationshipToHouseholdHead!,
                ),
              _ProfileRow(
                icon: Icons.verified_user_outlined,
                label: 'Eligibility',
                value: eligibility['approved'] == true
                    ? 'Eligible'
                    : 'Pending',
              ),
              if ((eligibility['reason']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    eligibility['reason'].toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              StatusBadge(
                label: eligibility['canLoginIndependently'] == true
                    ? 'Independent access'
                    : 'Household-managed',
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 150.ms),

        const SizedBox(height: 20),

        // Language selection
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.translate,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Language',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: CbhiLocalizations.supportedLocales.map((locale) {
                  final isSelected =
                      context.watch<AppCubit>().state.locale.languageCode ==
                          locale.languageCode;
                  final label = switch (locale.languageCode) {
                    'en' => 'English',
                    'am' => 'አማርኛ',
                    'om' => 'Afaan Oromoo',
                    _ => locale.languageCode.toUpperCase(),
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) =>
                        context.read<AppCubit>().setLocale(locale),
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 250.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 250.ms),

        const SizedBox(height: 16),

        // Dark mode toggle
        GlassCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dark_mode_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark Mode',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Easier on the eyes in low light',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: context.watch<AppCubit>().state.isDarkMode,
                onChanged: (_) => context.read<AppCubit>().toggleDarkMode(),
                activeThumbColor: AppTheme.primary,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 300.ms),

        const SizedBox(height: 16),

        // Biometric login toggle
        const _BiometricToggle()
            .animate()
            .fadeIn(duration: 400.ms, delay: 320.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 320.ms),

        const SizedBox(height: 16),

        // App info card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _ProfileRow(
                icon: Icons.verified_outlined,
                label: 'Platform',
                value: 'Maya City CBHI v1.0',
              ),
              const _ProfileRow(
                icon: Icons.account_balance_outlined,
                label: 'Authority',
                value: 'Ethiopian Health Insurance Agency (EHIA)',
              ),
              const _ProfileRow(
                icon: Icons.local_hospital_outlined,
                label: 'Ministry',
                value: 'Federal Ministry of Health (FMOH)',
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 350.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 350.ms),

        const SizedBox(height: 24),

        // Help & FAQ
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          ),
          icon: const Icon(Icons.help_outline),
          label: const Text('Help & FAQ'),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 420.ms),

        const SizedBox(height: 12),

        // Sign out
        FilledButton.icon(
          onPressed: () async {
            await context.read<AuthCubit>().logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.error.withValues(alpha: 0.9),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 400.ms),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Biometric Toggle Widget
// ═══════════════════════════════════════════════════════════════════════════

class _BiometricToggle extends StatefulWidget {
  const _BiometricToggle();

  @override
  State<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends State<_BiometricToggle> {
  bool _available = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) setState(() { _available = available; _enabled = enabled; });
  }

  Future<void> _toggle(bool value, BuildContext ctx) async {
    if (value) {
      final session = ctx.read<AuthCubit>().state.session;
      if (session == null) return;
      final ok = await BiometricService.enableBiometric(session.accessToken);
      if (mounted) setState(() => _enabled = ok);
    } else {
      await BiometricService.disableBiometric();
      if (mounted) setState(() => _enabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fingerprint, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biometric Login', style: Theme.of(context).textTheme.titleMedium),
                Text('Use fingerprint or face ID to sign in', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            onChanged: (v) => _toggle(v, context),
            activeThumbColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Legacy _HeroCard and _MetricCard (kept for backward compatibility)
// ═══════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AnimatedHeroCard(title: title, subtitle: subtitle, value: value);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return MetricCard(label: label, value: value, icon: icon);
  }
}
