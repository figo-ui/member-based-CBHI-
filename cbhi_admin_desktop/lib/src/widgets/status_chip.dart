import 'package:flutter/material.dart';
import '../i18n/app_localizations.dart';
import '../theme/admin_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  Color get _color {
    return switch (status.toUpperCase()) {
      'ACTIVE' || 'APPROVED' || 'PAID' || 'SUCCESS' => AdminTheme.success,
      'PENDING' || 'SUBMITTED' || 'UNDER_REVIEW' => AdminTheme.warning,
      'REJECTED' || 'FAILED' || 'EXPIRED' => AdminTheme.error,
      _ => AdminTheme.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        strings.statusLabel(status),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
