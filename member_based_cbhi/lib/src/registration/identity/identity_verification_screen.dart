import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cbhi_localizations.dart';
import '../../i18n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../shared/language_selector.dart';
import '../registration_cubit.dart';
import 'identity_cubit.dart';
import '../models/identity_model.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedIdentityType;
  String? selectedEmploymentStatus;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final List<Map<String, String>> employmentOptions = [
      {'value': 'farmer', 'label': strings.t('farmer')},
      {'value': 'merchant', 'label': strings.t('merchant')},
      {'value': 'daily_laborer', 'label': strings.t('dailyLaborer')},
      {'value': 'employed', 'label': strings.t('employed')},
      {'value': 'homemaker', 'label': strings.t('homemaker')},
      {'value': 'student', 'label': strings.t('student')},
      {'value': 'unemployed', 'label': strings.t('unemployed')},
      {'value': 'pensioner', 'label': strings.t('pensioner')},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('identityAndEmployment')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.read<RegistrationCubit>().goBackToConfirmation(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSelector(isLight: true),
          ),
        ],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) =>
                IdentityCubit(ctx.read<RegistrationCubit>().repository),
          ),
        ],
        child: BlocBuilder<IdentityCubit, IdentityState>(
          builder: (context, identityState) {
            final identityCubit = context.read<IdentityCubit>();
            final regCubit = context.read<RegistrationCubit>();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppTheme.spacingM),

                        // ── Header ──────────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppTheme.cardGradient,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t('identityVerification'),
                                style: textTheme.headlineSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.t('collectIdForScreening'),
                                style: textTheme.bodyMedium?.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Identity Section header ─────────────────
                                Row(
                                  children: [
                                    const Icon(Icons.badge_outlined,
                                        color: AppTheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      strings.t('identityDetails'),
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),

                                // ── Identity Type Picker ────────────────────
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText:
                                        strings.t('identityDocumentType'),
                                    prefixIcon:
                                        const Icon(Icons.category_outlined),
                                  ),
                                  initialValue: selectedIdentityType,
                                  items: [
                                    DropdownMenuItem(
                                        value: 'NATIONAL_ID',
                                        child: Text(strings.t('nationalId'))),
                                    DropdownMenuItem(
                                        value: 'PASSPORT',
                                        child: Text(strings.t('passport'))),
                                    DropdownMenuItem(
                                        value: 'LOCAL_ID',
                                        child: Text(strings.t('localId'))),
                                  ],
                                  onChanged: (value) {
                                    setState(
                                        () => selectedIdentityType = value);
                                  },
                                  validator: (v) =>
                                      v == null ? strings.t('required') : null,
                                ),

                                const SizedBox(height: 24),

                                // ── ID Document Scanner ─────────────────────
                                _IdDocumentScanner(
                                  state: identityState,
                                  cubit: identityCubit,
                                  strings: strings,
                                  textTheme: textTheme,
                                ),

                                const SizedBox(height: 40),

                                // ── Employment Section ──────────────────────
                                Row(
                                  children: [
                                    const Icon(Icons.work_outline,
                                        color: AppTheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      strings.t('employmentOccupationStatus'),
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),

                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: strings.t('mainOccupation'),
                                    prefixIcon: const Icon(
                                        Icons.work_history_outlined),
                                  ),
                                  initialValue: selectedEmploymentStatus,
                                  items: employmentOptions
                                      .map((option) => DropdownMenuItem(
                                            value: option['value'],
                                            child: Text(option['label']!),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() =>
                                        selectedEmploymentStatus = value);
                                    identityCubit
                                        .updateEmploymentStatus(value ?? '');
                                  },
                                  validator: (v) =>
                                      v == null ? strings.t('required') : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _canSubmit(identityState)
                                ? () {
                                    if (_formKey.currentState!.validate() &&
                                        selectedIdentityType != null &&
                                        selectedEmploymentStatus != null) {
                                      final identityModel = IdentityModel(
                                        identityType: selectedIdentityType!,
                                        identityNumber:
                                            identityState.identityNumber,
                                        employmentStatus:
                                            selectedEmploymentStatus!,
                                      );
                                      regCubit.submitIdentity(identityModel);
                                    }
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(strings.t('continueToMembership')),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _canSubmit(IdentityState state) {
    // Must have an image selected and OCR must not be in progress
    if (state.idImageBytes == null) return false;
    if (state.scanStatus == IdScanStatus.scanning) return false;
    // Must have an extracted (or low-confidence) ID number
    if (state.identityNumber.trim().isEmpty) return false;
    // Block if name mismatch
    if (state.nameMatchStatus == IdNameMatchStatus.mismatch) return false;
    // Block if ID is taken or availability check is in progress
    if (state.idAvailabilityStatus == IdAvailabilityStatus.taken) return false;
    if (state.idAvailabilityStatus == IdAvailabilityStatus.checking) return false;
    return true;
  }
}

// ── ID Document Scanner Widget ───────────────────────────────────────────────

class _IdDocumentScanner extends StatelessWidget {
  const _IdDocumentScanner({
    required this.state,
    required this.cubit,
    required this.strings,
    required this.textTheme,
  });

  final IdentityState state;
  final IdentityCubit cubit;
  final AppLocalizations strings;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.t('identityDocument'),
          style: textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Image preview or upload prompt
        if (state.idImageBytes != null)
          _ImagePreview(
            imageBytes: Uint8List.fromList(state.idImageBytes!),
            imageName: state.idImageName,
            onRemove: cubit.clearIdImage,
            strings: strings,
          )
        else
          _UploadPrompt(
            cubit: cubit,
            strings: strings,
          ),

        const SizedBox(height: 16),

        // OCR status area
        _OcrStatusArea(
          state: state,
          cubit: cubit,
          strings: strings,
          textTheme: textTheme,
        ),

        // Name matching status (if name was detected)
        if (state.detectedName != null && state.detectedName!.isNotEmpty)
          ...[
            const SizedBox(height: 16),
            _NameMatchingCard(
              state: state,
              cubit: cubit,
              strings: strings,
              textTheme: textTheme,
            ),
          ],

        // ID availability status (if ID was extracted)
        if (state.identityNumber.isNotEmpty)
          ...[
            const SizedBox(height: 16),
            _IdAvailabilityCard(
              state: state,
              strings: strings,
              textTheme: textTheme,
            ),
          ],
      ],
    );
  }
}

// ── Upload Prompt ─────────────────────────────────────────────────────────────

class _UploadPrompt extends StatelessWidget {
  const _UploadPrompt({required this.cubit, required this.strings});

  final IdentityCubit cubit;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showPickerOptions(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          color: colorScheme.surfaceContainerLowest,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 48,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              strings.t('scanOrUploadId'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              strings.t('scanOrUploadIdHint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
    // On web, file_picker is used directly (no camera option)
    if (kIsWeb) {
      cubit.pickIdImage(fromCamera: false);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final strings = CbhiLocalizations.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(strings.t('takePhoto')),
                onTap: () {
                  Navigator.pop(ctx);
                  cubit.pickIdImage(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(strings.t('chooseFromGallery')),
                onTap: () {
                  Navigator.pop(ctx);
                  cubit.pickIdImage(fromCamera: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Image Preview ─────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imageBytes,
    required this.imageName,
    required this.onRemove,
    required this.strings,
  });

  final Uint8List imageBytes;
  final String? imageName;
  final VoidCallback onRemove;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusM),
            ),
            child: Image.memory(
              imageBytes,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    imageName ?? strings.t('identityDocument'),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(strings.t('removeIdImage')),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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

// ── OCR Status Area ───────────────────────────────────────────────────────────

class _OcrStatusArea extends StatelessWidget {
  const _OcrStatusArea({
    required this.state,
    required this.cubit,
    required this.strings,
    required this.textTheme,
  });

  final IdentityState state;
  final IdentityCubit cubit;
  final AppLocalizations strings;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (state.scanStatus) {
      case IdScanStatus.idle:
        // No image selected yet — show nothing
        if (state.idImageBytes == null) return const SizedBox.shrink();
        // Image selected but OCR not started (shouldn't normally happen)
        return const SizedBox.shrink();

      case IdScanStatus.scanning:
        return _StatusCard(
          icon: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          message: strings.t('idOcrProcessing'),
          color: colorScheme.primaryContainer,
          textColor: colorScheme.onPrimaryContainer,
        );

      case IdScanStatus.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(
              icon: Icon(Icons.check_circle_outline,
                  color: AppTheme.success, size: 20),
              message: strings.t('idOcrSuccess'),
              color: AppTheme.success.withValues(alpha: 0.1),
              textColor: AppTheme.success,
            ),
            const SizedBox(height: 12),
            _ExtractedIdField(
              idNumber: state.identityNumber,
              strings: strings,
              textTheme: textTheme,
            ),
          ],
        );

      case IdScanStatus.lowConfidence:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(
              icon: Icon(Icons.warning_amber_outlined,
                  color: AppTheme.warning, size: 20),
              message: strings.t('idOcrLowConfidence'),
              color: AppTheme.warning.withValues(alpha: 0.1),
              textColor: AppTheme.warning,
              subtitle: state.scanError,
            ),
            if (state.identityNumber.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ExtractedIdField(
                idNumber: state.identityNumber,
                strings: strings,
                textTheme: textTheme,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => cubit.retryOcr(
                personalInfo: context.read<RegistrationCubit>().state.personalInfo,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(strings.t('retryValidation')),
            ),
          ],
        );

      case IdScanStatus.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(
              icon: Icon(Icons.error_outline,
                  color: colorScheme.error, size: 20),
              message: strings.t('idOcrFailed'),
              color: colorScheme.errorContainer,
              textColor: colorScheme.onErrorContainer,
              subtitle: state.scanError,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => cubit.retryOcr(
                personalInfo: context.read<RegistrationCubit>().state.personalInfo,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(strings.t('retryValidation')),
            ),
          ],
        );
    }
  }
}

// ── Extracted ID read-only display ────────────────────────────────────────────

class _ExtractedIdField extends StatelessWidget {
  const _ExtractedIdField({
    required this.idNumber,
    required this.strings,
    required this.textTheme,
  });

  final String idNumber;
  final AppLocalizations strings;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: strings.t('extractedIdNumber'),
        prefixIcon: const Icon(Icons.badge_outlined),
        suffixIcon: const Icon(Icons.lock_outline, size: 18),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: const OutlineInputBorder(),
        helperText: strings.t('extractedIdNumberHint'),
      ),
      child: Text(
        idNumber,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Generic status card ───────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.message,
    required this.color,
    required this.textColor,
    this.subtitle,
  });

  final Widget icon;
  final String message;
  final Color color;
  final Color textColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ── Name Matching Card ────────────────────────────────────────────────────────

class _NameMatchingCard extends StatelessWidget {
  const _NameMatchingCard({
    required this.state,
    required this.cubit,
    required this.strings,
    required this.textTheme,
  });

  final IdentityState state;
  final IdentityCubit cubit;
  final AppLocalizations strings;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (state.nameMatchStatus) {
      case IdNameMatchStatus.matched:
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        statusText = strings.t('nameMatchSuccess');
        break;
      case IdNameMatchStatus.mismatch:
        statusColor = colorScheme.error;
        statusIcon = Icons.error;
        statusText = strings.t('nameMatchMismatch');
        break;
      case IdNameMatchStatus.skipped:
        statusColor = colorScheme.outline;
        statusIcon = Icons.info_outline;
        statusText = strings.t('nameMatchSkipped');
        break;
      case IdNameMatchStatus.notChecked:
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.t('nameMatchTitle'),
                style: textTheme.titleSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: textTheme.bodyMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.detectedName != null) ...[
            const SizedBox(height: 12),
            _NameComparisonRow(
              label: strings.t('nameOnId'),
              value: state.detectedName!,
              textTheme: textTheme,
            ),
            const SizedBox(height: 8),
            _NameComparisonRow(
              label: strings.t('nameYouEntered'),
              value: context.read<RegistrationCubit>().state.personalInfo?.fullName ?? '',
              textTheme: textTheme,
            ),
          ],
          if (state.nameMatchStatus == IdNameMatchStatus.mismatch) ...[
            const SizedBox(height: 12),
            Text(
              strings.t('nameMatchMismatchWarning'),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            strings.t('nameMatchHint'),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameComparisonRow extends StatelessWidget {
  const _NameComparisonRow({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── ID Availability Card ──────────────────────────────────────────────────────

class _IdAvailabilityCard extends StatelessWidget {
  const _IdAvailabilityCard({
    required this.state,
    required this.strings,
    required this.textTheme,
  });

  final IdentityState state;
  final AppLocalizations strings;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? subtitle;

    switch (state.idAvailabilityStatus) {
      case IdAvailabilityStatus.checking:
        statusColor = colorScheme.primary;
        statusIcon = Icons.hourglass_empty;
        statusText = strings.t('idAvailabilityChecking');
        break;
      case IdAvailabilityStatus.available:
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        statusText = strings.t('idAvailabilityAvailable');
        break;
      case IdAvailabilityStatus.taken:
        statusColor = colorScheme.error;
        statusIcon = Icons.error;
        statusText = strings.t('idAvailabilityTaken');
        subtitle = strings.t('duplicateIdError');
        break;
      case IdAvailabilityStatus.unchecked:
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.idAvailabilityStatus == IdAvailabilityStatus.checking)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else
            Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: statusColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
