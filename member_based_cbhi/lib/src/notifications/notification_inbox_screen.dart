import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cbhi_localizations.dart';
import '../cbhi_state.dart';
import '../theme/app_theme.dart';

/// Full-screen notification inbox — shows all notifications with read/unread state.
class NotificationInboxScreen extends StatelessWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('allNotifications')),
        actions: [
          BlocBuilder<AppCubit, AppState>(
            builder: (context, state) {
              final unread = (state.snapshot?.notifications ?? [])
                  .where((n) => n['isRead'] != true)
                  .length;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _markAllRead(context, state),
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(strings.t('markAllRead')),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final notifications = state.snapshot?.notifications ?? [];
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notifications.isEmpty) {
            return _EmptyInbox(strings: strings);
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => context.read<AppCubit>().sync(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(
                  notification: n,
                  onTap: n['id'] == null
                      ? null
                      : () => context
                          .read<AppCubit>()
                          .markNotificationRead(n['id'].toString()),
                ).animate().fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: index * 40),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, AppState state) async {
    final cubit = context.read<AppCubit>();
    final unread = (state.snapshot?.notifications ?? [])
        .where((n) => n['isRead'] != true && n['id'] != null)
        .toList();
    for (final n in unread) {
      await cubit.markNotificationRead(n['id'].toString());
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    this.onTap,
  });

  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] == true;
    final type = notification['type']?.toString() ?? '';
    final title = notification['title']?.toString() ?? '';
    final message = notification['message']?.toString() ?? '';
    final createdAt = notification['createdAt']?.toString() ?? '';

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _iconColor(type).withValues(alpha: isRead ? 0.08 : 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _iconData(type),
          color: _iconColor(type).withValues(alpha: isRead ? 0.5 : 1.0),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: isRead ? FontWeight.w400 : FontWeight.w700,
          color: isRead ? AppTheme.textSecondary : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isRead ? AppTheme.textSecondary : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _formatDate(createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
      trailing: isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  IconData _iconData(String type) {
    switch (type) {
      case 'CLAIM_UPDATE':
        return Icons.receipt_long_outlined;
      case 'PAYMENT_CONFIRMATION':
        return Icons.payments_outlined;
      case 'RENEWAL_REMINDER':
        return Icons.autorenew_outlined;
      case 'SYSTEM_ALERT':
        return Icons.info_outline;
      case 'HEALTH_PROMOTION':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'CLAIM_UPDATE':
        return AppTheme.primary;
      case 'PAYMENT_CONFIRMATION':
        return AppTheme.gold;
      case 'RENEWAL_REMINDER':
        return AppTheme.warning;
      case 'SYSTEM_ALERT':
        return AppTheme.accent;
      default:
        return AppTheme.primary;
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.strings});
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.t('noNotificationsYet'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            strings.t('coverageAlertsHere'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
