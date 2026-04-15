import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/admin_repository.dart';
import '../i18n/app_localizations.dart';
import '../theme/admin_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _exporting = false;
  String? _message;
  bool _isSuccess = false;

  // Date range filter
  DateTime? _from;
  DateTime? _to;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AdminTheme.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
    }
  }

  void _clearDateRange() => setState(() { _from = null; _to = null; });

  Future<void> _export(String type) async {
    final strings = AppLocalizations.of(context);
    setState(() { _exporting = true; _message = null; });
    try {
      final csv = await widget.repository.exportCsv(
        type: type,
        from: _from?.toIso8601String().split('T').first,
        to: _to?.toIso8601String().split('T').first,
      );
      final path = await FilePicker.platform.saveFile(
        dialogTitle: strings.t('saveExport', {'type': _titleForType(type, strings)}),
        fileName: 'cbhi_${type}_${DateTime.now().toIso8601String().split('T').first}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path != null) {
        await File(path).writeAsString(csv);
        setState(() {
          _isSuccess = true;
          _message = strings.t('exportedTo', {'path': path});
        });
      }
    } catch (e) {
      setState(() { _isSuccess = false; _message = e.toString(); });
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final fmt = DateFormat('dd MMM yyyy');
    final hasRange = _from != null && _to != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.t('dataExport'),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AdminTheme.textDark)),
          const SizedBox(height: 8),
          Text(strings.t('exportSubtitle'),
              style: const TextStyle(color: AdminTheme.textSecondary)),
          const SizedBox(height: 20),

          // Date range picker
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_outlined, size: 18, color: AdminTheme.primary),
                label: Text(
                  hasRange
                      ? '${fmt.format(_from!)} — ${fmt.format(_to!)}'
                      : strings.t('selectDateRange'),
                  style: const TextStyle(color: AdminTheme.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AdminTheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              if (hasRange) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDateRange,
                  icon: const Icon(Icons.close, size: 18, color: AdminTheme.textSecondary),
                  tooltip: strings.t('clearDateRange'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    strings.t('dateRangeActive'),
                    style: const TextStyle(
                        color: AdminTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          if (_message != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: (_isSuccess ? AdminTheme.success : AdminTheme.error).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    color: _isSuccess ? AdminTheme.success : AdminTheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_message!)),
                ],
              ),
            ),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ExportCard(
                icon: Icons.home_outlined,
                title: strings.t('households'),
                description: strings.t('householdsExportDescription'),
                onExport: _exporting ? null : () => _export('households'),
              ),
              _ExportCard(
                icon: Icons.receipt_long_outlined,
                title: strings.t('claims'),
                description: strings.t('claimsExportDescription'),
                onExport: _exporting ? null : () => _export('claims'),
              ),
              _ExportCard(
                icon: Icons.payments_outlined,
                title: strings.t('payments'),
                description: strings.t('paymentsExportDescription'),
                onExport: _exporting ? null : () => _export('payments'),
              ),
              _ExportCard(
                icon: Icons.volunteer_activism_outlined,
                title: strings.t('indigentApplications'),
                description: strings.t('indigentExportDescription'),
                onExport: _exporting ? null : () => _export('indigent'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onExport,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AdminTheme.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16, color: AdminTheme.textDark)),
              const SizedBox(height: 6),
              Text(description,
                  style: const TextStyle(
                      color: AdminTheme.textSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onExport,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(strings.t('exportCsv')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _titleForType(String type, AppLocalizations strings) => switch (type) {
  'claims' => strings.t('claims'),
  'payments' => strings.t('payments'),
  'indigent' => strings.t('indigentApplications'),
  _ => strings.t('households'),
};
