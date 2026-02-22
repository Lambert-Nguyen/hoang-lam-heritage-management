import 'package:freezed_annotation/freezed_annotation.dart';
import '../l10n/app_localizations.dart';

part 'rate_plan.freezed.dart';
part 'rate_plan.g.dart';

/// Converter for decimal fields that may come as string or number from the backend
class DecimalToDoubleConverter implements JsonConverter<double, dynamic> {
  const DecimalToDoubleConverter();

  @override
  double fromJson(dynamic json) {
    if (json == null) return 0.0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0.0;
    return 0.0;
  }

  @override
  dynamic toJson(double object) => object;
}

/// Cancellation policy matching backend RatePlan.CancellationPolicy choices
enum CancellationPolicy {
  @JsonValue('free')
  free,
  @JsonValue('flexible')
  flexible,
  @JsonValue('moderate')
  moderate,
  @JsonValue('strict')
  strict,
  @JsonValue('non_refundable')
  nonRefundable,
}

/// Extension to get policy display names
extension CancellationPolicyExtension on CancellationPolicy {
  String get displayName {
    switch (this) {
      case CancellationPolicy.free:
        return 'Miễn phí hủy';
      case CancellationPolicy.flexible:
        return 'Linh hoạt';
      case CancellationPolicy.moderate:
        return 'Trung bình';
      case CancellationPolicy.strict:
        return 'Nghiêm ngặt';
      case CancellationPolicy.nonRefundable:
        return 'Không hoàn tiền';
    }
  }

  String get displayNameEn {
    switch (this) {
      case CancellationPolicy.free:
        return 'Free Cancellation';
      case CancellationPolicy.flexible:
        return 'Flexible';
      case CancellationPolicy.moderate:
        return 'Moderate';
      case CancellationPolicy.strict:
        return 'Strict';
      case CancellationPolicy.nonRefundable:
        return 'Non-refundable';
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case CancellationPolicy.free:
        return l10n.cancelPolicyFree;
      case CancellationPolicy.flexible:
        return l10n.cancelPolicyFlexible;
      case CancellationPolicy.moderate:
        return l10n.cancelPolicyModerate;
      case CancellationPolicy.strict:
        return l10n.cancelPolicyStrict;
      case CancellationPolicy.nonRefundable:
        return l10n.cancelPolicyNonRefundable;
    }
  }
}

/// RatePlan model for dynamic pricing
@freezed
sealed class RatePlan with _$RatePlan {
  const factory RatePlan({
    required int id,
    required String name,
    @JsonKey(name: 'name_en') String? nameEn,
    @JsonKey(name: 'room_type') required int roomType,
    @JsonKey(name: 'room_type_name') String? roomTypeName,
    @DecimalToDoubleConverter()
    @JsonKey(name: 'base_rate')
    required double baseRate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'min_stay') @Default(1) int minStay,
    @JsonKey(name: 'max_stay') int? maxStay,
    @JsonKey(name: 'advance_booking_days') int? advanceBookingDays,
    @JsonKey(name: 'cancellation_policy')
    @Default(CancellationPolicy.flexible)
    CancellationPolicy cancellationPolicy,
    @JsonKey(name: 'cancellation_policy_display')
    String? cancellationPolicyDisplay,
    @JsonKey(name: 'valid_from') DateTime? validFrom,
    @JsonKey(name: 'valid_to') DateTime? validTo,
    @JsonKey(name: 'blackout_dates') @Default([]) List<String> blackoutDates,
    @Default([]) List<String> channels,
    @Default('') String description,
    @JsonKey(name: 'includes_breakfast') @Default(false) bool includesBreakfast,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _RatePlan;

  factory RatePlan.fromJson(Map<String, dynamic> json) =>
      _$RatePlanFromJson(json);
}

/// RatePlan list item (lightweight)
@freezed
sealed class RatePlanListItem with _$RatePlanListItem {
  const factory RatePlanListItem({
    required int id,
    required String name,
    @JsonKey(name: 'room_type') required int roomType,
    @JsonKey(name: 'room_type_name') String? roomTypeName,
    @DecimalToDoubleConverter()
    @JsonKey(name: 'base_rate')
    required double baseRate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'min_stay') @Default(1) int minStay,
    @JsonKey(name: 'valid_from') DateTime? validFrom,
    @JsonKey(name: 'valid_to') DateTime? validTo,
    @JsonKey(name: 'includes_breakfast') @Default(false) bool includesBreakfast,
  }) = _RatePlanListItem;

  factory RatePlanListItem.fromJson(Map<String, dynamic> json) =>
      _$RatePlanListItemFromJson(json);
}

/// RatePlan create request
@freezed
sealed class RatePlanCreateRequest with _$RatePlanCreateRequest {
  const factory RatePlanCreateRequest({
    required String name,
    @JsonKey(name: 'name_en') String? nameEn,
    @JsonKey(name: 'room_type') required int roomType,
    @JsonKey(name: 'base_rate') required double baseRate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'min_stay') @Default(1) int minStay,
    @JsonKey(name: 'max_stay') int? maxStay,
    @JsonKey(name: 'advance_booking_days') int? advanceBookingDays,
    @JsonKey(name: 'cancellation_policy')
    @Default(CancellationPolicy.flexible)
    CancellationPolicy cancellationPolicy,
    @JsonKey(name: 'valid_from') DateTime? validFrom,
    @JsonKey(name: 'valid_to') DateTime? validTo,
    @JsonKey(name: 'blackout_dates') @Default([]) List<String> blackoutDates,
    @Default([]) List<String> channels,
    @Default('') String description,
    @JsonKey(name: 'includes_breakfast') @Default(false) bool includesBreakfast,
  }) = _RatePlanCreateRequest;

  factory RatePlanCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$RatePlanCreateRequestFromJson(json);
}

/// DateRateOverride model for date-specific pricing
@freezed
sealed class DateRateOverride with _$DateRateOverride {
  const factory DateRateOverride({
    required int id,
    @JsonKey(name: 'room_type') required int roomType,
    @JsonKey(name: 'room_type_name') String? roomTypeName,
    required DateTime date,
    @DecimalToDoubleConverter() required double rate,
    @Default('') String reason,
    @JsonKey(name: 'closed_to_arrival') @Default(false) bool closedToArrival,
    @JsonKey(name: 'closed_to_departure')
    @Default(false)
    bool closedToDeparture,
    @JsonKey(name: 'min_stay') int? minStay,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _DateRateOverride;

  factory DateRateOverride.fromJson(Map<String, dynamic> json) =>
      _$DateRateOverrideFromJson(json);
}

/// DateRateOverride list item (lightweight)
@freezed
sealed class DateRateOverrideListItem with _$DateRateOverrideListItem {
  const factory DateRateOverrideListItem({
    required int id,
    @JsonKey(name: 'room_type') required int roomType,
    @JsonKey(name: 'room_type_name') String? roomTypeName,
    required DateTime date,
    @DecimalToDoubleConverter() required double rate,
    @Default('') String reason,
    @JsonKey(name: 'closed_to_arrival') @Default(false) bool closedToArrival,
    @JsonKey(name: 'closed_to_departure')
    @Default(false)
    bool closedToDeparture,
  }) = _DateRateOverrideListItem;

  factory DateRateOverrideListItem.fromJson(Map<String, dynamic> json) =>
      _$DateRateOverrideListItemFromJson(json);
}

/// DateRateOverride create request
@freezed
sealed class DateRateOverrideCreateRequest
    with _$DateRateOverrideCreateRequest {
  const factory DateRateOverrideCreateRequest({
    @JsonKey(name: 'room_type') required int roomType,
    required DateTime date,
    required double rate,
    @Default('') String reason,
    @JsonKey(name: 'closed_to_arrival') @Default(false) bool closedToArrival,
    @JsonKey(name: 'closed_to_departure')
    @Default(false)
    bool closedToDeparture,
    @JsonKey(name: 'min_stay') int? minStay,
  }) = _DateRateOverrideCreateRequest;

  factory DateRateOverrideCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$DateRateOverrideCreateRequestFromJson(json);
}

/// DateRateOverride bulk create request
@freezed
sealed class DateRateOverrideBulkCreateRequest
    with _$DateRateOverrideBulkCreateRequest {
  const factory DateRateOverrideBulkCreateRequest({
    @JsonKey(name: 'room_type') required int roomType,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    required double rate,
    @Default('') String reason,
    @JsonKey(name: 'closed_to_arrival') @Default(false) bool closedToArrival,
    @JsonKey(name: 'closed_to_departure')
    @Default(false)
    bool closedToDeparture,
    @JsonKey(name: 'min_stay') int? minStay,
  }) = _DateRateOverrideBulkCreateRequest;

  factory DateRateOverrideBulkCreateRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$DateRateOverrideBulkCreateRequestFromJson(json);
}
