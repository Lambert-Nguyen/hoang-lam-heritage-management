import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exceptions.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for authentication state
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );
});

/// Provider for checking if auth is loading
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    loading: () => true,
    orElse: () => false,
  );
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  Timer? _sessionTimer;

  AuthNotifier(this._repository) : super(const AuthState.initial());

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  /// Check authentication status on app startup
  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();

    try {
      // Add timeout to prevent hanging on simulator
      final isAuthenticated = await _repository
          .isAuthenticated()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);

      if (!isAuthenticated) {
        state = const AuthState.unauthenticated();
        return;
      }

      // Get access token to start session timer
      final accessToken = await _repository.getAccessToken();
      if (accessToken == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      // Try to get cached user first
      final cachedUser = await _repository.getCachedUser();
      if (cachedUser != null) {
        state = AuthState.authenticated(user: cachedUser);
        
        // Start session timer
        _startSessionTimer(accessToken);

        // Refresh user data in background
        _refreshUserInBackground();
        return;
      }

      // No cached user, try to fetch from server
      try {
        final user = await _repository.getCurrentUser();
        state = AuthState.authenticated(user: user);
        
        // Start session timer
        _startSessionTimer(accessToken);
      } catch (e) {
        // Token might be invalid
        await _repository.clearAuthData();
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Login with username and password
  Future<void> login(String username, String password) async {
    state = const AuthState.loading();

    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _repository.login(request);
      state = AuthState.authenticated(user: response.user);
      
      // Start session timer for auto-logout
      _startSessionTimer(response.access);
    } catch (e) {
      state = AuthState.error(message: _getErrorMessage(e));
      // Don't auto-reset to unauthenticated - let UI handle error display
      // UI should call clearError() when user dismisses the error or retries
    }
  }

  /// Logout
  Future<void> logout() async {
    state = const AuthState.loading();

    try {
      await _repository.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      _sessionTimer?.cancel();
      state = const AuthState.unauthenticated();
    }
  }

  /// Clear error state and return to unauthenticated
  void clearError() {
    if (state is AuthStateError) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final request = PasswordChangeRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      await _repository.changePassword(request);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AuthState.authenticated(user: user);
    } catch (e) {
      // Keep current state on error
    }
  }

  /// Handle session expiry (called from auth interceptor)
  Future<void> handleSessionExpired() async {
    _sessionTimer?.cancel();
    await _repository.clearAuthData();
    state = const AuthState.unauthenticated();
  }

  /// Start session timer to auto-logout before token expires
  void _startSessionTimer(String accessToken) {
    _sessionTimer?.cancel();

    try {
      // Parse JWT token to get expiry time
      final parts = accessToken.split('.');
      if (parts.length != 3) return;

      // Decode payload (base64 with padding)
      String payload = parts[1];
      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      if (payloadMap['exp'] == null) return;

      final exp = payloadMap['exp'] as int;
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      // Calculate when to trigger logout (30 seconds before expiry)
      final logoutTime = expiryTime.subtract(const Duration(seconds: 30));
      final duration = logoutTime.difference(now);

      // Only set timer if token hasn't expired yet
      if (duration.isNegative) {
        handleSessionExpired();
        return;
      }

      _sessionTimer = Timer(duration, () {
        handleSessionExpired();
      });
    } catch (e) {
      // If parsing fails, don't set timer - rely on 401 handling
    }
  }

  /// Refresh user data in background
  Future<void> _refreshUserInBackground() async {
    try {
      final user = await _repository.getCurrentUser();
      // Only update if still authenticated
      state.maybeWhen(
        authenticated: (_) {
          state = AuthState.authenticated(user: user);
        },
        orElse: () {},
      );
    } catch (e) {
      // Ignore background refresh errors
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    // Use typed exceptions from ErrorInterceptor
    if (error is DioException && error.error is AppException) {
      final appException = error.error as AppException;
      return appException.message; // Already Vietnamese
    }
    
    // Fallback for non-DioException errors
    final message = error.toString().toLowerCase();
    if (message.contains('authentication') ||
        message.contains('đăng nhập') ||
        message.contains('mật khẩu') ||
        message.contains('invalid credentials')) {
      return 'Tên đăng nhập hoặc mật khẩu không đúng';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'Không có kết nối mạng';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}
