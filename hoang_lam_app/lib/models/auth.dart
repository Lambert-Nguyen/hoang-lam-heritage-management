import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'auth.freezed.dart';
part 'auth.g.dart';

/// Login request payload
@freezed
sealed class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

/// Login response from server
@freezed
sealed class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String access,
    required String refresh,
    required User user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

/// Token refresh request
@freezed
sealed class RefreshTokenRequest with _$RefreshTokenRequest {
  const factory RefreshTokenRequest({
    required String refresh,
  }) = _RefreshTokenRequest;

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
}

/// Token refresh response
@freezed
sealed class RefreshTokenResponse with _$RefreshTokenResponse {
  const factory RefreshTokenResponse({
    required String access,
    String? refresh,
  }) = _RefreshTokenResponse;

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenResponseFromJson(json);
}

/// Logout request
@freezed
sealed class LogoutRequest with _$LogoutRequest {
  const factory LogoutRequest({
    required String refresh,
  }) = _LogoutRequest;

  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      _$LogoutRequestFromJson(json);
}

/// Password change request
@freezed
sealed class PasswordChangeRequest with _$PasswordChangeRequest {
  const factory PasswordChangeRequest({
    @JsonKey(name: 'old_password') required String oldPassword,
    @JsonKey(name: 'new_password') required String newPassword,
    @JsonKey(name: 'confirm_password') required String confirmPassword,
  }) = _PasswordChangeRequest;

  factory PasswordChangeRequest.fromJson(Map<String, dynamic> json) =>
      _$PasswordChangeRequestFromJson(json);
}

/// Authentication state
@freezed
sealed class AuthState with _$AuthState {
  /// Initial state - not yet checked
  const factory AuthState.initial() = AuthStateInitial;

  /// Currently checking authentication status
  const factory AuthState.loading() = AuthStateLoading;

  /// User is authenticated
  const factory AuthState.authenticated({
    required User user,
  }) = AuthStateAuthenticated;

  /// User is not authenticated
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;

  /// Authentication error
  const factory AuthState.error({
    required String message,
  }) = AuthStateError;
}
