import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest.freezed.dart';
part 'guest.g.dart';

/// Guest ID type matching backend Guest.IDType choices
enum IDType {
  @JsonValue('cccd')
  cccd,
  @JsonValue('passport')
  passport,
  @JsonValue('cmnd')
  cmnd,
  @JsonValue('gplx')
  gplx,
  @JsonValue('other')
  other,
}

/// Extension to get ID type display names
extension IDTypeExtension on IDType {
  String get displayName {
    switch (this) {
      case IDType.cccd:
        return 'CCCD';
      case IDType.passport:
        return 'Hộ chiếu';
      case IDType.cmnd:
        return 'CMND';
      case IDType.gplx:
        return 'GPLX';
      case IDType.other:
        return 'Khác';
    }
  }

  String get displayNameEn {
    switch (this) {
      case IDType.cccd:
        return 'Citizen ID Card';
      case IDType.passport:
        return 'Passport';
      case IDType.cmnd:
        return 'Old ID Card';
      case IDType.gplx:
        return "Driver's License";
      case IDType.other:
        return 'Other';
    }
  }

  String get fullDisplayName {
    switch (this) {
      case IDType.cccd:
        return 'CCCD (Căn cước công dân)';
      case IDType.passport:
        return 'Hộ chiếu';
      case IDType.cmnd:
        return 'CMND (Chứng minh nhân dân)';
      case IDType.gplx:
        return 'GPLX (Giấy phép lái xe)';
      case IDType.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case IDType.cccd:
        return Icons.badge;
      case IDType.passport:
        return Icons.flight;
      case IDType.cmnd:
        return Icons.credit_card;
      case IDType.gplx:
        return Icons.drive_eta;
      case IDType.other:
        return Icons.description;
    }
  }
}

/// Guest gender matching backend choices
enum Gender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('other')
  other,
}

/// Extension to get gender display names
extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
    }
  }

  String get displayNameEn {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case Gender.male:
        return Icons.male;
      case Gender.female:
        return Icons.female;
      case Gender.other:
        return Icons.person;
    }
  }
}

/// Common nationalities for Vietnamese hotels
class Nationalities {
  Nationalities._();

  static const List<String> common = [
    'Vietnam',
    'China',
    'South Korea',
    'Japan',
    'USA',
    'France',
    'UK',
    'Australia',
    'Germany',
    'Russia',
    'Thailand',
    'Singapore',
    'Malaysia',
    'Taiwan',
    'Hong Kong',
    'Other',
  ];

  /// Get display name in Vietnamese
  static String getDisplayName(String nationality) {
    switch (nationality) {
      case 'Vietnam':
        return 'Việt Nam';
      case 'China':
        return 'Trung Quốc';
      case 'South Korea':
        return 'Hàn Quốc';
      case 'Japan':
        return 'Nhật Bản';
      case 'USA':
        return 'Mỹ';
      case 'France':
        return 'Pháp';
      case 'UK':
        return 'Anh';
      case 'Australia':
        return 'Úc';
      case 'Germany':
        return 'Đức';
      case 'Russia':
        return 'Nga';
      case 'Thailand':
        return 'Thái Lan';
      case 'Singapore':
        return 'Singapore';
      case 'Malaysia':
        return 'Malaysia';
      case 'Taiwan':
        return 'Đài Loan';
      case 'Hong Kong':
        return 'Hồng Kông';
      case 'Other':
        return 'Khác';
      default:
        return nationality;
    }
  }
}

/// Guest model matching backend GuestSerializer
@freezed
sealed class Guest with _$Guest {
  const factory Guest({
    required int id,
    @JsonKey(name: 'full_name') required String fullName,
    required String phone,
    @Default('') String email,

    // ID Information
    @JsonKey(name: 'id_type') @Default(IDType.cccd) IDType idType,
    @JsonKey(name: 'id_number') String? idNumber,
    @JsonKey(name: 'id_issue_date') DateTime? idIssueDate,
    @JsonKey(name: 'id_issue_place') @Default('') String idIssuePlace,
    @JsonKey(name: 'id_image') String? idImage,

    // Demographics
    @Default('Vietnam') String nationality,
    @JsonKey(name: 'date_of_birth') DateTime? dateOfBirth,
    Gender? gender,

    // Address
    @Default('') String address,
    @Default('') String city,
    @Default('') String country,

    // Status and preferences
    @JsonKey(name: 'is_vip') @Default(false) bool isVip,
    @JsonKey(name: 'total_stays') @Default(0) int totalStays,
    @Default({}) Map<String, dynamic> preferences,
    @Default('') String notes,

    // Computed fields from backend
    @JsonKey(name: 'is_returning_guest') @Default(false) bool isReturningGuest,
    @JsonKey(name: 'booking_count') @Default(0) int bookingCount,

    // Timestamps
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Guest;

  const Guest._();

  factory Guest.fromJson(Map<String, dynamic> json) => _$GuestFromJson(json);

  /// Create a new guest for registration
  factory Guest.create({
    required String fullName,
    required String phone,
    String email = '',
    IDType idType = IDType.cccd,
    String? idNumber,
    DateTime? idIssueDate,
    String idIssuePlace = '',
    String nationality = 'Vietnam',
    DateTime? dateOfBirth,
    Gender? gender,
    String address = '',
    String city = '',
    String country = '',
    bool isVip = false,
    String notes = '',
  }) {
    return Guest(
      id: 0, // Will be assigned by backend
      fullName: fullName,
      phone: phone,
      email: email,
      idType: idType,
      idNumber: idNumber,
      idIssueDate: idIssueDate,
      idIssuePlace: idIssuePlace,
      nationality: nationality,
      dateOfBirth: dateOfBirth,
      gender: gender,
      address: address,
      city: city,
      country: country,
      isVip: isVip,
      notes: notes,
    );
  }

  /// Get initials for avatar
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Get display name for nationality in Vietnamese
  String get nationalityDisplay => Nationalities.getDisplayName(nationality);

  /// Get age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Get formatted phone number
  String get formattedPhone {
    if (phone.length == 10) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    if (phone.length == 11) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 8)} ${phone.substring(8)}';
    }
    return phone;
  }

  /// Get VIP color
  Color get vipColor =>
      isVip ? const Color(0xFFFFD700) : const Color(0xFF9E9E9E);

  /// Get VIP icon
  IconData get vipIcon => isVip ? Icons.star : Icons.star_border;

  /// Check if guest has complete profile
  bool get hasCompleteProfile {
    return fullName.isNotEmpty &&
        phone.isNotEmpty &&
        idNumber != null &&
        idNumber!.isNotEmpty;
  }
}

/// Guest list response matching paginated API response
@freezed
sealed class GuestListResponse with _$GuestListResponse {
  const factory GuestListResponse({
    required int count,
    String? next,
    String? previous,
    required List<Guest> results,
  }) = _GuestListResponse;

  factory GuestListResponse.fromJson(Map<String, dynamic> json) =>
      _$GuestListResponseFromJson(json);
}

/// Guest search request
@freezed
sealed class GuestSearchRequest with _$GuestSearchRequest {
  const factory GuestSearchRequest({
    required String query,
    @JsonKey(name: 'search_by') @Default('all') String searchBy,
  }) = _GuestSearchRequest;

  factory GuestSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$GuestSearchRequestFromJson(json);
}

/// Booking summary for guest history
@freezed
sealed class GuestBookingSummary with _$GuestBookingSummary {
  const factory GuestBookingSummary({
    required int id,
    @JsonKey(name: 'room_number') required String roomNumber,
    @JsonKey(name: 'room_type_name') String? roomTypeName,
    @JsonKey(name: 'check_in_date') required DateTime checkInDate,
    @JsonKey(name: 'check_out_date') required DateTime checkOutDate,
    required String status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @JsonKey(name: 'total_amount') required int totalAmount,
    @JsonKey(name: 'is_paid') @Default(false) bool isPaid,
  }) = _GuestBookingSummary;

  factory GuestBookingSummary.fromJson(Map<String, dynamic> json) =>
      _$GuestBookingSummaryFromJson(json);
}

/// Guest history response
@freezed
sealed class GuestHistoryResponse with _$GuestHistoryResponse {
  const factory GuestHistoryResponse({
    required Guest guest,
    required List<GuestBookingSummary> bookings,
    @JsonKey(name: 'total_bookings') required int totalBookings,
    @JsonKey(name: 'total_stays') required int totalStays,
    @JsonKey(name: 'total_spent') @Default(0) int totalSpent,
  }) = _GuestHistoryResponse;

  factory GuestHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$GuestHistoryResponseFromJson(json);
}
