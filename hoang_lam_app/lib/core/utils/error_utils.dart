import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';
import '../errors/app_exceptions.dart';

/// Extracts a user-friendly localized message from any error object.
///
/// Priority:
/// 1. AppException — uses getLocalizedMessage()
/// 2. DioException — maps by type and status code
/// 3. FormatException — data format error
/// 4. Pattern-matched common error strings
/// 5. Falls back to generic error message
String getLocalizedErrorMessage(dynamic error, AppLocalizations l10n) {
  // Already a well-structured AppException
  if (error is AppException) {
    return error.getLocalizedMessage(l10n.isVietnamese ? 'vi' : 'en');
  }

  // DioException — map by type and HTTP status
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n.errorConnectionTimeout;
      case DioExceptionType.connectionError:
        return l10n.errorNoNetwork;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) return l10n.errorSessionExpired;
        if (statusCode == 403) return l10n.errorNoPermission;
        if (statusCode == 404) return l10n.errorNotFound;
        if (statusCode == 409) return l10n.errorConflict;
        if (statusCode != null && statusCode >= 500) return l10n.errorServer;
        // Try to extract detail message from response body
        final data = error.response?.data;
        if (data is Map && data.containsKey('detail')) {
          return data['detail'].toString();
        }
        return l10n.errorGeneric;
      case DioExceptionType.cancel:
        return l10n.errorGeneric;
      default:
        return l10n.errorNoNetwork;
    }
  }

  // FormatException — malformed data
  if (error is FormatException) {
    return l10n.errorGeneric;
  }

  final message = error.toString().toLowerCase();

  // Network / connectivity
  if (message.contains('socketexception') ||
      message.contains('no internet') ||
      message.contains('connection refused') ||
      message.contains('network is unreachable') ||
      message.contains('failed host lookup')) {
    return l10n.errorNoNetwork;
  }

  // Timeout
  if (message.contains('timeout') || message.contains('timed out')) {
    return l10n.errorConnectionTimeout;
  }

  // Authentication
  if (message.contains('401') || message.contains('unauthorized')) {
    return l10n.errorSessionExpired;
  }

  // Forbidden
  if (message.contains('403') || message.contains('forbidden')) {
    return l10n.errorNoPermission;
  }

  // Not found
  if (message.contains('404') || message.contains('not found')) {
    return l10n.errorNotFound;
  }

  // Conflict / duplicate
  if (message.contains('409') ||
      message.contains('conflict') ||
      message.contains('duplicate') ||
      message.contains('đã tồn tại')) {
    return l10n.errorConflict;
  }

  // Server error
  if (message.contains('500') ||
      message.contains('502') ||
      message.contains('503') ||
      message.contains('server error') ||
      message.contains('internal server')) {
    return l10n.errorServer;
  }

  // Generic fallback
  return l10n.errorGeneric;
}
