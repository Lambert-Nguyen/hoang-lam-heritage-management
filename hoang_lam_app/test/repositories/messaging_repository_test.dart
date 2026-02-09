import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/guest_message.dart';

void main() {
  group('MessageChannel', () {
    test('all channels have display names', () {
      for (final channel in MessageChannel.values) {
        expect(channel.displayName, isNotEmpty);
        expect(channel.apiValue, isNotEmpty);
      }
    });

    test('SMS channel', () {
      expect(MessageChannel.sms.displayName, 'SMS');
      expect(MessageChannel.sms.apiValue, 'sms');
    });

    test('Email channel', () {
      expect(MessageChannel.email.displayName, 'Email');
    });

    test('Zalo channel', () {
      expect(MessageChannel.zalo.displayName, 'Zalo');
    });
  });

  group('MessageStatus', () {
    test('all statuses have display names', () {
      for (final status in MessageStatus.values) {
        expect(status.displayName, isNotEmpty);
        expect(status.displayNameEn, isNotEmpty);
      }
    });

    test('sent status', () {
      expect(MessageStatus.sent.displayName, 'Đã gửi');
      expect(MessageStatus.sent.displayNameEn, 'Sent');
    });

    test('failed status', () {
      expect(MessageStatus.failed.displayName, 'Thất bại');
    });
  });

  group('MessageTemplateType', () {
    test('all types have display names', () {
      for (final type in MessageTemplateType.values) {
        expect(type.displayName, isNotEmpty);
        expect(type.displayNameEn, isNotEmpty);
      }
    });

    test('booking confirmation type', () {
      expect(
        MessageTemplateType.bookingConfirmation.displayName,
        'Xác nhận đặt phòng',
      );
    });
  });

  group('MessageTemplate model', () {
    test('creates from JSON', () {
      final json = {
        'id': 1,
        'name': 'Booking Confirmation SMS',
        'template_type': 'booking_confirmation',
        'template_type_display': 'Xác nhận đặt phòng',
        'subject': 'Xác nhận #{room_number}',
        'body': 'Chào {guest_name}',
        'channel': 'sms',
        'is_active': true,
        'available_variables': ['guest_name', 'room_number'],
        'created_at': '2026-01-15T10:00:00Z',
        'updated_at': '2026-01-15T10:00:00Z',
      };

      final template = MessageTemplate.fromJson(json);
      expect(template.id, 1);
      expect(template.name, 'Booking Confirmation SMS');
      expect(template.templateType, MessageTemplateType.bookingConfirmation);
      expect(template.channel, MessageChannel.sms);
      expect(template.isActive, true);
      expect(template.availableVariables, contains('guest_name'));
    });

    test('serializes to JSON', () {
      const template = MessageTemplate(
        id: 1,
        name: 'Test Template',
        templateType: MessageTemplateType.custom,
        subject: 'Test',
        body: 'Body',
        channel: MessageChannel.email,
      );

      final json = template.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Test Template');
      expect(json['template_type'], 'custom');
      expect(json['channel'], 'email');
    });
  });

  group('GuestMessage model', () {
    test('creates from JSON', () {
      final json = {
        'id': 1,
        'guest': 10,
        'guest_name': 'Nguyễn Văn A',
        'booking': 5,
        'booking_display': '#5 - 101',
        'template': 1,
        'template_name': 'Booking Confirmation',
        'channel': 'sms',
        'channel_display': 'SMS',
        'subject': 'Xác nhận đặt phòng',
        'body': 'Chào Nguyễn Văn A',
        'recipient_address': '0901234567',
        'status': 'sent',
        'status_display': 'Đã gửi',
        'sent_at': '2026-01-15T10:30:00Z',
        'send_error': '',
        'sent_by': 1,
        'sent_by_name': 'Owner',
        'created_at': '2026-01-15T10:00:00Z',
      };

      final message = GuestMessage.fromJson(json);
      expect(message.id, 1);
      expect(message.guest, 10);
      expect(message.guestName, 'Nguyễn Văn A');
      expect(message.booking, 5);
      expect(message.channel, MessageChannel.sms);
      expect(message.status, MessageStatus.sent);
      expect(message.recipientAddress, '0901234567');
      expect(message.sentAt, isNotNull);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 2,
        'guest': 10,
        'channel': 'email',
        'subject': 'Test',
        'body': 'Test body',
        'status': 'draft',
      };

      final message = GuestMessage.fromJson(json);
      expect(message.booking, isNull);
      expect(message.template, isNull);
      expect(message.sentAt, isNull);
      expect(message.sendError, '');
    });
  });

  group('SendMessageRequest model', () {
    test('creates and serializes', () {
      const request = SendMessageRequest(
        guest: 1,
        booking: 5,
        template: 2,
        channel: MessageChannel.sms,
        subject: 'Test',
        body: 'Body',
      );

      final json = request.toJson();
      expect(json['guest'], 1);
      expect(json['booking'], 5);
      expect(json['template'], 2);
      expect(json['channel'], 'sms');
    });
  });

  group('PreviewMessageResponse model', () {
    test('creates from JSON', () {
      final json = {
        'subject': 'Rendered Subject',
        'body': 'Rendered body with Nguyễn Văn A',
        'recipient_address': '0901234567',
        'channel': 'sms',
      };

      final response = PreviewMessageResponse.fromJson(json);
      expect(response.subject, 'Rendered Subject');
      expect(response.body, contains('Nguyễn Văn A'));
      expect(response.recipientAddress, '0901234567');
      expect(response.channel, MessageChannel.sms);
    });
  });

  group('GuestMessageListResponse model', () {
    test('parses paginated response', () {
      final json = {
        'count': 1,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 1,
            'guest': 10,
            'channel': 'sms',
            'subject': 'Test',
            'body': 'Body',
            'status': 'sent',
          },
        ],
      };

      final response = GuestMessageListResponse.fromJson(json);
      expect(response.count, 1);
      expect(response.results.length, 1);
    });
  });
}
