import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'booking.dart';
import '../l10n/app_localizations.dart';

part 'group_booking.freezed.dart';
part 'group_booking.g.dart';

// ============================================================
// Group Booking Status Enum
// ============================================================

enum GroupBookingStatus {
  @JsonValue('tentative')
  tentative,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('checked_in')
  checkedIn,
  @JsonValue('checked_out')
  checkedOut,
  @JsonValue('cancelled')
  cancelled,
}

extension GroupBookingStatusX on GroupBookingStatus {
  String get displayName {
    switch (this) {
      case GroupBookingStatus.tentative:
        return 'Đang chờ';
      case GroupBookingStatus.confirmed:
        return 'Đã xác nhận';
      case GroupBookingStatus.checkedIn:
        return 'Đang ở';
      case GroupBookingStatus.checkedOut:
        return 'Đã trả phòng';
      case GroupBookingStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String get displayNameEn {
    switch (this) {
      case GroupBookingStatus.tentative:
        return 'Tentative';
      case GroupBookingStatus.confirmed:
        return 'Confirmed';
      case GroupBookingStatus.checkedIn:
        return 'Checked In';
      case GroupBookingStatus.checkedOut:
        return 'Checked Out';
      case GroupBookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case GroupBookingStatus.tentative:
        return Colors.orange;
      case GroupBookingStatus.confirmed:
        return Colors.blue;
      case GroupBookingStatus.checkedIn:
        return Colors.green;
      case GroupBookingStatus.checkedOut:
        return Colors.grey;
      case GroupBookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case GroupBookingStatus.tentative:
        return Icons.hourglass_empty;
      case GroupBookingStatus.confirmed:
        return Icons.check_circle;
      case GroupBookingStatus.checkedIn:
        return Icons.login;
      case GroupBookingStatus.checkedOut:
        return Icons.logout;
      case GroupBookingStatus.cancelled:
        return Icons.cancel;
    }
  }


  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case GroupBookingStatus.tentative:
        return l10n.groupStatusPending;
      case GroupBookingStatus.confirmed:
        return l10n.groupStatusConfirmed;
      case GroupBookingStatus.checkedIn:
        return l10n.groupStatusCheckedIn;
      case GroupBookingStatus.checkedOut:
        return l10n.groupStatusCheckedOut;
      case GroupBookingStatus.cancelled:
        return l10n.groupStatusCancelled;
    }
  }
}

// ============================================================
// Group Booking Model
// ============================================================

@freezed
sealed class GroupBooking with _$GroupBooking {
  const factory GroupBooking({
    required int id,
    required String name,
    @JsonKey(name: 'contact_name') required String contactName,
    @JsonKey(name: 'contact_phone') required String contactPhone,
    @JsonKey(name: 'contact_email') @Default('') String contactEmail,
    @Default('') String company,
    // Dates
    @JsonKey(name: 'check_in_date') required String checkInDate,
    @JsonKey(name: 'check_out_date') required String checkOutDate,
    @JsonKey(name: 'actual_check_in') String? actualCheckIn,
    @JsonKey(name: 'actual_check_out') String? actualCheckOut,
    int? nights,
    // Room allocation
    @JsonKey(name: 'room_count') required int roomCount,
    @JsonKey(name: 'guest_count') required int guestCount,
    @Default([]) List<int> rooms,
    @JsonKey(name: 'room_numbers') @Default([]) List<String> roomNumbers,
    // Pricing
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'deposit_amount') @Default(0) double depositAmount,
    @JsonKey(name: 'deposit_paid') @Default(false) bool depositPaid,
    @JsonKey(name: 'special_rate') double? specialRate,
    @JsonKey(name: 'discount_percent') @Default(0) double discountPercent,
    @Default('VND') String currency,
    @JsonKey(name: 'balance_due') double? balanceDue,
    // Status
    required GroupBookingStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @Default(BookingSource.phone) BookingSource source,
    @JsonKey(name: 'source_display') String? sourceDisplay,
    // Notes
    @Default('') String notes,
    @JsonKey(name: 'special_requests') @Default('') String specialRequests,
    // Audit
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_name') String? createdByName,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _GroupBooking;

  factory GroupBooking.fromJson(Map<String, dynamic> json) =>
      _$GroupBookingFromJson(json);
}

// Helper extension for GroupBooking
extension GroupBookingX on GroupBooking {
  /// Calculate balance due if not provided by API
  double get calculatedBalanceDue {
    return balanceDue ?? (totalAmount - depositAmount);
  }

  /// Calculate nights if not provided by API
  int get calculatedNights {
    if (nights != null) return nights!;
    try {
      final checkIn = DateTime.parse(checkInDate);
      final checkOut = DateTime.parse(checkOutDate);
      return checkOut.difference(checkIn).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Check if group can be confirmed
  bool get canConfirm => status == GroupBookingStatus.tentative;

  /// Check if group can check in
  bool get canCheckIn =>
      status == GroupBookingStatus.tentative ||
      status == GroupBookingStatus.confirmed;

  /// Check if group can check out
  bool get canCheckOut => status == GroupBookingStatus.checkedIn;

  /// Check if group can be cancelled
  bool get canCancel =>
      status != GroupBookingStatus.checkedOut &&
      status != GroupBookingStatus.cancelled;
}

// ============================================================
// Group Booking Create Model
// ============================================================

@freezed
sealed class GroupBookingCreate with _$GroupBookingCreate {
  const factory GroupBookingCreate({
    required String name,
    @JsonKey(name: 'contact_name') required String contactName,
    @JsonKey(name: 'contact_phone') required String contactPhone,
    @JsonKey(name: 'contact_email') @Default('') String contactEmail,
    @Default('') String company,
    // Dates
    @JsonKey(name: 'check_in_date') required String checkInDate,
    @JsonKey(name: 'check_out_date') required String checkOutDate,
    // Room allocation
    @JsonKey(name: 'room_count') required int roomCount,
    @JsonKey(name: 'guest_count') required int guestCount,
    @Default([]) List<int> rooms,
    // Pricing
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'deposit_amount') @Default(0) double depositAmount,
    @JsonKey(name: 'deposit_paid') @Default(false) bool depositPaid,
    @JsonKey(name: 'special_rate') double? specialRate,
    @JsonKey(name: 'discount_percent') @Default(0) double discountPercent,
    @Default('VND') String currency,
    // Source
    @Default(BookingSource.phone) BookingSource source,
    // Notes
    @Default('') String notes,
    @JsonKey(name: 'special_requests') @Default('') String specialRequests,
  }) = _GroupBookingCreate;

  factory GroupBookingCreate.fromJson(Map<String, dynamic> json) =>
      _$GroupBookingCreateFromJson(json);
}

// ============================================================
// Group Booking Update Model
// ============================================================

@freezed
sealed class GroupBookingUpdate with _$GroupBookingUpdate {
  const factory GroupBookingUpdate({
    String? name,
    @JsonKey(name: 'contact_name') String? contactName,
    @JsonKey(name: 'contact_phone') String? contactPhone,
    @JsonKey(name: 'contact_email') String? contactEmail,
    String? company,
    // Dates
    @JsonKey(name: 'check_in_date') String? checkInDate,
    @JsonKey(name: 'check_out_date') String? checkOutDate,
    // Room allocation
    @JsonKey(name: 'room_count') int? roomCount,
    @JsonKey(name: 'guest_count') int? guestCount,
    List<int>? rooms,
    // Pricing
    @JsonKey(name: 'total_amount') double? totalAmount,
    @JsonKey(name: 'deposit_amount') double? depositAmount,
    @JsonKey(name: 'deposit_paid') bool? depositPaid,
    @JsonKey(name: 'special_rate') double? specialRate,
    @JsonKey(name: 'discount_percent') double? discountPercent,
    // Status
    GroupBookingStatus? status,
    // Notes
    String? notes,
    @JsonKey(name: 'special_requests') String? specialRequests,
  }) = _GroupBookingUpdate;

  factory GroupBookingUpdate.fromJson(Map<String, dynamic> json) =>
      _$GroupBookingUpdateFromJson(json);
}
