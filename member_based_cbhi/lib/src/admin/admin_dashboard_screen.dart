import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../auth/auth_cubit.dart';
import '../cbhi_data.dart';
import '../shared/animated_widgets.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.repository,
    required this.authCubit,
  });

  final CbhiRepository repository;
  final AuthCubit authCubit;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminOverviewPage(repository: widget.repository),
      _AdminClaimsReviewPage(repository: widget.repository),
      _AdminSettingsPage(repository: widget.repository),
    ];
    final titles = ['Overview', 'Claims Review', 'System Settings'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard • ${titles[_index]}'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.authCubit.logout,
            icon: const Icon(Icons.logout),
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
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.rule_folder_outlined),
              selectedIcon: Icon(Icons.rule_folder),
              label: 'Review',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOverviewPage extends StatefulWidget {
  const _AdminOverviewPage({required this.repository});

  final CbhiRepository repository;

  @override
  State<_AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<_AdminOverviewPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _report;
  List<Map<String, dynamic>> _pendingApplications = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final report = await widget.repository.fetchAdminSummaryReport();
      final pending = await widget.repository.fetchPendingIndigentApplications();
      setState(() {
        _report = report;
        _pendingApplications = pending;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report ?? const <String, dynamic>{};
    final claims = (report['claims'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final payments = (report['payments'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        key: const ValueKey('admin-overview'),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          const AnimatedHeroCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'CBHI Control Center',
            subtitle:
                'Review key enrollment, claims, and payment indicators. Automatic indigent approval processes are active.',
            value: 'System Overview',
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _MessageCard(
              title: 'Could not load dashboard',
              message: _error!,
              icon: Icons.error_outline,
              iconColor: AppTheme.error,
              color: AppTheme.error.withValues(alpha: 0.1),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Households',
                    value: '${report['households'] ?? 0}',
                    icon: Icons.house_outlined,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Facilities',
                    value: '${report['accreditedFacilities'] ?? 0}',
                    icon: Icons.local_hospital_outlined,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Claims',
                    value: '${claims['submitted'] ?? 0}',
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Payments',
                    value: '${payments['totalTransactions'] ?? 0}',
                    icon: Icons.payments_outlined,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Indigent Automation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Pending Manual Review',
                    value: '${report['pendingIndigentApplications'] ?? _pendingApplications.length}',
                    valueBadge: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pendingApplications.isEmpty
                        ? 'No indigent applications are waiting for manual intervention.'
                        : 'Some applications remain in pending status and may need follow-up.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_outlined, color: AppTheme.gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Financial Summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Claimed Amount',
                    value: '${claims['totalClaimedAmount'] ?? 0} ETB',
                  ),
                  _DetailRow(
                    label: 'Approved Amount',
                    value: '${claims['totalApprovedAmount'] ?? 0} ETB',
                  ),
                  _DetailRow(
                    label: 'Collected Amount',
                    value: '${payments['totalCollectedAmount'] ?? 0} ETB',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.05, end: 0),
          ],
        ],
      ),
    );
  }
}

class _AdminClaimsReviewPage extends StatefulWidget {
  const _AdminClaimsReviewPage({required this.repository});

  final CbhiRepository repository;

  @override
  State<_AdminClaimsReviewPage> createState() => _AdminClaimsReviewPageState();
}

class _AdminClaimsReviewPageState extends State<_AdminClaimsReviewPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _claims = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final claims = await widget.repository.fetchAdminClaims();
      setState(() {
        _claims = claims;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reviewClaim(Map<String, dynamic> claim, String status) async {
    final amountController = TextEditingController(
      text: claim['claimedAmount']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: claim['decisionNote']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Set claim to $status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Approved Amount (ETB)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Decision Note',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.repository.reviewAdminClaim(
                  claimId: claim['id'].toString(),
                  status: status,
                  approvedAmount: double.tryParse(amountController.text.trim()),
                  decisionNote: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                await _load();
              },
              child: const Text('Save Decision'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        key: const ValueKey('admin-claims-review'),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          const AnimatedHeroCard(
            icon: Icons.rule_folder_outlined,
            title: 'Claims Review',
            subtitle:
                'Process facility service claims, adjust approved amounts, and add decision notes for the beneficiaries.',
            value: 'Pending Inbox',
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _MessageCard(
              title: 'Could not load claims',
              message: _error!,
              icon: Icons.error_outline,
              iconColor: AppTheme.error,
              color: AppTheme.error.withValues(alpha: 0.1),
            )
          else if (_claims.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Claims Pending',
              subtitle: 'All submitted claims have been processed.',
            ).animate().fadeIn(duration: 400.ms)
          else
            ..._claims.asMap().entries.map(
              (entry) {
                final claim = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                claim['claimNumber']?.toString() ?? 'Claim',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            StatusBadge(label: claim['status']?.toString() ?? 'UNKNOWN'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Beneficiary',
                          value: claim['beneficiaryName']?.toString() ?? 'N/A',
                        ),
                        _DetailRow(
                          label: 'Membership ID',
                          value: claim['membershipId']?.toString() ?? 'N/A',
                        ),
                        _DetailRow(
                          label: 'Facility',
                          value: claim['facilityName']?.toString() ?? 'N/A',
                        ),
                        _DetailRow(
                          label: 'Claimed',
                          value: '${claim['claimedAmount']?.toString() ?? '0'} ETB',
                        ),
                        if ((claim['decisionNote']?.toString() ?? '').isNotEmpty)
                          _DetailRow(
                            label: 'Note',
                            value: claim['decisionNote'].toString(),
                          ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _reviewClaim(claim, 'REJECTED'),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => _reviewClaim(claim, 'UNDER_REVIEW'),
                              icon: const Icon(Icons.hourglass_empty),
                              label: const Text('Review'),
                            ),
                            FilledButton.icon(
                              onPressed: () => _reviewClaim(claim, 'APPROVED'),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: (100 + entry.key * 80).ms).slideY(begin: 0.05, end: 0),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AdminSettingsPage extends StatefulWidget {
  const _AdminSettingsPage({required this.repository});

  final CbhiRepository repository;

  @override
  State<_AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<_AdminSettingsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _settings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final settings = await widget.repository.fetchAdminConfiguration();
      setState(() {
        _settings = settings;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editSetting(Map<String, dynamic> setting) async {
    final labelController = TextEditingController(
      text: setting['label']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: setting['description']?.toString() ?? '',
    );
    final valueController = TextEditingController(
      text: const JsonEncoder.withIndent(
        '  ',
      ).convert(setting['value'] ?? const <String, dynamic>{}),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.tune, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  setting['key']?.toString() ?? 'Setting',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'Label'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueController,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Value (JSON)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final decoded = jsonDecode(valueController.text.trim());
                  if (decoded is! Map<String, dynamic>) {
                    throw const FormatException(
                      'Configuration value must be a JSON object.',
                    );
                  }
                  await widget.repository.updateAdminConfiguration(
                    key: setting['key'].toString(),
                    label: labelController.text.trim(),
                    description: descriptionController.text.trim(),
                    value: decoded,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  await _load();
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(error.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        key: const ValueKey('admin-settings'),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          const AnimatedHeroCard(
            icon: Icons.settings_outlined,
            title: 'System Settings',
            subtitle:
                'Manage critical CBHI configuration for enrollment windows, premium amounts, and automation policies.',
            value: 'Configuration',
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _MessageCard(
              title: 'Could not load settings',
              message: _error!,
              icon: Icons.error_outline,
              iconColor: AppTheme.error,
              color: AppTheme.error.withValues(alpha: 0.1),
            )
          else
            ..._settings.asMap().entries.map(
              (entry) {
                final setting = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    setting['label']?.toString() ?? 'Setting',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    setting['description']?.toString() ?? '',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _editSetting(setting),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit Setting',
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
                                foregroundColor: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            const JsonEncoder.withIndent('  ').convert(setting['value'] ?? const <String, dynamic>{}),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: (100 + entry.key * 80).ms).slideY(begin: 0.05, end: 0),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textDark.withValues(alpha: 0.8),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueBadge = false,
  });

  final String label;
  final String value;
  final bool valueBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: valueBadge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(label: value),
                  )
                : Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                  ),
          ),
        ],
      ),
    );
  }
}
