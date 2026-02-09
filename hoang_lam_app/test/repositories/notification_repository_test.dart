import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/notification.dart';

void main() {
  group('NotificationType', () {
    test('all notification types have display names', () {
      for (final type in NotificationType.values) {
        expect(type.displayName, isNotEmpty);
        expect(type.displayNameEn, isNotEmpty);
        expect(type.icon, isNotEmpty);
      }
    });

    test('booking_created type', () {
      expect(NotificationType.bookingCreated.displayName, 'Đặt phòng mới');
      expect(NotificationType.bookingCreated.displayNameEn, 'New Booking');
    });

    test('checkout_reminder type', () {
      expect(NotificationType.checkoutReminder.displayName, 'Nhắc trả phòng');
    });
  });

  group('AppNotification model', () {
    test('creates from JSON', () {
      final json = {
        'id': 1,
        'notification_type': 'booking_created',
        'notification_type_display': 'Đặt phòng mới',
        'title': 'Đặt phòng mới #123',
        'body': 'Phòng 101 đã được đặt.',
        'data': {'booking_id': 123},
        'booking': 123,
        'is_read': false,
        'read_at': null,
        'is_sent': true,
        'created_at': '2026-01-15T10:00:00Z',
      };

      final notification = AppNotification.fromJson(json);
      expect(notification.id, 1);
      expect(notification.notificationType, NotificationType.bookingCreated);
      expect(notification.title, 'Đặt phòng mới #123');
      expect(notification.body, 'Phòng 101 đã được đặt.');
      expect(notification.booking, 123);
      expect(notification.isRead, false);
      expect(notification.isSent, true);
    });

    test('serializes to JSON', () {
      const notification = AppNotification(
        id: 1,
        notificationType: NotificationType.general,
        title: 'Test',
        body: 'Test body',
      );

      final json = notification.toJson();
      expect(json['id'], 1);
      expect(json['notification_type'], 'general');
      expect(json['title'], 'Test');
    });

    test('copyWith works', () {
      const notification = AppNotification(
        id: 1,
        notificationType: NotificationType.general,
        title: 'Test',
        body: 'Test body',
        isRead: false,
      );

      final read = notification.copyWith(isRead: true, readAt: DateTime.now());
      expect(read.isRead, true);
      expect(read.readAt, isNotNull);
      expect(read.id, 1); // unchanged
    });

    test('handles null optional fields', () {
      final json = {
        'id': 2,
        'notification_type': 'general',
        'title': 'Simple',
        'body': 'Simple body',
      };

      final notification = AppNotification.fromJson(json);
      expect(notification.booking, isNull);
      expect(notification.readAt, isNull);
      expect(notification.data, isEmpty);
    });
  });

  group('NotificationListResponse model', () {
    test('parses paginated response', () {
      final json = {
        'count': 2,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 1,
            'notification_type': 'booking_created',
            'title': 'Notification 1',
            'body': 'Body 1',
          },
          {
            'id': 2,
            'notification_type': 'general',
            'title': 'Notification 2',
            'body': 'Body 2',
          },
        ],
      };

      final response = NotificationListResponse.fromJson(json);
      expect(response.count, 2);
      expect(response.results.length, 2);
      expect(response.results[0].id, 1);
      expect(response.results[1].id, 2);
    });
  });

  group('DeviceTokenRequest model', () {
    test('creates and serializes', () {
      const request = DeviceTokenRequest(
        token: 'fcm-token-123',
        platform: 'ios',
        deviceName: 'iPhone 15',
      );

      final json = request.toJson();
      expect(json['token'], 'fcm-token-123');
      expect(json['platform'], 'ios');
      expect(json['device_name'], 'iPhone 15');
    });

    test('defaults to android', () {
      const request = DeviceTokenRequest(token: 'test');
      expect(request.platform, 'android');
    });
  });

  group('NotificationPreferences model', () {
    test('creates from JSON', () {
      final json = {'receive_notifications': true};
      final prefs = NotificationPreferences.fromJson(json);
      expect(prefs.receiveNotifications, true);
    });

    test('defaults to true', () {
      const prefs = NotificationPreferences();
      expect(prefs.receiveNotifications, true);
    });
  });
}
