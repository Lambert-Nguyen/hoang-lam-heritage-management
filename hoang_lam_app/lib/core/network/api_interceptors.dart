import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env_config.dart';
import '../config/app_constants.dart';
import '../errors/app_exceptions.dart';

/// Auth interceptor for JWT token management
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login and refresh endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request
          final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
          err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';

          final response = await _dio.fetch(err.requestOptions);
          _isRefreshing = false;
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh failed, clear tokens
        await _clearTokens();
      }

      _isRefreshing = false;
    }

    handler.next(err);
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
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (EnvConfig.current.enableLogging) {
      debugPrint('┌─────────────────────────────────────────────────────────');
      debugPrint('│ REQUEST: ${options.method} ${options.uri}');
      debugPrint('│ Headers: ${options.headers}');
      if (options.data != null) {
        debugPrint('│ Data: ${options.data}');
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
      debugPrint('│ Data: ${response.data}');
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
        debugPrint('│ Data: ${err.response?.data}');
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
