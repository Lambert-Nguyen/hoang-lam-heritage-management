import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/auth.dart';
import '../models/user.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  AuthRepository({
    ApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Login with username and password
  /// Returns [LoginResponse] with tokens and user data on success
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.authLoginEndpoint,
      data: request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data!);

    // Store tokens securely
    await _saveTokens(loginResponse.access, loginResponse.refresh);

    // Store user data
    await _saveUser(loginResponse.user);

    return loginResponse;
  }

  /// Logout and invalidate tokens
  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.read(
        key: AppConstants.refreshTokenKey,
      );

      if (refreshToken != null) {
        // Try to blacklist the token on server
        await _apiClient.post(
          AppConstants.authLogoutEndpoint,
          data: LogoutRequest(refresh: refreshToken).toJson(),
        );
      }
    } catch (e) {
      // Ignore errors during logout - we still want to clear local data
    } finally {
      // Always clear local tokens and data
      await clearAuthData();
    }
  }

  /// Refresh access token
  Future<RefreshTokenResponse?> refreshToken() async {
    final refreshToken = await _secureStorage.read(
      key: AppConstants.refreshTokenKey,
    );

    if (refreshToken == null) {
      return null;
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        AppConstants.authRefreshEndpoint,
        data: RefreshTokenRequest(refresh: refreshToken).toJson(),
      );

      final refreshResponse = RefreshTokenResponse.fromJson(response.data!);

      // Update stored tokens
      await _secureStorage.write(
        key: AppConstants.accessTokenKey,
        value: refreshResponse.access,
      );

      if (refreshResponse.refresh != null) {
        await _secureStorage.write(
          key: AppConstants.refreshTokenKey,
          value: refreshResponse.refresh,
        );
      }

      return refreshResponse;
    } catch (e) {
      // Token refresh failed - clear auth data
      await clearAuthData();
      return null;
    }
  }

  /// Get current user profile from server
  Future<User> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      AppConstants.authMeEndpoint,
    );

    final user = User.fromJson(response.data!);

    // Update cached user data
    await _saveUser(user);

    return user;
  }

  /// Change user password
  Future<void> changePassword(PasswordChangeRequest request) async {
    await _apiClient.post(
      AppConstants.authPasswordChangeEndpoint,
      data: request.toJson(),
    );
  }

  /// Check if user is currently authenticated (has stored tokens)
  Future<bool> isAuthenticated() async {
    final accessToken = await _secureStorage.read(
      key: AppConstants.accessTokenKey,
    );
    return accessToken != null;
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userDataKey);
  }

  /// Save tokens to secure storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: accessToken,
    );
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Save user data to secure storage
  Future<void> _saveUser(User user) async {
    final jsonString = jsonEncode(user.toJson());
    await _secureStorage.write(
      key: AppConstants.userDataKey,
      value: jsonString,
    );
  }

  /// Get cached user data
  Future<User?> getCachedUser() async {
    final userData = await _secureStorage.read(key: AppConstants.userDataKey);
    if (userData == null) return null;

    try {
      final json = jsonDecode(userData) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}
