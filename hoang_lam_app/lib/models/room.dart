import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.freezed.dart';
part 'room.g.dart';

/// Converter for decimal fields that may come as string or number from the backend
class DecimalToIntConverter implements JsonConverter<int, dynamic> {
  const DecimalToIntConverter();

  @override
  int fromJson(dynamic json) {
    if (json == null) return 0;
    if (json is num) return json.toInt();
    if (json is String) return int.tryParse(json) ?? double.tryParse(json)?.toInt() ?? 0;
    return 0;
  }

  @override
  dynamic toJson(int object) => object;
}

/// Nullable version for optional decimal fields
class NullableDecimalToIntConverter implements JsonConverter<int?, dynamic> {
  const NullableDecimalToIntConverter();

  @override
  int? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is num) return json.toInt();
    if (json is String) return int.tryParse(json) ?? double.tryParse(json)?.toInt();
    return null;
  }

  @override
  dynamic toJson(int? object) => object;
}

/// Room status matching backend Room.Status choices
enum RoomStatus {
  @JsonValue('available')
  available,
  @JsonValue('occupied')
  occupied,
  @JsonValue('cleaning')
  cleaning,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('blocked')
  blocked,
}

/// Extension to get status display names and colors
extension RoomStatusExtension on RoomStatus {
  String get displayName {
    switch (this) {
      case RoomStatus.available:
        return 'Trống';
      case RoomStatus.occupied:
        return 'Có khách';
      case RoomStatus.cleaning:
        return 'Đang dọn';
      case RoomStatus.maintenance:
        return 'Bảo trì';
      case RoomStatus.blocked:
        return 'Khóa';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.cleaning:
        return 'Cleaning';
      case RoomStatus.maintenance:
        return 'Maintenance';
      case RoomStatus.blocked:
        return 'Blocked';
    }
  }

  Color get color {
    switch (this) {
      case RoomStatus.available:
        return const Color(0xFF4CAF50); // Green
      case RoomStatus.occupied:
        return const Color(0xFFF44336); // Red
      case RoomStatus.cleaning:
        return const Color(0xFFFFC107); // Amber
      case RoomStatus.maintenance:
        return const Color(0xFF9E9E9E); // Grey
      case RoomStatus.blocked:
        return const Color(0xFF795548); // Brown
    }
  }

  IconData get icon {
    switch (this) {
      case RoomStatus.available:
        return Icons.check_circle;
      case RoomStatus.occupied:
        return Icons.person;
      case RoomStatus.cleaning:
        return Icons.cleaning_services;
      case RoomStatus.maintenance:
        return Icons.build;
      case RoomStatus.blocked:
        return Icons.block;
    }
  }

  /// Check if room can be booked
  bool get isBookable => this == RoomStatus.available;

  /// Check if status change to 'available' is allowed
  bool get canMarkAvailable {
    return this == RoomStatus.cleaning || this == RoomStatus.blocked;
  }
}

/// RoomType model matching backend RoomTypeSerializer
@freezed
sealed class RoomType with _$RoomType {
  const factory RoomType({
    required int id,
    required String name,
    @JsonKey(name: 'name_en') String? nameEn,
    @DecimalToIntConverter()
    @JsonKey(name: 'base_rate') required int baseRate,
    // Hourly booking fields
    @NullableDecimalToIntConverter()
    @JsonKey(name: 'hourly_rate') int? hourlyRate,
    @NullableDecimalToIntConverter()
    @JsonKey(name: 'first_hour_rate') int? firstHourRate,
    @JsonKey(name: 'allows_hourly') @Default(true) bool allowsHourly,
    @JsonKey(name: 'min_hours') @Default(2) int minHours,
    // Guest capacity
    @JsonKey(name: 'max_guests') @Default(2) int maxGuests,
    String? description,
    @Default([]) List<String> amenities,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'room_count') @Default(0) int roomCount,
    @JsonKey(name: 'available_room_count') @Default(0) int availableRoomCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _RoomType;

  const RoomType._();

  factory RoomType.fromJson(Map<String, dynamic> json) =>
      _$RoomTypeFromJson(json);

  /// Get display name in preferred language
  String displayName(bool useEnglish) {
    return useEnglish && nameEn != null && nameEn!.isNotEmpty ? nameEn! : name;
  }

  /// Get formatted base rate
  String get formattedBaseRate => '${baseRate.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}đ';

  /// Get formatted hourly rate
  String? get formattedHourlyRate {
    if (hourlyRate == null) return null;
    return '${hourlyRate.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ/giờ';
  }
}

/// Room model matching backend RoomSerializer
@freezed
sealed class Room with _$Room {
  const factory Room({
    required int id,
    required String number,
    String? name,
    @JsonKey(name: 'room_type') required int roomTypeId,
    @JsonKey(name: 'room_type_name') String? roomTypeName,
    @JsonKey(name: 'room_type_details') RoomType? roomTypeDetails,
    @Default(1) int floor,
    @Default(RoomStatus.available) RoomStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @Default([]) List<String> amenities,
    String? notes,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @NullableDecimalToIntConverter()
    @JsonKey(name: 'base_rate') int? baseRate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Room;

  const Room._();

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  /// Get display name (room number with optional name)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return '$number - $name';
    }
    return number;
  }

  /// Get status color
  Color get statusColor => status.color;

  /// Check if room is available for booking
  bool get isAvailable => status == RoomStatus.available;

  /// Get formatted base rate from room type
  String get formattedRate {
    final rate = baseRate ?? roomTypeDetails?.baseRate ?? 0;
    return '${rate.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ';
  }
}

/// Room list response matching paginated API response
@freezed
sealed class RoomListResponse with _$RoomListResponse {
  const factory RoomListResponse({
    required int count,
    String? next,
    String? previous,
    required List<Room> results,
  }) = _RoomListResponse;

  factory RoomListResponse.fromJson(Map<String, dynamic> json) =>
      _$RoomListResponseFromJson(json);
}

/// Room type list response matching paginated API response
@freezed
sealed class RoomTypeListResponse with _$RoomTypeListResponse {
  const factory RoomTypeListResponse({
    required int count,
    String? next,
    String? previous,
    required List<RoomType> results,
  }) = _RoomTypeListResponse;

  factory RoomTypeListResponse.fromJson(Map<String, dynamic> json) =>
      _$RoomTypeListResponseFromJson(json);
}

/// Room status update request
@freezed
sealed class RoomStatusUpdateRequest with _$RoomStatusUpdateRequest {
  const factory RoomStatusUpdateRequest({
    required RoomStatus status,
    String? notes,
  }) = _RoomStatusUpdateRequest;

  factory RoomStatusUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$RoomStatusUpdateRequestFromJson(json);
}

/// Room availability check request
@freezed
sealed class RoomAvailabilityRequest with _$RoomAvailabilityRequest {
  const factory RoomAvailabilityRequest({
    @JsonKey(name: 'check_in') required DateTime checkIn,
    @JsonKey(name: 'check_out') required DateTime checkOut,
    @JsonKey(name: 'room_type') int? roomTypeId,
  }) = _RoomAvailabilityRequest;

  factory RoomAvailabilityRequest.fromJson(Map<String, dynamic> json) =>
      _$RoomAvailabilityRequestFromJson(json);
}

/// Room availability check response
@freezed
sealed class RoomAvailabilityResponse with _$RoomAvailabilityResponse {
  const factory RoomAvailabilityResponse({
    @JsonKey(name: 'available_rooms') required List<Room> availableRooms,
    @JsonKey(name: 'total_available') required int totalAvailable,
    @JsonKey(name: 'check_in') required String checkIn,
    @JsonKey(name: 'check_out') required String checkOut,
    @JsonKey(name: 'room_type') int? roomTypeId,
  }) = _RoomAvailabilityResponse;

  factory RoomAvailabilityResponse.fromJson(Map<String, dynamic> json) =>
      _$RoomAvailabilityResponseFromJson(json);
}
