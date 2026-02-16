import 'package:freezed_annotation/freezed_annotation.dart';
import '../l10n/app_localizations.dart';

part 'guest_message.freezed.dart';
part 'guest_message.g.dart';

// ============================================================
// Message Channel Enum
// ============================================================

/// Message channel matching backend GuestMessage.Channel choices
enum MessageChannel {
  @JsonValue('sms')
  sms,
  @JsonValue('email')
  email,
  @JsonValue('zalo')
  zalo,
}

extension MessageChannelExtension on MessageChannel {
  String get displayName {
    switch (this) {
      case MessageChannel.sms:
        return 'SMS';
      case MessageChannel.email:
        return 'Email';
      case MessageChannel.zalo:
        return 'Zalo';
    }
  }

  String get apiValue {
    switch (this) {
      case MessageChannel.sms:
        return 'sms';
      case MessageChannel.email:
        return 'email';
      case MessageChannel.zalo:
        return 'zalo';
    }
  }
}

// ============================================================
// Message Status Enum
// ============================================================

enum MessageStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('pending')
  pending,
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('failed')
  failed,
}

extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.draft:
        return 'Nháp';
      case MessageStatus.pending:
        return 'Đang gửi';
      case MessageStatus.sent:
        return 'Đã gửi';
      case MessageStatus.delivered:
        return 'Đã nhận';
      case MessageStatus.failed:
        return 'Thất bại';
    }
  }

  String get displayNameEn {
    switch (this) {
      case MessageStatus.draft:
        return 'Draft';
      case MessageStatus.pending:
        return 'Pending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.failed:
        return 'Failed';
    }
  }


  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case MessageStatus.draft:
        return l10n.messageStatusDraft;
      case MessageStatus.pending:
        return l10n.messageStatusSending;
      case MessageStatus.sent:
        return l10n.messageStatusSent;
      case MessageStatus.delivered:
        return l10n.messageStatusDelivered;
      case MessageStatus.failed:
        return l10n.messageStatusFailed;
    }
  }
}

// ============================================================
// Message Template Type Enum
// ============================================================

enum MessageTemplateType {
  @JsonValue('booking_confirmation')
  bookingConfirmation,
  @JsonValue('pre_arrival')
  preArrival,
  @JsonValue('checkout_reminder')
  checkoutReminder,
  @JsonValue('review_request')
  reviewRequest,
  @JsonValue('custom')
  custom,
}

extension MessageTemplateTypeExtension on MessageTemplateType {
  String get displayName {
    switch (this) {
      case MessageTemplateType.bookingConfirmation:
        return 'Xác nhận đặt phòng';
      case MessageTemplateType.preArrival:
        return 'Thông tin trước khi đến';
      case MessageTemplateType.checkoutReminder:
        return 'Nhắc trả phòng';
      case MessageTemplateType.reviewRequest:
        return 'Yêu cầu đánh giá';
      case MessageTemplateType.custom:
        return 'Tùy chỉnh';
    }
  }

  String get displayNameEn {
    switch (this) {
      case MessageTemplateType.bookingConfirmation:
        return 'Booking Confirmation';
      case MessageTemplateType.preArrival:
        return 'Pre-Arrival Info';
      case MessageTemplateType.checkoutReminder:
        return 'Check-out Reminder';
      case MessageTemplateType.reviewRequest:
        return 'Review Request';
      case MessageTemplateType.custom:
        return 'Custom';
    }
  }


  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case MessageTemplateType.bookingConfirmation:
        return l10n.msgTemplateBookingConfirm;
      case MessageTemplateType.preArrival:
        return l10n.msgTemplatePreArrival;
      case MessageTemplateType.checkoutReminder:
        return l10n.msgTemplateCheckoutReminder;
      case MessageTemplateType.reviewRequest:
        return l10n.msgTemplateReviewRequest;
      case MessageTemplateType.custom:
        return l10n.msgTemplateCustom;
    }
  }
}

// ============================================================
// Message Template Model
// ============================================================

@freezed
sealed class MessageTemplate with _$MessageTemplate {
  const factory MessageTemplate({
    required int id,
    required String name,
    @JsonKey(name: 'template_type') required MessageTemplateType templateType,
    @JsonKey(name: 'template_type_display') String? templateTypeDisplay,
    required String subject,
    required String body,
    required MessageChannel channel,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'available_variables') @Default([]) List<String> availableVariables,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MessageTemplate;

  factory MessageTemplate.fromJson(Map<String, dynamic> json) =>
      _$MessageTemplateFromJson(json);
}

// ============================================================
// Guest Message Model
// ============================================================

@freezed
sealed class GuestMessage with _$GuestMessage {
  const factory GuestMessage({
    required int id,
    required int guest,
    @JsonKey(name: 'guest_name') String? guestName,
    int? booking,
    @JsonKey(name: 'booking_display') String? bookingDisplay,
    int? template,
    @JsonKey(name: 'template_name') String? templateName,
    required MessageChannel channel,
    @JsonKey(name: 'channel_display') String? channelDisplay,
    required String subject,
    required String body,
    required MessageStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @JsonKey(name: 'recipient_address') String? recipientAddress,
    @JsonKey(name: 'sent_at') DateTime? sentAt,
    @JsonKey(name: 'send_error') @Default('') String sendError,
    @JsonKey(name: 'sent_by') int? sentBy,
    @JsonKey(name: 'sent_by_name') String? sentByName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _GuestMessage;

  factory GuestMessage.fromJson(Map<String, dynamic> json) =>
      _$GuestMessageFromJson(json);
}

// ============================================================
// Guest Message List Response (paginated)
// ============================================================

@freezed
sealed class GuestMessageListResponse with _$GuestMessageListResponse {
  const factory GuestMessageListResponse({
    required int count,
    String? next,
    String? previous,
    required List<GuestMessage> results,
  }) = _GuestMessageListResponse;

  factory GuestMessageListResponse.fromJson(Map<String, dynamic> json) =>
      _$GuestMessageListResponseFromJson(json);
}

// ============================================================
// Message Template List Response (paginated)
// ============================================================

@freezed
sealed class MessageTemplateListResponse with _$MessageTemplateListResponse {
  const factory MessageTemplateListResponse({
    required int count,
    String? next,
    String? previous,
    required List<MessageTemplate> results,
  }) = _MessageTemplateListResponse;

  factory MessageTemplateListResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageTemplateListResponseFromJson(json);
}

// ============================================================
// Send Message Request
// ============================================================

@freezed
sealed class SendMessageRequest with _$SendMessageRequest {
  const factory SendMessageRequest({
    required int guest,
    int? booking,
    int? template,
    required MessageChannel channel,
    required String subject,
    required String body,
  }) = _SendMessageRequest;

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);
}

// ============================================================
// Preview Message Request
// ============================================================

@freezed
sealed class PreviewMessageRequest with _$PreviewMessageRequest {
  const factory PreviewMessageRequest({
    required int template,
    required int guest,
    int? booking,
  }) = _PreviewMessageRequest;

  factory PreviewMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$PreviewMessageRequestFromJson(json);
}

// ============================================================
// Preview Message Response
// ============================================================

@freezed
sealed class PreviewMessageResponse with _$PreviewMessageResponse {
  const factory PreviewMessageResponse({
    required String subject,
    required String body,
    @JsonKey(name: 'recipient_address') String? recipientAddress,
    required MessageChannel channel,
  }) = _PreviewMessageResponse;

  factory PreviewMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$PreviewMessageResponseFromJson(json);
}
