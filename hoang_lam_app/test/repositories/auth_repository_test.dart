import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoang_lam_app/repositories/auth_repository.dart';
import 'package:hoang_lam_app/core/network/api_client.dart';
import 'package:hoang_lam_app/models/auth.dart';
import 'package:hoang_lam_app/models/user.dart';
import 'package:hoang_lam_app/core/config/app_constants.dart';
import 'package:dio/dio.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([ApiClient, FlutterSecureStorage])
void main() {
  group('AuthRepository', () {
    late MockApiClient mockApiClient;
    late MockFlutterSecureStorage mockSecureStorage;
    late AuthRepository authRepository;

    setUp(() {
      mockApiClient = MockApiClient();
      mockSecureStorage = MockFlutterSecureStorage();
      authRepository = AuthRepository(
        apiClient: mockApiClient,
        secureStorage: mockSecureStorage,
      );
    });

    group('login', () {
      test('should login successfully and store tokens', () async {
        // Arrange
        final loginRequest = LoginRequest(
          username: 'testuser',
          password: 'password123',
        );

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/auth/login/'),
          data: {
            'access': 'mock_access_token',
            'refresh': 'mock_refresh_token',
            'user': {
              'id': 1,
              'username': 'testuser',
              'email': 'test@example.com',
              'first_name': 'Test',
              'last_name': 'User',
              'role': 'staff',
            },
          },
          statusCode: 200,
        );

        when(mockApiClient.post<Map<String, dynamic>>(
          AppConstants.authLoginEndpoint,
          data: anyNamed('data'),
        )).thenAnswer((_) async => mockResponse);

        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => {});

        // Act
        final result = await authRepository.login(loginRequest);

        // Assert
        expect(result.access, 'mock_access_token');
        expect(result.refresh, 'mock_refresh_token');
        expect(result.user.username, 'testuser');
        expect(result.user.role, UserRole.staff);

        // Verify tokens were stored
        verify(mockSecureStorage.write(
          key: AppConstants.accessTokenKey,
          value: 'mock_access_token',
        )).called(1);
        verify(mockSecureStorage.write(
          key: AppConstants.refreshTokenKey,
          value: 'mock_refresh_token',
        )).called(1);
      });
    });

    group('logout', () {
      test('should logout and clear tokens', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.refreshTokenKey))
            .thenAnswer((_) async => 'mock_refresh_token');

        when(mockApiClient.post(
          AppConstants.authLogoutEndpoint,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/auth/logout/'),
              statusCode: 200,
            ));

        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async => {});

        // Act
        await authRepository.logout();

        // Assert
        verify(mockSecureStorage.delete(key: AppConstants.accessTokenKey))
            .called(1);
        verify(mockSecureStorage.delete(key: AppConstants.refreshTokenKey))
            .called(1);
        verify(mockSecureStorage.delete(key: AppConstants.userDataKey))
            .called(1);
      });

      test('should clear tokens even if server logout fails', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.refreshTokenKey))
            .thenAnswer((_) async => 'mock_refresh_token');

        when(mockApiClient.post(
          AppConstants.authLogoutEndpoint,
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/logout/'),
          type: DioExceptionType.connectionError,
        ));

        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async => {});

        // Act
        await authRepository.logout();

        // Assert - tokens still cleared despite error
        verify(mockSecureStorage.delete(key: AppConstants.accessTokenKey))
            .called(1);
        verify(mockSecureStorage.delete(key: AppConstants.refreshTokenKey))
            .called(1);
      });
    });

    group('refreshToken', () {
      test('should refresh token successfully', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.refreshTokenKey))
            .thenAnswer((_) async => 'mock_refresh_token');

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/auth/refresh/'),
          data: {
            'access': 'new_access_token',
            'refresh': 'new_refresh_token',
          },
          statusCode: 200,
        );

        when(mockApiClient.post<Map<String, dynamic>>(
          AppConstants.authRefreshEndpoint,
          data: anyNamed('data'),
        )).thenAnswer((_) async => mockResponse);

        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => {});

        // Act
        final result = await authRepository.refreshToken();

        // Assert
        expect(result, isNotNull);
        expect(result!.access, 'new_access_token');
        expect(result.refresh, 'new_refresh_token');

        verify(mockSecureStorage.write(
          key: AppConstants.accessTokenKey,
          value: 'new_access_token',
        )).called(1);
      });

      test('should return null when refresh token not found', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.refreshTokenKey))
            .thenAnswer((_) async => null);

        // Act
        final result = await authRepository.refreshToken();

        // Assert
        expect(result, isNull);
        verifyNever(mockApiClient.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
        ));
      });

      test('should clear auth data when refresh fails', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.refreshTokenKey))
            .thenAnswer((_) async => 'expired_refresh_token');

        when(mockApiClient.post<Map<String, dynamic>>(
          AppConstants.authRefreshEndpoint,
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/refresh/'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/refresh/'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async => {});

        // Act
        final result = await authRepository.refreshToken();

        // Assert
        expect(result, isNull);
        verify(mockSecureStorage.delete(key: AppConstants.accessTokenKey))
            .called(1);
      });
    });

    group('getCurrentUser', () {
      test('should get current user and cache it', () async {
        // Arrange
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/auth/me/'),
          data: {
            'id': 1,
            'username': 'testuser',
            'email': 'test@example.com',
            'first_name': 'Test',
            'last_name': 'User',
            'role': 'manager',
          },
          statusCode: 200,
        );

        when(mockApiClient.get<Map<String, dynamic>>(
          AppConstants.authMeEndpoint,
        )).thenAnswer((_) async => mockResponse);

        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => {});

        // Act
        final user = await authRepository.getCurrentUser();

        // Assert
        expect(user.username, 'testuser');
        expect(user.role, UserRole.manager);
        verify(mockSecureStorage.write(
          key: AppConstants.userDataKey,
          value: anyNamed('value'),
        )).called(1);
      });
    });

    group('changePassword', () {
      test('should change password successfully', () async {
        // Arrange
        final request = PasswordChangeRequest(
          oldPassword: 'oldpass123',
          newPassword: 'newpass456',
          confirmPassword: 'newpass456',
        );

        when(mockApiClient.post(
          AppConstants.authPasswordChangeEndpoint,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions:
                  RequestOptions(path: '/auth/password/change/'),
              statusCode: 200,
            ));

        // Act & Assert
        await expectLater(
          authRepository.changePassword(request),
          completes,
        );
      });
    });

    group('isAuthenticated', () {
      test('should return true when access token exists', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.accessTokenKey))
            .thenAnswer((_) async => 'mock_access_token');

        // Act
        final result = await authRepository.isAuthenticated();

        // Assert
        expect(result, true);
      });

      test('should return false when no access token', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.accessTokenKey))
            .thenAnswer((_) async => null);

        // Act
        final result = await authRepository.isAuthenticated();

        // Assert
        expect(result, false);
      });
    });

    group('getCachedUser', () {
      test('should return cached user when data exists', () async {
        // Arrange
        final userJson = '{"id":1,"username":"testuser","email":"test@example.com","first_name":"Test","last_name":"User","role":"staff"}';
        when(mockSecureStorage.read(key: AppConstants.userDataKey))
            .thenAnswer((_) async => userJson);

        // Act
        final user = await authRepository.getCachedUser();

        // Assert
        expect(user, isNotNull);
        expect(user!.username, 'testuser');
        expect(user.role, UserRole.staff);
      });

      test('should return null when no cached data', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.userDataKey))
            .thenAnswer((_) async => null);

        // Act
        final user = await authRepository.getCachedUser();

        // Assert
        expect(user, isNull);
      });

      test('should return null when cached data is invalid', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.userDataKey))
            .thenAnswer((_) async => 'invalid json');

        // Act
        final user = await authRepository.getCachedUser();

        // Assert
        expect(user, isNull);
      });
    });

    group('clearAuthData', () {
      test('should clear all auth data', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async => {});

        // Act
        await authRepository.clearAuthData();

        // Assert
        verify(mockSecureStorage.delete(key: AppConstants.accessTokenKey))
            .called(1);
        verify(mockSecureStorage.delete(key: AppConstants.refreshTokenKey))
            .called(1);
        verify(mockSecureStorage.delete(key: AppConstants.userDataKey))
            .called(1);
      });
    });
  });
}
