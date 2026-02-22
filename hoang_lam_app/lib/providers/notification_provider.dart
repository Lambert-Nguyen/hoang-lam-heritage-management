import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../repositories/notification_repository.dart';

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// ============================================================
// Notification Providers
// ============================================================

/// Provider for all notifications
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.getNotifications();
  },
);

/// Provider for unread notification count
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});

/// Provider for notification preferences
final notificationPreferencesProvider =
    FutureProvider.autoDispose<NotificationPreferences>((ref) async {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getPreferences();
    });

// ============================================================
// Notification Notifier (for mutations)
// ============================================================

/// StateNotifier for managing notification state and actions
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  /// Load all notifications
  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(int id) async {
    try {
      await _repository.markAsRead(id);
      // Update local state
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.map((n) {
            if (n.id == id) {
              return n.copyWith(isRead: true, readAt: DateTime.now());
            }
            return n;
          }).toList(),
        );
      });
      // Refresh unread count
      _ref.invalidate(unreadNotificationCountProvider);
    } catch (e) {
      // Silently handle - the notification still exists
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final count = await _repository.markAllAsRead();
      // Update local state
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.map((n) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }).toList(),
        );
      });
      // Refresh unread count
      _ref.invalidate(unreadNotificationCountProvider);
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Refresh notifications from backend
  Future<void> refresh() async {
    await loadNotifications();
    _ref.invalidate(unreadNotificationCountProvider);
  }
}

/// Provider for NotificationNotifier
final notificationNotifierProvider = StateNotifierProvider.autoDispose<
  NotificationNotifier,
  AsyncValue<List<AppNotification>>
>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository, ref);
});
