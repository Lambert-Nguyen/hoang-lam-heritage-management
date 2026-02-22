import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';

/// Notification list screen showing all notifications
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notificationsAsync = ref.watch(notificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: l10n.markAllRead,
            onPressed: () async {
              final count =
                  await ref
                      .read(notificationNotifierProvider.notifier)
                      .markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${context.l10n.markedNotificationsRead} ($count)',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(context, l10n);
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(notificationNotifierProvider.notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _onNotificationTap(context, ref, notification),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.errorLoadingData,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(notificationNotifierProvider.notifier).refresh();
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noNotifications,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noNotificationsDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // Mark as read if unread
    if (!notification.isRead) {
      ref
          .read(notificationNotifierProvider.notifier)
          .markAsRead(notification.id);
    }

    // Navigate to related booking if available
    if (notification.booking != null) {
      context.push('/bookings/${notification.booking}');
    }
  }
}

/// Individual notification tile widget
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        color:
            notification.isRead
                ? null
                : (isDark
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.04)),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIconData(), color: _getIconColor(), size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight:
                                notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        notification.notificationType.localizedName(
                          context.l10n,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getIconColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt, context),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Booking indicator
            if (notification.booking != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (notification.notificationType) {
      case NotificationType.bookingCreated:
        return Icons.add_circle_outline;
      case NotificationType.bookingConfirmed:
        return Icons.check_circle_outline;
      case NotificationType.bookingCancelled:
        return Icons.cancel_outlined;
      case NotificationType.checkinReminder:
        return Icons.login;
      case NotificationType.checkoutReminder:
        return Icons.logout;
      case NotificationType.checkinCompleted:
        return Icons.how_to_reg;
      case NotificationType.checkoutCompleted:
        return Icons.door_front_door_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor() {
    switch (notification.notificationType) {
      case NotificationType.bookingCreated:
        return AppColors.statusBlue; // Blue
      case NotificationType.bookingConfirmed:
        return AppColors.success; // Green
      case NotificationType.bookingCancelled:
        return AppColors.error; // Red
      case NotificationType.checkinReminder:
        return AppColors.warning; // Orange
      case NotificationType.checkoutReminder:
        return AppColors.statusDeepOrange; // Deep Orange
      case NotificationType.checkinCompleted:
        return AppColors.statusTeal; // Teal
      case NotificationType.checkoutCompleted:
        return AppColors.statusBrown; // Brown
      case NotificationType.general:
        return AppColors.statusBlueGrey; // Blue Grey
    }
  }

  String _formatTime(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return context.l10n.justNow;
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${context.l10n.minutesAgo}';
    }
    if (diff.inHours < 24) return '${diff.inHours} ${context.l10n.hoursAgo}';
    if (diff.inDays < 7) return '${diff.inDays} ${context.l10n.daysAgo}';

    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
