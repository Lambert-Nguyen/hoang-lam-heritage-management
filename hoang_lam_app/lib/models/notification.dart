import 'package:freezed_annotation/freezed_annotation.dart';
import '../l10n/app_localizations.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

// ============================================================
// Notification Type Enum
// ============================================================

/// Notification type matching backend Notification.NotificationType choices
enum NotificationType {
  @JsonValue('booking_created')
  bookingCreated,
  @JsonValue('booking_confirmed')
  bookingConfirmed,
  @JsonValue('booking_cancelled')
  bookingCancelled,
  @JsonValue('checkin_reminder')
  checkinReminder,
  @JsonValue('checkout_reminder')
  checkoutReminder,
  @JsonValue('checkin_completed')
  checkinCompleted,
  @JsonValue('checkout_completed')
  checkoutCompleted,
  @JsonValue('general')
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.bookingCreated:
        return 'Đặt phòng mới';
      case NotificationType.bookingConfirmed:
        return 'Xác nhận đặt phòng';
      case NotificationType.bookingCancelled:
        return 'Hủy đặt phòng';
      case NotificationType.checkinReminder:
        return 'Nhắc nhận phòng';
      case NotificationType.checkoutReminder:
        return 'Nhắc trả phòng';
      case NotificationType.checkinCompleted:
        return 'Đã nhận phòng';
      case NotificationType.checkoutCompleted:
        return 'Đã trả phòng';
      case NotificationType.general:
        return 'Thông báo chung';
    }
  }

  String get displayNameEn {
    switch (this) {
      case NotificationType.bookingCreated:
        return 'New Booking';
      case NotificationType.bookingConfirmed:
        return 'Booking Confirmed';
      case NotificationType.bookingCancelled:
        return 'Booking Cancelled';
      case NotificationType.checkinReminder:
        return 'Check-in Reminder';
      case NotificationType.checkoutReminder:
        return 'Check-out Reminder';
      case NotificationType.checkinCompleted:
        return 'Check-in Completed';
      case NotificationType.checkoutCompleted:
        return 'Check-out Completed';
      case NotificationType.general:
        return 'General';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.bookingCreated:
        return 'add_circle';
      case NotificationType.bookingConfirmed:
        return 'check_circle';
      case NotificationType.bookingCancelled:
        return 'cancel';
      case NotificationType.checkinReminder:
        return 'login';
      case NotificationType.checkoutReminder:
        return 'logout';
      case NotificationType.checkinCompleted:
        return 'how_to_reg';
      case NotificationType.checkoutCompleted:
        return 'door_front';
      case NotificationType.general:
        return 'notifications';
    }
  }


  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case NotificationType.bookingCreated:
        return l10n.notificationTypeNewBooking;
      case NotificationType.bookingConfirmed:
        return l10n.notificationTypeBookingConfirmed;
      case NotificationType.bookingCancelled:
        return l10n.notificationTypeBookingCancelled;
      case NotificationType.checkinReminder:
        return l10n.notificationTypeCheckinReminder;
      case NotificationType.checkoutReminder:
        return l10n.notificationTypeCheckoutReminder;
      case NotificationType.checkinCompleted:
        return l10n.notificationTypeCheckedIn;
      case NotificationType.checkoutCompleted:
        return l10n.notificationTypeCheckedOut;
      case NotificationType.general:
        return l10n.notificationTypeGeneral;
    }
  }
}

// ============================================================
// Notification Model
// ============================================================

@freezed
sealed class AppNotification with _$AppNotification {
  const factory AppNotification({
    required int id,
    @JsonKey(name: 'notification_type') required NotificationType notificationType,
    @JsonKey(name: 'notification_type_display') String? notificationTypeDisplay,
    required String title,
    required String body,
    @Default({}) Map<String, dynamic> data,
    int? booking,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'read_at') DateTime? readAt,
    @JsonKey(name: 'is_sent') @Default(false) bool isSent,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

// ============================================================
// Notification List Response (paginated)
// ============================================================

@freezed
sealed class NotificationListResponse with _$NotificationListResponse {
  const factory NotificationListResponse({
    required int count,
    String? next,
    String? previous,
    required List<AppNotification> results,
  }) = _NotificationListResponse;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResponseFromJson(json);
}

// ============================================================
// Device Token Registration
// ============================================================

@freezed
sealed class DeviceTokenRequest with _$DeviceTokenRequest {
  const factory DeviceTokenRequest({
    required String token,
    @Default('android') String platform,
    @JsonKey(name: 'device_name') @Default('') String deviceName,
  }) = _DeviceTokenRequest;

  factory DeviceTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenRequestFromJson(json);
}

// ============================================================
// Notification Preferences
// ============================================================

@freezed
sealed class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @JsonKey(name: 'receive_notifications') @Default(true) bool receiveNotifications,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
}
