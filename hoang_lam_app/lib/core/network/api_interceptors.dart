import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env_config.dart';
import '../config/app_constants.dart';
import '../errors/app_exceptions.dart';

/// iOS-compatible secure storage options
const _iOSOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock,
);

/// Auth interceptor for JWT token management
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: _iOSOptions,
  );
  bool _isRefreshing = false;
  final List<RequestOptions> _requestQueue = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login and refresh endpoints
    if (_isAuthEndpoint(options.path)) {
      debugPrint('[AuthInterceptor] Skipping auth for: ${options.path}');
      return handler.next(options);
    }

    try {
      final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
      debugPrint('[AuthInterceptor] Token read result: ${accessToken != null ? "found" : "null"}');
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    } catch (e) {
      debugPrint('[AuthInterceptor] Error reading token: $e');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // If already refreshing, queue this request
      if (_isRefreshing) {
        _requestQueue.add(err.requestOptions);
        // Wait for refresh to complete
        await _waitForRefresh();
        
        // Retry with new token
        try {
          final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
          if (accessToken != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
            final response = await _dio.fetch(err.requestOptions);
            return handler.resolve(response);
          }
        } catch (e) {
          // Retry failed, pass error through
          return handler.next(err);
        }
      } else {
        // First 401, start refresh process
        _isRefreshing = true;

        try {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
            err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';

            final response = await _dio.fetch(err.requestOptions);
            
            // Process queued requests
            await _retryQueuedRequests();
            
            _isRefreshing = false;
            return handler.resolve(response);
          }
        } catch (e) {
          // Refresh failed, clear tokens
          await _clearTokens();
        }

        _isRefreshing = false;
        _requestQueue.clear();
      }
    }

    handler.next(err);
  }

  Future<void> _waitForRefresh() async {
    // Poll until refresh is complete (max 5 seconds)
    int attempts = 0;
    while (_isRefreshing && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<void> _retryQueuedRequests() async {
    if (_requestQueue.isEmpty) return;
    
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    if (accessToken == null) return;

    // Copy queue and clear it
    final requests = List<RequestOptions>.from(_requestQueue);
    _requestQueue.clear();

    // Retry all queued requests
    for (final request in requests) {
      try {
        request.headers['Authorization'] = 'Bearer $accessToken';
        await _dio.fetch(request);
      } catch (e) {
        // Individual request failed, but don't block others
        debugPrint('Queued request failed: $e');
      }
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        AppConstants.authRefreshEndpoint,
        data: {'refresh': refreshToken},
        options: Options(headers: {'Authorization': ''}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.write(
          key: AppConstants.accessTokenKey,
          value: data['access'],
        );
        if (data['refresh'] != null) {
          await _storage.write(
            key: AppConstants.refreshTokenKey,
            value: data['refresh'],
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('login') || path.contains('refresh');
  }
}

/// Logging interceptor for debugging
class LoggingInterceptor extends Interceptor {
  /// Sanitize headers to hide sensitive information
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    // Hide Authorization token
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization'].toString();
      if (auth.startsWith('Bearer ')) {
        sanitized['Authorization'] = 'Bearer ***';
      } else {
        sanitized['Authorization'] = '***';
      }
    }
    return sanitized;
  }

  /// Sanitize request data to hide passwords
  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;
    
    if (data is Map<String, dynamic>) {
      final sanitized = Map<String, dynamic>.from(data);
      // Hide password fields
      if (sanitized.containsKey('password')) {
        sanitized['password'] = '***';
      }
      if (sanitized.containsKey('old_password')) {
        sanitized['old_password'] = '***';
      }
      if (sanitized.containsKey('new_password')) {
        sanitized['new_password'] = '***';
      }
      if (sanitized.containsKey('confirm_password')) {
        sanitized['confirm_password'] = '***';
      }
      return sanitized;
    }
    
    return data;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (EnvConfig.current.enableLogging) {
      debugPrint('┌─────────────────────────────────────────────────────────');
      debugPrint('│ REQUEST: ${options.method} ${options.uri}');
      debugPrint('│ Headers: ${_sanitizeHeaders(options.headers)}');
      if (options.data != null) {
        debugPrint('│ Data: ${_sanitizeData(options.data)}');
      }
      debugPrint('└─────────────────────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (EnvConfig.current.enableLogging) {
      debugPrint('┌─────────────────────────────────────────────────────────');
      debugPrint('│ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      // Don't log response data as it may contain tokens
      debugPrint('│ Data: <response data hidden for security>');
      debugPrint('└─────────────────────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (EnvConfig.current.enableLogging) {
      debugPrint('┌─────────────────────────────────────────────────────────');
      debugPrint('│ ERROR: ${err.type} ${err.requestOptions.uri}');
      debugPrint('│ Message: ${err.message}');
      if (err.response != null) {
        debugPrint('│ Status: ${err.response?.statusCode}');
        debugPrint('│ Data: ${_sanitizeData(err.response?.data)}');
      }
      debugPrint('└─────────────────────────────────────────────────────────');
    }
    handler.next(err);
  }
}

/// Error handling interceptor
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }

  AppException _mapDioError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Kết nối quá thời gian. Vui lòng thử lại.',
          messageEn: 'Connection timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Không có kết nối mạng.',
          messageEn: 'No network connection.',
        );

      case DioExceptionType.badResponse:
        return _mapStatusCode(err.response);

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Yêu cầu đã bị hủy.',
          messageEn: 'Request was cancelled.',
        );

      default:
        return UnknownException(
          message: 'Đã xảy ra lỗi. Vui lòng thử lại.',
          messageEn: 'An error occurred. Please try again.',
        );
    }
  }

  AppException _mapStatusCode(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;
    final errorMessage = data is Map ? data['message'] ?? data['detail'] : null;

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: errorMessage ?? 'Dữ liệu không hợp lệ.',
          messageEn: 'Invalid data.',
          errors: data is Map ? data['errors'] : null,
        );

      case 401:
        return AuthException(
          message: 'Phiên đăng nhập đã hết hạn.',
          messageEn: 'Session expired. Please login again.',
        );

      case 403:
        return AuthException(
          message: 'Bạn không có quyền thực hiện thao tác này.',
          messageEn: 'You do not have permission for this action.',
        );

      case 404:
        return NotFoundException(
          message: 'Không tìm thấy dữ liệu.',
          messageEn: 'Data not found.',
        );

      case 409:
        return ConflictException(
          message: errorMessage ?? 'Dữ liệu bị xung đột.',
          messageEn: 'Data conflict.',
        );

      case 422:
        return ValidationException(
          message: errorMessage ?? 'Dữ liệu không hợp lệ.',
          messageEn: 'Invalid data.',
          errors: data is Map ? data['errors'] : null,
        );

      case 500:
      case 502:
      case 503:
        return ServerException(
          message: 'Lỗi máy chủ. Vui lòng thử lại sau.',
          messageEn: 'Server error. Please try again later.',
        );

      default:
        return UnknownException(
          message: errorMessage ?? 'Đã xảy ra lỗi.',
          messageEn: 'An error occurred.',
        );
    }
  }
}
