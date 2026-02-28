import '../../l10n/app_localizations.dart';
import '../errors/app_exceptions.dart';

/// Extracts a user-friendly localized message from any error object.
///
/// Priority:
/// 1. AppException — uses getLocalizedMessage()
/// 2. Pattern-matched common error strings
/// 3. Falls back to generic error message
String getLocalizedErrorMessage(dynamic error, AppLocalizations l10n) {
  // Already a well-structured AppException
  if (error is AppException) {
    return error.getLocalizedMessage(l10n.isVietnamese ? 'vi' : 'en');
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
