import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/admin_repository.dart';
import '../i18n/app_localizations.dart';
import '../theme/admin_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _settings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await widget.repository.getConfiguration();
      setState(() => _settings = settings);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> setting) async {
    final strings = AppLocalizations.of(context);
    final labelCtrl = TextEditingController(
      text: setting['label']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: setting['description']?.toString() ?? '',
    );
    final valueCtrl = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(setting['value'] ?? {}),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.tune, color: AdminTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(setting['key']?.toString() ?? strings.t('setting')),
            ),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(labelText: strings.t('label')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: strings.t('description'),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl,
                  decoration: InputDecoration(
                    labelText: strings.t('valueJson'),
                  ),
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final decoded = jsonDecode(valueCtrl.text.trim()) as Map<String, dynamic>;
      await widget.repository.updateConfiguration(
        key: setting['key'].toString(),
        value: decoded,
        label: labelCtrl.text.trim(),
        description: descCtrl.text.trim(),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.t('settingUpdated')),
            backgroundColor: AdminTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AdminTheme.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: AdminTheme.primary),
      );
    if (_error != null)
      return Center(
        child: Text(_error!, style: const TextStyle(color: AdminTheme.error)),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('systemConfiguration'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.t('manageSystemSettings'),
            style: const TextStyle(color: AdminTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ..._settings.map(
            (setting) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: AdminTheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  setting['label']?.toString() ??
                      setting['key']?.toString() ??
                      '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((setting['description']?.toString() ?? '').isNotEmpty)
                      Text(
                        setting['description'].toString(),
                        style: const TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F9F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent(
                          '  ',
                        ).convert(setting['value'] ?? {}),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AdminTheme.primary,
                  ),
                  onPressed: () => _edit(setting),
                  tooltip: strings.t('edit'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
