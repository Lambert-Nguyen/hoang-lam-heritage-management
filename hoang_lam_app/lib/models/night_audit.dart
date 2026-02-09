import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'night_audit.freezed.dart';
part 'night_audit.g.dart';

/// Converter that handles both num and String values from the API
/// Django's DecimalField serializes as strings, but we want doubles
class _StringOrNumToDouble implements JsonConverter<double, dynamic> {
  const _StringOrNumToDouble();

  @override
  double fromJson(dynamic json) {
    if (json == null) return 0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0;
    return 0;
  }

  @override
  dynamic toJson(double object) => object;
}

/// Night Audit status enum
enum NightAuditStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('completed')
  completed,
  @JsonValue('closed')
  closed;

  String get displayName {
    switch (this) {
      case NightAuditStatus.draft:
        return 'Nháp';
      case NightAuditStatus.completed:
        return 'Hoàn thành';
      case NightAuditStatus.closed:
        return 'Đã đóng';
    }
  }

  Color get color {
    switch (this) {
      case NightAuditStatus.draft:
        return Colors.orange;
      case NightAuditStatus.completed:
        return Colors.blue;
      case NightAuditStatus.closed:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case NightAuditStatus.draft:
        return Icons.edit_note;
      case NightAuditStatus.completed:
        return Icons.check_circle_outline;
      case NightAuditStatus.closed:
        return Icons.lock;
    }
  }
}

/// Night Audit model - Full detail
@freezed
sealed class NightAudit with _$NightAudit {
  const NightAudit._();

  const factory NightAudit({
    required int id,
    @JsonKey(name: 'audit_date') required DateTime auditDate,
    required NightAuditStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    // Room statistics
    @JsonKey(name: 'total_rooms') @Default(0) int totalRooms,
    @JsonKey(name: 'rooms_occupied') @Default(0) int roomsOccupied,
    @JsonKey(name: 'rooms_available') @Default(0) int roomsAvailable,
    @JsonKey(name: 'rooms_cleaning') @Default(0) int roomsCleaning,
    @JsonKey(name: 'rooms_maintenance') @Default(0) int roomsMaintenance,
    @_StringOrNumToDouble() @JsonKey(name: 'occupancy_rate') @Default(0) double occupancyRate,
    // Booking statistics
    @JsonKey(name: 'check_ins_today') @Default(0) int checkInsToday,
    @JsonKey(name: 'check_outs_today') @Default(0) int checkOutsToday,
    @JsonKey(name: 'no_shows') @Default(0) int noShows,
    @Default(0) int cancellations,
    @JsonKey(name: 'new_bookings') @Default(0) int newBookings,
    // Financial summary
    @_StringOrNumToDouble() @JsonKey(name: 'total_income') @Default(0) double totalIncome,
    @_StringOrNumToDouble() @JsonKey(name: 'room_revenue') @Default(0) double roomRevenue,
    @_StringOrNumToDouble() @JsonKey(name: 'other_revenue') @Default(0) double otherRevenue,
    @_StringOrNumToDouble() @JsonKey(name: 'total_expense') @Default(0) double totalExpense,
    @_StringOrNumToDouble() @JsonKey(name: 'net_revenue') @Default(0) double netRevenue,
    // Payment breakdown
    @_StringOrNumToDouble() @JsonKey(name: 'cash_collected') @Default(0) double cashCollected,
    @_StringOrNumToDouble() @JsonKey(name: 'bank_transfer_collected') @Default(0) double bankTransferCollected,
    @_StringOrNumToDouble() @JsonKey(name: 'momo_collected') @Default(0) double momoCollected,
    @_StringOrNumToDouble() @JsonKey(name: 'other_payments') @Default(0) double otherPayments,
    // Outstanding
    @_StringOrNumToDouble() @JsonKey(name: 'pending_payments') @Default(0) double pendingPayments,
    @JsonKey(name: 'unpaid_bookings_count') @Default(0) int unpaidBookingsCount,
    // Notes
    @Default('') String notes,
    // Audit info
    @JsonKey(name: 'performed_by') int? performedBy,
    @JsonKey(name: 'performed_by_name') String? performedByName,
    @JsonKey(name: 'performed_at') DateTime? performedAt,
    @JsonKey(name: 'closed_by') int? closedBy,
    @JsonKey(name: 'closed_by_name') String? closedByName,
    @JsonKey(name: 'closed_at') DateTime? closedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _NightAudit;

  factory NightAudit.fromJson(Map<String, dynamic> json) =>
      _$NightAuditFromJson(json);
}

/// Night Audit list item (lightweight)
@freezed
sealed class NightAuditListItem with _$NightAuditListItem {
  const factory NightAuditListItem({
    required int id,
    @JsonKey(name: 'audit_date') required DateTime auditDate,
    required NightAuditStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @JsonKey(name: 'total_rooms') @Default(0) int totalRooms,
    @JsonKey(name: 'rooms_occupied') @Default(0) int roomsOccupied,
    @_StringOrNumToDouble() @JsonKey(name: 'occupancy_rate') @Default(0) double occupancyRate,
    @_StringOrNumToDouble() @JsonKey(name: 'total_income') @Default(0) double totalIncome,
    @_StringOrNumToDouble() @JsonKey(name: 'total_expense') @Default(0) double totalExpense,
    @_StringOrNumToDouble() @JsonKey(name: 'net_revenue') @Default(0) double netRevenue,
    @JsonKey(name: 'performed_by_name') String? performedByName,
    @JsonKey(name: 'performed_at') DateTime? performedAt,
  }) = _NightAuditListItem;

  factory NightAuditListItem.fromJson(Map<String, dynamic> json) =>
      _$NightAuditListItemFromJson(json);
}

/// Request to create a night audit
@freezed
sealed class NightAuditRequest with _$NightAuditRequest {
  const factory NightAuditRequest({
    @JsonKey(name: 'audit_date') required DateTime auditDate,
    @Default('') String notes,
  }) = _NightAuditRequest;

  factory NightAuditRequest.fromJson(Map<String, dynamic> json) =>
      _$NightAuditRequestFromJson(json);
}

/// Extension for NightAudit helpers
extension NightAuditExtension on NightAudit {
  /// Whether this audit can be edited
  bool get canEdit => status != NightAuditStatus.closed;

  /// Whether this audit can be closed
  bool get canClose => status != NightAuditStatus.closed;

  /// Format occupancy rate as percentage string
  String get occupancyRateFormatted => '${occupancyRate.toStringAsFixed(1)}%';

  /// Get total payments collected
  double get totalPaymentsCollected =>
      cashCollected + bankTransferCollected + momoCollected + otherPayments;
}
