import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../auth/auth_cubit.dart';
import '../cbhi_data.dart';
import '../i18n/app_localizations.dart';
import '../shared/animated_widgets.dart';
import '../shared/local_attachment_store.dart';
import '../theme/app_theme.dart';

class FacilityStaffScreen extends StatefulWidget {
  const FacilityStaffScreen({
    super.key,
    required this.repository,
    required this.authCubit,
  });

  final CbhiRepository repository;
  final AuthCubit authCubit;

  @override
  State<FacilityStaffScreen> createState() => _FacilityStaffScreenState();
}

class _FacilityStaffScreenState extends State<FacilityStaffScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final pages = [
      _FacilityVerifyPage(repository: widget.repository),
      _FacilitySubmitClaimPage(repository: widget.repository),
      _FacilityClaimTrackerPage(repository: widget.repository),
    ];
    final titles = [
      strings.t('verifyEligibility'),
      strings.t('submitClaim'),
      strings.t('claimDecisions'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            tooltip: strings.t('signOut'),
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
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
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
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user),
              label: strings.t('eligibility'),
            ),
            NavigationDestination(
              icon: Icon(Icons.note_add_outlined),
              selectedIcon: Icon(Icons.note_add),
              label: strings.t('claims'),
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: strings.t('claimDecisions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityVerifyPage extends StatefulWidget {
  const _FacilityVerifyPage({required this.repository});

  final CbhiRepository repository;

  @override
  State<_FacilityVerifyPage> createState() => _FacilityVerifyPageState();
}

class _FacilityVerifyPageState extends State<_FacilityVerifyPage> {
  final _membershipIdController = TextEditingController();
  final _phoneController = TextEditingController(text: '+2519');
  final _householdCodeController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _membershipIdController.dispose();
    _phoneController.dispose();
    _householdCodeController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final strings = AppLocalizations.of(context);
    final membershipId = _membershipIdController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final householdCode = _householdCodeController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (membershipId.isEmpty &&
        (phoneNumber.isEmpty || phoneNumber == '+2519') &&
        (householdCode.isEmpty || fullName.isEmpty)) {
      setState(() {
        _error = strings.t('provideLookupOrHousehold');
        _result = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.repository.verifyFacilityEligibility(
        membershipId: membershipId.isEmpty ? null : membershipId,
        phoneNumber: phoneNumber.isEmpty || phoneNumber == '+2519'
            ? null
            : phoneNumber,
        householdCode: householdCode.isEmpty ? null : householdCode,
        fullName: fullName.isEmpty ? null : fullName,
      );
      setState(() {
        _result = response;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _result = null;
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
    final strings = AppLocalizations.of(context);
    final result = _result;
    final beneficiary =
        (result?['beneficiary'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final eligibility =
        (result?['eligibility'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final coverage =
        (result?['coverage'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return ListView(
      key: const ValueKey('facility-verify'),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      children: [
        AnimatedHeroCard(
          icon: Icons.search_outlined,
          title: strings.t('verifyEligibility'),
          subtitle: strings.t('verifyEligibilitySubtitle'),
          value: strings.t('benefitLookup'),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 24),

        GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _membershipIdController,
                    decoration: InputDecoration(
                      labelText: strings.t('membershipId'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: strings.t('beneficiaryPhoneNumber'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          strings.t('orLabel'),
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _householdCodeController,
                          decoration: InputDecoration(
                            labelText: strings.t('householdCode'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: strings.t('fullName'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _verify,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(strings.t('verifyEligibility')),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.05, end: 0),

        if (_error != null) ...[
          const SizedBox(height: 20),
          _MessageCard(
            color: AppTheme.error.withValues(alpha: 0.1),
            icon: Icons.error_outline,
            iconColor: AppTheme.error,
            title: strings.t('verificationFailed'),
            message: _error!,
          ).animate().fadeIn(duration: 300.ms),
        ],

        if (result != null) ...[
          const SizedBox(height: 24),
          SectionHeader(title: strings.t('verificationResult')),
          const SizedBox(height: 8),

          _MessageCard(
                color: eligibility['isEligible'] == true
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.warning.withValues(alpha: 0.1),
                icon: eligibility['isEligible'] == true
                    ? Icons.verified
                    : Icons.warning_amber_rounded,
                iconColor: eligibility['isEligible'] == true
                    ? AppTheme.success
                    : AppTheme.warning,
                title: eligibility['isEligible'] == true
                    ? strings.t('eligibleForService')
                    : strings.t('notEligibleForService'),
                message:
                    eligibility['reason']?.toString() ??
                    strings.t('noEligibilityNoteProvided'),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 16),

          GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                beneficiary['fullName']?.toString() ??
                                    strings.t('beneficiaryName'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${strings.t('idLabel')}: ${beneficiary['membershipId']?.toString() ?? strings.t('notAvailable')}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: strings.t('householdCode'),
                      value:
                          beneficiary['householdCode']?.toString() ??
                          strings.t('notAvailable'),
                    ),
                    _DetailRow(
                      label: strings.t('relationship'),
                      value:
                          beneficiary['relationshipToHouseholdHead']
                              ?.toString() ??
                          strings.t('notAvailable'),
                    ),
                    _DetailRow(
                      label: strings.t('coverageStatus'),
                      value:
                          coverage['status']?.toString() ??
                          strings.t('notAvailable'),
                      valueBadge: true,
                    ),
                    _DetailRow(
                      label: strings.t('validUntil'),
                      value: _formatStaffDate(coverage['endDate']),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.05, end: 0),
        ],
      ],
    );
  }
}

class _FacilitySubmitClaimPage extends StatefulWidget {
  const _FacilitySubmitClaimPage({required this.repository});

  final CbhiRepository repository;

  @override
  State<_FacilitySubmitClaimPage> createState() =>
      _FacilitySubmitClaimPageState();
}

class _FacilitySubmitClaimPageState extends State<_FacilitySubmitClaimPage> {
  final _membershipIdController = TextEditingController();
  final _phoneController = TextEditingController(text: '+2519');
  final _householdCodeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _serviceDate = DateTime.now();
  String? _documentPath;
  bool _isSubmitting = false;
  String? _message;
  bool _isSuccessMessage = false;

  @override
  void dispose() {
    _membershipIdController.dispose();
    _phoneController.dispose();
    _householdCodeController.dispose();
    _fullNameController.dispose();
    _serviceNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || !mounted) return;

    if (kIsWeb) {
      // On web, path is null — use the file name for display only.
      final fileName = result.files.single.name;
      setState(() {
        _documentPath = fileName;
      });
      return;
    }

    final selectedPath = result.files.single.path;
    if (selectedPath == null || !mounted) return;

    final persistedPath = await LocalAttachmentStore.persist(
      selectedPath,
      category: 'facility_claim',
    );
    setState(() {
      _documentPath = persistedPath;
    });
  }

  Future<void> _submitClaim() async {
    final strings = AppLocalizations.of(context);
    final membershipId = _membershipIdController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final householdCode = _householdCodeController.text.trim();
    final fullName = _fullNameController.text.trim();
    final serviceName = _serviceNameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim());
    final unitPrice = double.tryParse(_unitPriceController.text.trim());

    if (membershipId.isEmpty &&
        (phoneNumber.isEmpty || phoneNumber == '+2519') &&
        (householdCode.isEmpty || fullName.isEmpty)) {
      setState(() {
        _message = strings.t('provideLookupOrHousehold');
        _isSuccessMessage = false;
      });
      return;
    }

    if (serviceName.isEmpty || quantity == null || unitPrice == null) {
      setState(() {
        _message = strings.t('serviceFieldsRequired');
        _isSuccessMessage = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final response = await widget.repository.submitFacilityClaim(
        membershipId: membershipId.isEmpty ? null : membershipId,
        phoneNumber: phoneNumber.isEmpty || phoneNumber == '+2519'
            ? null
            : phoneNumber,
        householdCode: householdCode.isEmpty ? null : householdCode,
        fullName: fullName.isEmpty ? null : fullName,
        serviceDate: _serviceDate,
        items: [
          {
            'serviceName': serviceName,
            'quantity': quantity,
            'unitPrice': unitPrice,
            'notes': _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          },
        ],
        supportingDocumentPath: _documentPath,
      );
      setState(() {
        _isSuccessMessage = true;
        _message = strings.f('claimSubmittedMessage', {
          'claimNumber': response['claimNumber']?.toString() ?? '',
        });
        _serviceNameController.clear();
        _quantityController.text = '1';
        _unitPriceController.clear();
        _notesController.clear();
        _documentPath = null;
      });
    } catch (error) {
      setState(() {
        _isSuccessMessage = false;
        _message = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListView(
      key: const ValueKey('facility-submit-claim'),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      children: [
        AnimatedHeroCard(
          icon: Icons.note_add_outlined,
          title: strings.t('submitServiceClaim'),
          subtitle: strings.t('submitServiceClaimSubtitle'),
          value: strings.t('newClaim'),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 24),

        GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: strings.t('beneficiaryDetailsSection')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _membershipIdController,
                    decoration: InputDecoration(
                      labelText: strings.t('membershipId'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: strings.t('beneficiaryPhoneNumber'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _householdCodeController,
                          decoration: InputDecoration(
                            labelText: strings.t('householdCode'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: strings.t('fullName'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.05, end: 0),

        const SizedBox(height: 16),

        GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: strings.t('serviceDetails')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _serviceNameController,
                    decoration: InputDecoration(
                      labelText: strings.t('serviceName'),
                      prefixIcon: const Icon(Icons.medical_services_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.t('quantity'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _unitPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: strings.t('unitPriceEtb'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: strings.t('clinicalOrBillingNotes'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t('serviceDate'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _formatStaffDate(
                                  _serviceDate.toIso8601String(),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _serviceDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme
                                        .copyWith(primary: AppTheme.primary),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _serviceDate = picked;
                              });
                            }
                          },
                          child: Text(strings.t('change')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _documentPath == null
                          ? strings.t('attachSupportingDocument')
                          : strings.t('replaceDocument'),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                  if (_documentPath != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.attachment,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _documentPath!.split(RegExp(r'[\\\\/]')).last,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.05, end: 0),

        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submitClaim,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(strings.t('submitClaim')),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        if (_message != null) ...[
          const SizedBox(height: 20),
          _MessageCard(
            color: _isSuccessMessage
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.error.withValues(alpha: 0.1),
            icon: _isSuccessMessage
                ? Icons.check_circle_outline
                : Icons.error_outline,
            iconColor: _isSuccessMessage ? AppTheme.success : AppTheme.error,
            title: _isSuccessMessage
                ? strings.t('success')
                : strings.t('error'),
            message: _message!,
          ).animate().fadeIn(duration: 300.ms),
        ],
      ],
    );
  }
}

class _FacilityClaimTrackerPage extends StatefulWidget {
  const _FacilityClaimTrackerPage({required this.repository});

  final CbhiRepository repository;

  @override
  State<_FacilityClaimTrackerPage> createState() =>
      _FacilityClaimTrackerPageState();
}

class _FacilityClaimTrackerPageState extends State<_FacilityClaimTrackerPage> {
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
      final claims = await widget.repository.fetchFacilityClaims();
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        key: const ValueKey('facility-claim-tracker'),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          AnimatedHeroCard(
            icon: Icons.fact_check_outlined,
            title: strings.t('claimDecisions'),
            subtitle: strings.t('facilityClaimTrackerSubtitle'),
            value: strings.t('recentSubmissions'),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _MessageCard(
              color: AppTheme.error.withValues(alpha: 0.1),
              icon: Icons.error_outline,
              iconColor: AppTheme.error,
              title: strings.t('facilityClaimsLoadError'),
              message: _error!,
            )
          else if (_claims.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: strings.t('noFacilityClaimsYet'),
              subtitle: strings.t('facilityClaimsAppearAfterSync'),
            ).animate().fadeIn(duration: 400.ms)
          else
            ..._claims.asMap().entries.map((entry) {
              final claim = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:
                    GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          claim['claimNumber']?.toString() ??
                                              strings.t('claims'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if ((claim['beneficiaryName']
                                                    ?.toString() ??
                                                '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            claim['beneficiaryName'].toString(),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  StatusBadge(
                                    label:
                                        claim['status']?.toString() ??
                                        'UNKNOWN',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on_outlined,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    strings.f('claimedAmountWithEtb', {
                                      'amount':
                                          claim['claimedAmount']?.toString() ??
                                          '0',
                                    }),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.event_outlined,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatStaffDate(
                                      claim['reviewedAt'] ?? claim['createdAt'],
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              if ((claim['decisionNote']?.toString() ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusS,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.note_outlined,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          claim['decisionNote'].toString(),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: 350.ms,
                          delay: (100 + entry.key * 80).ms,
                        )
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 350.ms,
                          delay: (100 + entry.key * 80).ms,
                        ),
              );
            }),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
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

String _formatStaffDate(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) {
    return 'Not Available';
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}
