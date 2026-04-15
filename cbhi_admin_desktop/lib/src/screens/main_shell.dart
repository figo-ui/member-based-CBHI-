import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/claims_cubit.dart';
import '../blocs/indigent_cubit.dart';
import '../blocs/overview_cubit.dart';
import '../data/admin_repository.dart';
import '../i18n/app_localizations.dart';
import '../theme/admin_theme.dart';
import 'audit_log_screen.dart';
import 'benefit_packages_screen.dart';
import 'facility_performance_screen.dart';
import 'financial_screen.dart';
import 'grievances_admin_screen.dart';
import 'overview_screen.dart';
import 'claims_screen.dart';
import 'facilities_screen.dart';
import 'indigent_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'user_management_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.repository,
    required this.onLogout,
    required this.locale,
    required this.onLocaleChanged,
  });

  final AdminRepository repository;
  final VoidCallback onLogout;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _isOnline = true;
  Timer? _pingTimer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Ping every 30 seconds
    _pingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final online = await widget.repository.ping();
    if (mounted && online != _isOnline) {
      setState(() => _isOnline = online);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final navItems = [
      _NavItem(icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard, label: strings.t('navOverview')),
      _NavItem(icon: Icons.rule_folder_outlined, selectedIcon: Icons.rule_folder, label: strings.t('navClaims')),
      _NavItem(icon: Icons.volunteer_activism_outlined, selectedIcon: Icons.volunteer_activism, label: strings.t('navIndigent')),
      _NavItem(icon: Icons.local_hospital_outlined, selectedIcon: Icons.local_hospital, label: strings.t('navFacilities')),
      _NavItem(icon: Icons.account_balance_outlined, selectedIcon: Icons.account_balance, label: strings.t('navFinancial')),
      _NavItem(icon: Icons.analytics_outlined, selectedIcon: Icons.analytics, label: strings.t('navFacilityPerformance')),
      _NavItem(icon: Icons.people_outlined, selectedIcon: Icons.people, label: strings.t('navUsers')),
      _NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: strings.t('benefitPackages')),
      _NavItem(icon: Icons.gavel_outlined, selectedIcon: Icons.gavel, label: strings.t('memberGrievances')),
      _NavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: strings.t('navReports')),
      _NavItem(icon: Icons.history_outlined, selectedIcon: Icons.history, label: strings.t('navAuditLog')),
      _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: strings.t('navSettings')),
    ];
    final pages = [
      BlocProvider(create: (_) => OverviewCubit(widget.repository)..load(), child: OverviewScreen(repository: widget.repository)),
      BlocProvider(create: (_) => ClaimsCubit(widget.repository)..load(), child: ClaimsScreen(repository: widget.repository)),
      BlocProvider(create: (_) => IndigentCubit(widget.repository)..load(),
        child: IndigentScreen(repository: widget.repository),
      ),
      FacilitiesScreen(repository: widget.repository),
      FinancialScreen(repository: widget.repository),
      FacilityPerformanceScreen(repository: widget.repository),
      UserManagementScreen(repository: widget.repository),
      BenefitPackagesScreen(repository: widget.repository),
      GrievancesAdminScreen(repository: widget.repository),
      ReportsScreen(repository: widget.repository),
      AuditLogScreen(repository: widget.repository),
      SettingsScreen(repository: widget.repository),
    ];

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          Container(
            width: 240,
            color: AdminTheme.sidebarBg,
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AdminTheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.t('appTitle'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Maya City',
                              style: TextStyle(
                                color: AdminTheme.sidebarText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0xFF1E3530), height: 1),
                const SizedBox(height: 8),

                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final isSelected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _selectedIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AdminTheme.sidebarSelected.withValues(
                                        alpha: 0.15,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(
                                        color: AdminTheme.sidebarSelected
                                            .withValues(alpha: 0.3),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    color: isSelected
                                        ? AdminTheme.sidebarSelected
                                        : AdminTheme.sidebarText,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AdminTheme.sidebarSelected
                                          : AdminTheme.sidebarText,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom — logout
                const Divider(color: Color(0xFF1E3530), height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await widget.repository.logout();
                        widget.onLogout();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout,
                              color: AdminTheme.sidebarText,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              strings.t('signOut'),
                              style: const TextStyle(
                                color: AdminTheme.sidebarText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        navItems[_selectedIndex].label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<Locale>(
                        tooltip: strings.t('language'),
                        onSelected: widget.onLocaleChanged,
                        itemBuilder: (_) => AppLocalizations.supportedLocales
                            .map(
                              (locale) => PopupMenuItem<Locale>(
                                value: locale,
                                child: Text(
                                  strings.languageLabel(locale.languageCode),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AdminTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.translate,
                                size: 16,
                                color: AdminTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                strings.languageLabel(
                                  widget.locale.languageCode,
                                ),
                                style: const TextStyle(
                                  color: AdminTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // FIX: Add Semantics for accessibility
                      Semantics(
                        label: _isOnline
                            ? 'Connected to server'
                            : 'Offline — no server connection',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (_isOnline
                                    ? AdminTheme.success
                                    : AdminTheme.error)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                color: _isOnline
                                    ? AdminTheme.success
                                    : AdminTheme.error,
                                size: 8,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isOnline
                                    ? strings.t('connected')
                                    : strings.t('offline'),
                                style: TextStyle(
                                  color: _isOnline
                                      ? AdminTheme.success
                                      : AdminTheme.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Page content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: pages[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
