import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User roles matching backend HotelUser.role
enum UserRole {
  @JsonValue('owner')
  owner,
  @JsonValue('manager')
  manager,
  @JsonValue('staff')
  staff,
  @JsonValue('housekeeping')
  housekeeping,
}

/// Extension to get role display names
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Chủ căn hộ';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.housekeeping:
        return 'Phòng buồng';
    }
  }

  String get displayNameEn {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
      case UserRole.housekeeping:
        return 'Housekeeping';
    }
  }

  /// Check if user can view financial data
  bool get canViewFinance {
    return this == UserRole.owner || this == UserRole.manager;
  }

  /// Check if user can edit rates
  bool get canEditRates {
    return this == UserRole.owner;
  }

  /// Check if user can manage bookings
  bool get canManageBookings {
    return this != UserRole.housekeeping;
  }
}

/// User model matching backend UserProfileSerializer
@freezed
sealed class User with _$User {
  const factory User({
    required int id,
    required String username,
    String? email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    UserRole? role,
    @JsonKey(name: 'role_display') String? roleDisplay,
    String? phone,
  }) = _User;

  const User._();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Get full name or username as fallback
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return username;
  }

  /// Check if user is admin (owner or manager)
  bool get isAdmin => role == UserRole.owner || role == UserRole.manager;
}
