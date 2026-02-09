import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/notification.dart';

/// Repository for notification operations
class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==================== Notifications ====================

  /// Get all notifications for the current user
  Future<List<AppNotification>> getNotifications() async {
    final response = await _apiClient.get<dynamic>(
      AppConstants.notificationsEndpoint,
    );

    if (response.data == null) {
      return [];
    }

    // Handle paginated response
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = NotificationListResponse.fromJson(dataMap);
        return listResponse.results;
      }
    }

    // Handle non-paginated response
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get a single notification by ID
  Future<AppNotification> getNotification(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.notificationsEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Notification not found');
    }
    return AppNotification.fromJson(response.data!);
  }

  /// Mark a notification as read
  Future<AppNotification> markAsRead(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.notificationsEndpoint}$id/read/',
    );
    if (response.data == null) {
      throw Exception('Failed to mark notification as read');
    }
    return AppNotification.fromJson(response.data!);
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.notificationsEndpoint}read-all/',
    );
    return (response.data?['marked_read'] as int?) ?? 0;
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.notificationsEndpoint}unread-count/',
    );
    return (response.data?['unread_count'] as int?) ?? 0;
  }

  // ==================== Device Token ====================

  /// Register a device token for push notifications
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String deviceName = '',
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      AppConstants.deviceTokenEndpoint,
      data: {
        'token': token,
        'platform': platform,
        'device_name': deviceName,
      },
    );
  }

  /// Unregister a device token
  Future<void> unregisterDeviceToken(String token) async {
    await _apiClient.delete<Map<String, dynamic>>(
      AppConstants.deviceTokenEndpoint,
      data: {'token': token},
    );
  }

  // ==================== Preferences ====================

  /// Get notification preferences from backend
  Future<NotificationPreferences> getPreferences() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      AppConstants.notificationPreferencesEndpoint,
    );
    if (response.data == null) {
      return const NotificationPreferences();
    }
    return NotificationPreferences.fromJson(response.data!);
  }

  /// Update notification preferences on backend
  Future<NotificationPreferences> updatePreferences({
    required bool receiveNotifications,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      AppConstants.notificationPreferencesEndpoint,
      data: {'receive_notifications': receiveNotifications},
    );
    if (response.data == null) {
      throw Exception('Failed to update preferences');
    }
    return NotificationPreferences.fromJson(response.data!);
  }
}
