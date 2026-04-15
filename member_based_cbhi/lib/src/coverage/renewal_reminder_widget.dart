import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../cbhi_data.dart';
import '../cbhi_localizations.dart';
import '../theme/app_theme.dart';

/// Renewal Reminder Widget — proactively shows renewal deadline when
/// coverage is within 30 days of expiry or already expired.
class RenewalReminderWidget extends StatelessWidget {
  const RenewalReminderWidget({
    super.key,
    required this.snapshot,
    required this.onRenew,
  });

  final CbhiSnapshot snapshot;
  final VoidCallback onRenew;

  int? get _daysUntilExpiry {
    final endDateStr = snapshot.coverage?['endDate']?.toString();
    if (endDateStr == null) return null;
    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return null;
    return endDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    final days = _daysUntilExpiry;
    final status = snapshot.coverageStatus;

    // Only show if coverage is expiring soon or expired
    if (status == 'ACTIVE' && (days == null || days > 30)) return const SizedBox.shrink();
    if (status == 'PENDING_RENEWAL') return const SizedBox.shrink();

    final isExpired = status == 'EXPIRED' || (days != null && days < 0);
    final isUrgent = !isExpired && days != null && days <= 7;

    final bgColor = isExpired ? AppTheme.error : (isUrgent ? AppTheme.warning : AppTheme.gold);
    final icon = isExpired ? Icons.error_outline : (isUrgent ? Icons.warning_amber_outlined : Icons.schedule_outlined);

    String message;
    if (isExpired) {
      message = strings.t('coverageExpiredMessage');
    } else if (isUrgent) {
      message = strings.f('coverageExpiresInDays', {'days': '$days'});
    } else {
      message = strings.f('coverageExpiresSoon', {'days': '$days'});
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: bgColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? strings.t('coverageExpired') : strings.t('renewalReminder'),
                  style: TextStyle(fontWeight: FontWeight.w700, color: bgColor, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: bgColor.withValues(alpha: 0.8))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onRenew,
            style: FilledButton.styleFrom(
              backgroundColor: bgColor,
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(strings.t('renewNow'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }
}
