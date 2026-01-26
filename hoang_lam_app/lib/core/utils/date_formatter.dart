import 'package:intl/intl.dart';
import '../config/app_constants.dart';

/// Date/time formatting utilities
class DateFormatter {
  DateFormatter._();

  static final _dateFormat = DateFormat(AppConstants.dateFormat);
  static final _dateFormatShort = DateFormat(AppConstants.dateFormatShort);
  static final _timeFormat = DateFormat(AppConstants.timeFormat);
  static final _dateTimeFormat = DateFormat(AppConstants.dateTimeFormat);
  static final _apiDateFormat = DateFormat(AppConstants.apiDateFormat);
  static final _apiDateTimeFormat = DateFormat(AppConstants.apiDateTimeFormat);

  /// Format date as dd/MM/yyyy
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format date as dd/MM
  static String formatDateShort(DateTime date) {
    return _dateFormatShort.format(date);
  }

  /// Format time as HH:mm
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  /// Format datetime as dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Format for API (yyyy-MM-dd)
  static String toApiDate(DateTime date) {
    return _apiDateFormat.format(date);
  }

  /// Format for API with time
  static String toApiDateTime(DateTime dateTime) {
    return _apiDateTimeFormat.format(dateTime.toUtc());
  }

  /// Parse API date string
  static DateTime? parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return _apiDateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse API datetime string
  static DateTime? parseApiDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeString).toLocal();
    } catch (e) {
      return null;
    }
  }

  /// Format date range (e.g., "19/01 → 21/01")
  static String formatDateRange(DateTime start, DateTime end) {
    return '${formatDateShort(start)} → ${formatDateShort(end)}';
  }

  /// Calculate nights between two dates
  static int calculateNights(DateTime checkIn, DateTime checkOut) {
    final checkInDate = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final checkOutDate = DateTime(checkOut.year, checkOut.month, checkOut.day);
    return checkOutDate.difference(checkInDate).inDays;
  }

  /// Get relative date description
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Ngày mai';
    } else if (difference == -1) {
      return 'Hôm qua';
    } else if (difference > 1 && difference <= 7) {
      return 'Trong $difference ngày';
    } else if (difference < -1 && difference >= -7) {
      return '${-difference} ngày trước';
    } else {
      return formatDate(date);
    }
  }

  /// Get Vietnamese day of week
  static String getDayOfWeek(DateTime date) {
    const days = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];
    return days[date.weekday % 7];
  }

  /// Get Vietnamese month name
  static String getMonthName(int month) {
    return 'Tháng $month';
  }

  /// Format month and year (e.g., "Tháng 1, 2026")
  static String formatMonthYear(DateTime date) {
    return '${getMonthName(date.month)}, ${date.year}';
  }
}
