/// Base exception class for the app
abstract class AppException implements Exception {
  final String message; // Vietnamese
  final String messageEn; // English
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    required this.messageEn,
    this.code,
    this.details,
  });

  /// Get localized message based on locale
  String getLocalizedMessage(String locale) {
    return locale == 'vi' ? message : messageEn;
  }

  @override
  String toString() => 'AppException: $message';
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    required super.messageEn,
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    required super.messageEn,
    super.code = 'AUTH_ERROR',
    super.details,
  });
}

/// Server exceptions (5xx)
class ServerException extends AppException {
  const ServerException({
    required super.message,
    required super.messageEn,
    super.code = 'SERVER_ERROR',
    super.details,
  });
}

/// Validation exceptions (400, 422)
class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  const ValidationException({
    required super.message,
    required super.messageEn,
    super.code = 'VALIDATION_ERROR',
    super.details,
    this.errors,
  });
}

/// Not found exceptions (404)
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    required super.messageEn,
    super.code = 'NOT_FOUND',
    super.details,
  });
}

/// Conflict exceptions (409)
class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    required super.messageEn,
    super.code = 'CONFLICT',
    super.details,
  });
}

/// Booking conflict exception
class BookingConflictException extends ConflictException {
  final int? conflictingBookingId;
  final int? roomId;

  const BookingConflictException({
    super.message = 'Phòng đã được đặt trong thời gian này.',
    super.messageEn = 'Room is already booked for this period.',
    super.code = 'BOOKING_CONFLICT',
    this.conflictingBookingId,
    this.roomId,
  });
}

/// Unknown exceptions
class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    required super.messageEn,
    super.code = 'UNKNOWN_ERROR',
    super.details,
  });
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException({
    super.message = 'Lỗi bộ nhớ đệm.',
    super.messageEn = 'Cache error.',
    super.code = 'CACHE_ERROR',
    super.details,
  });
}

/// Offline exceptions
class OfflineException extends AppException {
  const OfflineException({
    super.message = 'Không có kết nối mạng. Đang làm việc offline.',
    super.messageEn = 'No network connection. Working offline.',
    super.code = 'OFFLINE',
    super.details,
  });
}
