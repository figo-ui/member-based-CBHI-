import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/personal_info_model.dart';
import '../../cbhi_data.dart';
import '../../shared/image_utils.dart';
import '../../shared/local_attachment_store.dart';
import '../../shared/location_service.dart';
import '../../shared/ethiopic_date_utils.dart';
import '../../shared/ethiopic_date_picker.dart';

class PersonalInfoForm extends StatefulWidget {
  const PersonalInfoForm({
    super.key,
    this.initialValue,
    this.onCancel,
    required this.onNext,
    this.repository,
  });

  final PersonalInfoModel? initialValue;
  final VoidCallback? onCancel;
  final ValueChanged<PersonalInfoModel> onNext;
  final CbhiRepository? repository;

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late LocationService _locationService;

  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _dateOfBirth;
  late final TextEditingController _householdSize;
  String _gender = 'FEMALE';
  String _preferredLanguage = 'en';
  String? _birthCertificatePath;

  // Location cascade state
  List<LocationItem> _regions = [];
  List<LocationItem> _zones = [];
  List<LocationItem> _woredas = [];
  List<LocationItem> _kebeles = [];
  LocationItem? _selectedRegion;
  LocationItem? _selectedZone;
  LocationItem? _selectedWoreda;
  LocationItem? _selectedKebele;
  bool _loadingLocations = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      apiBaseUrl: widget.repository?.apiBaseUrl ?? kDefaultApiBaseUrl,
    );
    final initial = widget.initialValue;
    _firstName = TextEditingController(text: initial?.firstName ?? '');
    _middleName = TextEditingController(text: initial?.middleName ?? '');
    _lastName = TextEditingController(text: initial?.lastName ?? '');
    _phone = TextEditingController(text: initial?.phone ?? '+2519');
    _email = TextEditingController(text: initial?.email ?? '');
    _dateOfBirth = TextEditingController(
      text: initial == null
          ? ''
          : '${initial.dateOfBirth.year.toString().padLeft(4, '0')}-${initial.dateOfBirth.month.toString().padLeft(2, '0')}-${initial.dateOfBirth.day.toString().padLeft(2, '0')}',
    );
    _householdSize = TextEditingController(
      text: (initial?.householdSize ?? 1).toString(),
    );
    _gender = initial?.gender ?? 'FEMALE';
    _preferredLanguage = initial?.preferredLanguage ?? 'en';
    _birthCertificatePath = initial?.birthCertificatePath;
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() => _loadingLocations = true);
    final regions = await _locationService.fetchRegions();
    setState(() {
      _regions = regions;
      _loadingLocations = false;
    });
  }

  Future<void> _onRegionChanged(LocationItem? region) async {
    setState(() {
      _selectedRegion = region;
      _selectedZone = null;
      _selectedWoreda = null;
      _selectedKebele = null;
      _zones = [];
      _woredas = [];
      _kebeles = [];
    });
    if (region == null) return;
    final zones = await _locationService.fetchZones(region.code);
    setState(() => _zones = zones);
  }

  Future<void> _onZoneChanged(LocationItem? zone) async {
    setState(() {
      _selectedZone = zone;
      _selectedWoreda = null;
      _selectedKebele = null;
      _woredas = [];
      _kebeles = [];
    });
    if (zone == null) return;
    final woredas = await _locationService.fetchWoredas(zone.code);
    setState(() => _woredas = woredas);
  }

  Future<void> _onWoredaChanged(LocationItem? woreda) async {
    setState(() {
      _selectedWoreda = woreda;
      _selectedKebele = null;
      _kebeles = [];
    });
    if (woreda == null) return;
    final kebeles = await _locationService.fetchKebeles(woreda.code);
    setState(() => _kebeles = kebeles);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _dateOfBirth.dispose();
    _householdSize.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final parsed =
        DateTime.tryParse(_dateOfBirth.text) ?? DateTime(now.year - 20);
    final picked = await showEthiopicDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
    );
    if (picked != null) {
      _dateOfBirth.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickBirthCertificate() async {
    await Permission.camera.request();
    await Permission.photos.request();
    if (!mounted) {
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose image'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Choose PDF or image'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) {
      return;
    }
    if (choice == 'file') {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (file?.files.single.path != null) {
        final persistedPath = await LocalAttachmentStore.persist(
          file!.files.single.path!,
          category: 'registration_birth_certificate',
        );
        setState(() => _birthCertificatePath = persistedPath);
      }
      return;
    }
    final picked = choice == 'camera'
        ? await _picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );
    if (picked != null) {
      final persistedPath = await LocalAttachmentStore.persist(
        picked.path,
        category: 'registration_birth_certificate',
      );
      setState(() => _birthCertificatePath = persistedPath);
    }
  }

  bool _isImage(String path) {
    final normalized = path.toLowerCase();
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 1 of 5'),
        leading: widget.onCancel == null
            ? null
            : IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal information', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Capture household head details and supporting documents before identity verification.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _buildTextField(_firstName, 'First name', required: true),
              const SizedBox(height: 12),
              _buildTextField(_middleName, 'Middle name'),
              const SizedBox(height: 12),
              _buildTextField(_lastName, 'Last name', required: true),
              const SizedBox(height: 12),
              _buildTextField(
                _phone,
                'Phone number',
                required: true,
                keyboardType: TextInputType.phone,
                hintText: '+2519XXXXXXXX',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _email,
                'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                  DropdownMenuItem(value: 'MALE', child: Text('Male')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (value) =>
                    setState(() => _gender = value ?? 'FEMALE'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateOfBirth,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date of birth',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
                onTap: _selectDate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _preferredLanguage,
                decoration: const InputDecoration(
                  labelText: 'Preferred language',
                ),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'am', child: Text('Amharic')),
                  DropdownMenuItem(value: 'om', child: Text('Afaan Oromo')),
                ],
                onChanged: (value) =>
                    setState(() => _preferredLanguage = value ?? 'en'),
              ),
              const SizedBox(height: 20),
              Text('Household address', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              // Region dropdown
              if (_loadingLocations)
                const Center(child: CircularProgressIndicator())
              else if (_regions.isEmpty)
                ...[
                  _buildTextField(TextEditingController(text: _selectedRegion?.name ?? ''), 'Region', required: true),
                  const SizedBox(height: 12),
                  _buildTextField(TextEditingController(text: _selectedZone?.name ?? ''), 'Zone', required: true),
                  const SizedBox(height: 12),
                  _buildTextField(TextEditingController(text: _selectedWoreda?.name ?? ''), 'Woreda', required: true),
                  const SizedBox(height: 12),
                  _buildTextField(TextEditingController(text: _selectedKebele?.name ?? ''), 'Kebele', required: true),
                ]
              else ...[
                DropdownButtonFormField<LocationItem>(
                  initialValue: _selectedRegion,
                  decoration: const InputDecoration(labelText: 'Region'),
                  items: _regions.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.displayName(_preferredLanguage)),
                  )).toList(),
                  onChanged: _onRegionChanged,
                  validator: (v) => v == null ? 'Region is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LocationItem>(
                  initialValue: _selectedZone,
                  decoration: const InputDecoration(labelText: 'Zone'),
                  items: _zones.map((z) => DropdownMenuItem(
                    value: z,
                    child: Text(z.displayName(_preferredLanguage)),
                  )).toList(),
                  onChanged: _selectedRegion == null ? null : _onZoneChanged,
                  validator: (v) => v == null ? 'Zone is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LocationItem>(
                  initialValue: _selectedWoreda,
                  decoration: const InputDecoration(labelText: 'Woreda'),
                  items: _woredas.map((w) => DropdownMenuItem(
                    value: w,
                    child: Text(w.displayName(_preferredLanguage)),
                  )).toList(),
                  onChanged: _selectedZone == null ? null : _onWoredaChanged,
                  validator: (v) => v == null ? 'Woreda is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LocationItem>(
                  initialValue: _selectedKebele,
                  decoration: const InputDecoration(labelText: 'Kebele'),
                  items: _kebeles.map((k) => DropdownMenuItem(
                    value: k,
                    child: Text(k.displayName(_preferredLanguage)),
                  )).toList(),
                  onChanged: _selectedWoreda == null
                      ? null
                      : (v) => setState(() => _selectedKebele = v),
                  validator: (v) => v == null ? 'Kebele is required' : null,
                ),
              ],
              const SizedBox(height: 12),
              _buildTextField(
                _householdSize,
                'Household size',
                required: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _DocumentPickerCard(
                title: 'Birth certificate',
                subtitle: 'Optional image or PDF upload',
                path: _birthCertificatePath,
                onPick: _pickBirthCertificate,
                isImage:
                    _birthCertificatePath != null &&
                    _isImage(_birthCertificatePath!),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    widget.onNext(
                      PersonalInfoModel(
                        firstName: _firstName.text.trim(),
                        middleName: _middleName.text.trim().isEmpty
                            ? null
                            : _middleName.text.trim(),
                        lastName: _lastName.text.trim(),
                        phone: _phone.text.trim(),
                        email: _email.text.trim().isEmpty
                            ? null
                            : _email.text.trim(),
                        gender: _gender,
                        dateOfBirth:
                            DateTime.tryParse(_dateOfBirth.text.trim()) ??
                            DateTime.now(),
                        birthCertificateRef: null,
                        birthCertificatePath: _birthCertificatePath,
                        idDocumentPath: null,
                        region: _selectedRegion?.name ?? '',
                        zone: _selectedZone?.name ?? '',
                        woreda: _selectedWoreda?.name ?? '',
                        kebele: _selectedKebele?.name ?? '',
                        householdSize:
                            int.tryParse(_householdSize.text.trim()) ?? 1,
                        preferredLanguage: _preferredLanguage,
                      ),
                    );
                  },
                  child: const Text('Review information'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hintText),
      validator: required
          ? (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}

class _DocumentPickerCard extends StatelessWidget {
  const _DocumentPickerCard({
    required this.title,
    required this.subtitle,
    required this.path,
    required this.onPick,
    required this.isImage,
  });

  final String title;
  final String subtitle;
  final String? path;
  final VoidCallback onPick;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 12),
            if (path != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(path!),
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(Icons.description_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              path!.split(Platform.pathSeparator).last,
                            ),
                          ),
                        ],
                      ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                path == null ? 'Upload document' : 'Replace document',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
