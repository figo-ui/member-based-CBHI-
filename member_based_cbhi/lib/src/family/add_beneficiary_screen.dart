import 'dart:convert';
import 'dart:io' if (dart.library.html) '../shared/web_stubs.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'
    if (dart.library.html) '../shared/permission_handler_stub.dart';

import '../cbhi_data.dart';
import '../cbhi_localizations.dart';
import '../i18n/app_localizations.dart';
import '../shared/ethiopic_date_picker.dart';
import '../shared/local_attachment_store.dart';
import '../shared/native_file_image_impl.dart'
    if (dart.library.html) '../shared/native_file_image_web.dart' as impl;
import '../theme/app_theme.dart';
import 'add_beneficiary_cubit.dart';

// ── Local enum for ID scan status ────────────────────────────────────────────
enum _BeneficiaryIdScanStatus { idle, scanning, success, lowConfidence, failed }

class AddBeneficiaryScreen extends StatefulWidget {
  const AddBeneficiaryScreen({
    super.key,
    required this.repository,
    this.member,
  });

  final CbhiRepository repository;
  final FamilyMember? member;

  @override
  State<AddBeneficiaryScreen> createState() => _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends State<AddBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final AddBeneficiaryCubit _cubit;
  late final TextEditingController _fullNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _phoneController;

  String _gender = 'FEMALE';
  String _relationship = 'CHILD';
  String? _identityType;

  // ── ID scanner local state ─────────────────────────────────────────────────
  List<int>? _idImageBytes;
  String? _idImageName;
  _BeneficiaryIdScanStatus _idScanStatus = _BeneficiaryIdScanStatus.idle;
  String _extractedIdNumber = '';
  String? _idScanError;

  @override
  void initState() {
    super.initState();
    _cubit = AddBeneficiaryCubit(
      widget.repository,
      initialPhotoPath: widget.member?.photoPath,
    );
    _fullNameController = TextEditingController(
      text: widget.member?.fullName ?? '',
    );
    _dobController = TextEditingController(
      text: widget.member?.dateOfBirth?.split('T').first ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.member?.phoneNumber ?? '+2519',
    );
    _gender = widget.member?.gender ?? 'FEMALE';
    _relationship = widget.member?.relationshipToHouseholdHead ?? 'CHILD';
    _identityType = widget.member?.identityType;
    // Pre-populate extracted ID from existing member data (edit mode)
    _extractedIdNumber = widget.member?.identityNumber ?? '';
    if (_extractedIdNumber.isNotEmpty) {
      _idScanStatus = _BeneficiaryIdScanStatus.success;
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final strings = CbhiLocalizations.of(context);
    final now = DateTime.now();
    final initialDate =
        DateTime.tryParse(_dobController.text) ?? DateTime(now.year - 12);
    final picked = await showEthiopicDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: strings.t('selectDateOfBirth'),
    );
    if (picked != null) {
      _dobController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selectPhoto() async {
    final strings = CbhiLocalizations.of(context);
    final cameraStatus = await Permission.camera.request();
    final photoStatus = await Permission.photos.request();
    if (!mounted) {
      return;
    }
    if (!cameraStatus.isGranted && !photoStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('cameraOrGalleryPermissionRequired'))),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(strings.t('takePhoto')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(strings.t('chooseFromGallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null && mounted) {
      final persistedPath = await LocalAttachmentStore.persist(
        image.path,
        category: 'beneficiary_photo',
      );
      _cubit.setPhotoPath(persistedPath);
    }
  }

  Future<void> _save() async {
    final strings = CbhiLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if ((_cubit.state.photoPath ?? '').isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.t('photoRequired'))));
      return;
    }

    final nameParts = _splitName(_fullNameController.text.trim());
    final dateOfBirth =
        DateTime.tryParse(_dobController.text.trim()) ?? DateTime.now();
    final draft = FamilyMemberDraft(
      firstName: nameParts.$1,
      middleName: nameParts.$2,
      lastName: nameParts.$3,
      gender: _gender,
      dateOfBirth: dateOfBirth,
      relationshipToHouseholdHead: _relationship,
      identityType: _extractedIdNumber.trim().isEmpty
          ? null
          : _identityType,
      identityNumber: _extractedIdNumber.trim().isEmpty
          ? null
          : _extractedIdNumber.trim(),
      phoneNumber:
          (_phoneController.text.trim().isEmpty ||
              _phoneController.text.trim() == '+2519')
          ? null
          : _phoneController.text.trim(),
      photoPath: _cubit.state.photoPath,
    );

    final success = await _cubit.submit(
      memberId: widget.member?.id,
      draft: draft,
    );
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  // ── ID image picking ───────────────────────────────────────────────────────

  Future<void> _pickIdImage({bool fromCamera = false}) async {
    try {
      List<int>? bytes;
      String? name;

      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.first;
        bytes = file.bytes?.toList();
        name = file.name;
      } else {
        final XFile? picked = await _picker.pickImage(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        if (picked == null) return;
        bytes = await picked.readAsBytes().then((b) => b.toList());
        name = picked.name;
      }

      if (bytes == null || bytes.isEmpty) return;

      setState(() {
        _idImageBytes = bytes;
        _idImageName = name;
        _idScanStatus = _BeneficiaryIdScanStatus.idle;
        _idScanError = null;
        _extractedIdNumber = '';
      });

      await _runOcr(bytes);
    } catch (_) {
      // User cancelled or permission denied — silently ignore
    }
  }

  Future<void> _runOcr(List<int> bytes) async {
    setState(() {
      _idScanStatus = _BeneficiaryIdScanStatus.scanning;
      _idScanError = null;
      _extractedIdNumber = '';
    });

    try {
      final base64Image = base64Encode(bytes);
      final result = await widget.repository.validateIdDocument(
        imageBase64: base64Image,
      );

      final detectedId = result['detectedIdNumber']?.toString() ?? '';
      final isValid = result['isValid'] == true;
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      final issues = (result['issues'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      final isLowConfidence = !isValid && issues.isNotEmpty;

      if (detectedId.isNotEmpty && (isValid || confidence >= 0.6)) {
        setState(() {
          _extractedIdNumber = detectedId;
          _idScanStatus = _BeneficiaryIdScanStatus.success;
          _idScanError = null;
        });
      } else if (isLowConfidence) {
        setState(() {
          _extractedIdNumber = detectedId;
          _idScanStatus = _BeneficiaryIdScanStatus.lowConfidence;
          _idScanError = issues.isNotEmpty ? issues.first : null;
        });
      } else {
        setState(() {
          _idScanStatus = _BeneficiaryIdScanStatus.failed;
          _idScanError = issues.isNotEmpty
              ? issues.first
              : 'Could not extract ID number from the document.';
        });
      }
    } catch (e) {
      setState(() {
        _idScanStatus = _BeneficiaryIdScanStatus.failed;
        _idScanError = e.toString();
      });
    }
  }

  void _clearIdImage() {
    setState(() {
      _idImageBytes = null;
      _idImageName = null;
      _idScanStatus = _BeneficiaryIdScanStatus.idle;
      _idScanError = null;
      _extractedIdNumber = '';
    });
  }

  void _showIdPickerOptions(BuildContext context) {
    if (kIsWeb) {
      _pickIdImage(fromCamera: false);
      return;
    }
    final strings = CbhiLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(strings.t('takePhoto')),
              onTap: () {
                Navigator.pop(ctx);
                _pickIdImage(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(strings.t('chooseFromGallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickIdImage(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Builder(
        builder: (context) {
          return BlocListener<AddBeneficiaryCubit, AddBeneficiaryState>(
            listenWhen: (previous, current) => previous.error != current.error,
            listener: (context, state) {
              if (state.error != null && state.error!.isNotEmpty) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.error!)));
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.member == null
                      ? CbhiLocalizations.of(context).t('addBeneficiary')
                      : CbhiLocalizations.of(context).t('editBeneficiary'),
                ),
              ),
              body: BlocBuilder<AddBeneficiaryCubit, AddBeneficiaryState>(
                builder: (context, state) {
                  final strings = CbhiLocalizations.of(context);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t('beneficiaryDetails'),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(strings.t('captureBeneficiaryProfile')),
                          const SizedBox(height: 24),
                          _PhotoPreview(
                            repository: widget.repository,
                            photoPath: state.photoPath,
                            fallbackLabel: _initials(_fullNameController.text),
                            onPick: _selectPhoto,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: strings.t('fullName'),
                            ),
                            validator: (value) {
                              final parts =
                                  value
                                      ?.trim()
                                      .split(RegExp(r'\s+'))
                                      .where((part) => part.isNotEmpty)
                                      .toList() ??
                                  const <String>[];
                              if (parts.length < 2) {
                                return strings.t('fullNamePartsRequired');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: strings.t('dateOfBirth'),
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                            ),
                            onTap: _pickDate,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? strings.t('dateOfBirthRequired')
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: InputDecoration(
                              labelText: strings.t('gender'),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'FEMALE',
                                child: Text(strings.t('female')),
                              ),
                              DropdownMenuItem(
                                value: 'MALE',
                                child: Text(strings.t('male')),
                              ),
                              DropdownMenuItem(
                                value: 'OTHER',
                                child: Text(strings.t('other')),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _gender = value ?? 'FEMALE'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _relationship,
                            decoration: InputDecoration(
                              labelText: strings.t(
                                'relationshipToHouseholdHead',
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'SPOUSE',
                                child: Text(strings.t('spouse')),
                              ),
                              DropdownMenuItem(
                                value: 'CHILD',
                                child: Text(strings.t('child')),
                              ),
                              DropdownMenuItem(
                                value: 'PARENT',
                                child: Text(strings.t('parent')),
                              ),
                              DropdownMenuItem(
                                value: 'SIBLING',
                                child: Text(strings.t('sibling')),
                              ),
                              DropdownMenuItem(
                                value: 'OTHER',
                                child: Text(strings.t('other')),
                              ),
                            ],
                            onChanged: (value) => setState(
                              () => _relationship = value ?? 'CHILD',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            strings.t('independentAccessSection'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(strings.t('independentAccessDescription')),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: strings.t('phoneNumber'),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (_relationship == 'CHILD' &&
                                  (trimmed.isEmpty || trimmed == '+2519')) {
                                return null;
                              }
                              if (trimmed.isEmpty || trimmed == '+2519') {
                                return strings.t('phoneRequiredForNonChild');
                              }
                              if (trimmed.length < 10) {
                                return strings.t(
                                  'enterValidEthiopianMobileNumber',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            strings.t('identityDetails'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(strings.t('nationalIdOrLocalIdOptional')),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: _identityType,
                            decoration: InputDecoration(
                              labelText: strings.t('idTypeOptional'),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(strings.t('none')),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'NATIONAL_ID',
                                child: Text(strings.t('nationalId')),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'LOCAL_ID',
                                child: Text(strings.t('localId')),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _identityType = value),
                          ),
                          // Only show scanner when an ID type is selected
                          if (_identityType != null) ...[
                            const SizedBox(height: 16),
                            _BeneficiaryIdScanner(
                              imageBytes: _idImageBytes,
                              imageName: _idImageName,
                              scanStatus: _idScanStatus,
                              extractedIdNumber: _extractedIdNumber,
                              scanError: _idScanError,
                              strings: strings,
                              textTheme: Theme.of(context).textTheme,
                              onPickImage: () =>
                                  _showIdPickerOptions(context),
                              onRemoveImage: _clearIdImage,
                              onRetry: () {
                                if (_idImageBytes != null) {
                                  _runOcr(_idImageBytes!);
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: state.isSubmitting ? null : _save,
                              icon: state.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                widget.member == null
                                    ? strings.t('saveBeneficiary')
                                    : strings.t('updateBeneficiary'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  (String, String?, String) _splitName(String fullName) {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) {
      return (fullName.trim(), null, 'Member');
    }
    if (parts.length == 2) {
      return (parts.first, null, parts.last);
    }
    return (
      parts.first,
      parts.sublist(1, parts.length - 1).join(' '),
      parts.last,
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'B';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.repository,
    required this.photoPath,
    required this.fallbackLabel,
    required this.onPick,
  });

  final CbhiRepository repository;
  final String? photoPath;
  final String fallbackLabel;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    final resolvedUrl = repository.resolveMediaUrl(photoPath);
    final hasLocalFile =
        !kIsWeb &&
        photoPath != null &&
        photoPath!.isNotEmpty &&
        File(photoPath!).existsSync();


    Widget avatar;
    if (hasLocalFile) {
      avatar = CircleAvatar(
        radius: 42,
        backgroundImage: impl.getFileImageProvider(photoPath!),
      );
    } else if (resolvedUrl.startsWith('http://') ||
        resolvedUrl.startsWith('https://')) {
      avatar = CircleAvatar(
        radius: 42,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: resolvedUrl,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const CircularProgressIndicator(strokeWidth: 2),
            errorWidget: (context, url, error) => Text(
              fallbackLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
    } else {
      avatar = CircleAvatar(
        radius: 42,
        child: Text(
          fallbackLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('beneficiaryPhoto'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(strings.t('useCameraOrGalleryConfirmPreview')),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: onPick,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(strings.t('addOrChangePhoto')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Beneficiary ID Scanner Widget ────────────────────────────────────────────

class _BeneficiaryIdScanner extends StatelessWidget {
  const _BeneficiaryIdScanner({
    required this.imageBytes,
    required this.imageName,
    required this.scanStatus,
    required this.extractedIdNumber,
    required this.scanError,
    required this.strings,
    required this.textTheme,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onRetry,
  });

  final List<int>? imageBytes;
  final String? imageName;
  final _BeneficiaryIdScanStatus scanStatus;
  final String extractedIdNumber;
  final String? scanError;
  final AppLocalizations strings;
  final TextTheme textTheme;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.t('identityDocument'),
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Image preview or upload prompt
        if (imageBytes != null)
          _ImagePreview(
            imageBytes: Uint8List.fromList(imageBytes!),
            imageName: imageName,
            onRemove: onRemoveImage,
            strings: strings,
          )
        else
          _UploadPrompt(
            onPick: onPickImage,
            strings: strings,
          ),

        const SizedBox(height: 16),

        // OCR status area
        _OcrStatusArea(
          scanStatus: scanStatus,
          extractedIdNumber: extractedIdNumber,
          scanError: scanError,
          onRetry: onRetry,
          strings: strings,
          textTheme: textTheme,
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            child: Image.memory(
              imageBytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  imageName ?? strings.t('idDocument'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  strings.t('documentUploaded'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            tooltip: strings.t('remove'),
          ),
        ],
      ),
    );
  }
}

// ── Upload Prompt ─────────────────────────────────────────────────────────────

class _UploadPrompt extends StatelessWidget {
  const _UploadPrompt({
    required this.onPick,
    required this.strings,
  });

  final VoidCallback onPick;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPick,
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
}

// ── OCR Status Area ───────────────────────────────────────────────────────────

class _OcrStatusArea extends StatelessWidget {
  const _OcrStatusArea({
    required this.scanStatus,
    required this.extractedIdNumber,
    required this.scanError,
    required this.onRetry,
    required this.strings,
    required this.textTheme,
  });

  final _BeneficiaryIdScanStatus scanStatus;
  final String extractedIdNumber;
  final String? scanError;
  final VoidCallback onRetry;
  final AppLocalizations strings;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (scanStatus) {
      case _BeneficiaryIdScanStatus.idle:
        return const SizedBox.shrink();

      case _BeneficiaryIdScanStatus.scanning:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.t('scanningDocument'),
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );

      case _BeneficiaryIdScanStatus.success:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.t('idExtracted'),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extractedIdNumber,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case _BeneficiaryIdScanStatus.lowConfidence:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: colorScheme.tertiary.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: colorScheme.tertiary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.t('lowConfidenceDetection'),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              if (extractedIdNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${strings.t('detectedId')}: $extractedIdNumber',
                  style: textTheme.bodyMedium,
                ),
              ],
              if (scanError != null) ...[
                const SizedBox(height: 4),
                Text(
                  scanError!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(strings.t('retry')),
              ),
            ],
          ),
        );

      case _BeneficiaryIdScanStatus.failed:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.t('scanFailed'),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              if (scanError != null) ...[
                const SizedBox(height: 8),
                Text(
                  scanError!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(strings.t('retry')),
              ),
            ],
          ),
        );
    }
  }
}
