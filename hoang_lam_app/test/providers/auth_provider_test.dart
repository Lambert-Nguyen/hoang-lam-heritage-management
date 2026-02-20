import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:hoang_lam_app/models/auth.dart';
import 'package:hoang_lam_app/models/user.dart';
import 'package:hoang_lam_app/providers/auth_provider.dart';
import 'package:hoang_lam_app/repositories/auth_repository.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepository;
  late ProviderContainer container;

  // Provide dummy values for Freezed types that Mockito can't auto-generate
  setUpAll(() {
    provideDummy<User>(User(id: 0, username: 'dummy'));
    provideDummy<LoginResponse>(LoginResponse(
      access: 'dummy',
      refresh: 'dummy',
      user: User(id: 0, username: 'dummy'),
    ));
  });

  final testUser = User(
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    role: UserRole.staff,
  );

  final testLoginResponse = LoginResponse(
    access: 'mock_access_token_header.eyJleHAiOjk5OTk5OTk5OTl9.signature',
    refresh: 'mock_refresh_token',
    user: testUser,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier', () {
    group('initial state', () {
      test('should start in initial state', () {
        final state = container.read(authStateProvider);
        expect(
          state,
          isA<AuthStateInitial>(),
        );
      });
    });

    group('checkAuthStatus', () {
      test('should set authenticated when tokens and cached user exist',
          () async {
        when(mockRepository.isAuthenticated()).thenAnswer((_) async => true);
        when(mockRepository.getAccessToken())
            .thenAnswer((_) async => 'mock_access');
        when(mockRepository.getCachedUser())
            .thenAnswer((_) async => testUser);
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        final notifier = container.read(authStateProvider.notifier);
        await notifier.checkAuthStatus();

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateAuthenticated>());
        state.maybeWhen(
          authenticated: (user) {
            expect(user.username, 'testuser');
            expect(user.role, UserRole.staff);
          },
          orElse: () => fail('Expected authenticated state'),
        );
      });

      test('should set unauthenticated when not authenticated', () async {
        when(mockRepository.isAuthenticated()).thenAnswer((_) async => false);

        final notifier = container.read(authStateProvider.notifier);
        await notifier.checkAuthStatus();

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateUnauthenticated>());
      });

      test('should set unauthenticated when no access token', () async {
        when(mockRepository.isAuthenticated()).thenAnswer((_) async => true);
        when(mockRepository.getAccessToken()).thenAnswer((_) async => null);

        final notifier = container.read(authStateProvider.notifier);
        await notifier.checkAuthStatus();

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateUnauthenticated>());
      });

      test('should set unauthenticated when isAuthenticated times out',
          () async {
        // Use a Completer that never completes to simulate a hanging call.
        // The implementation's 5-second timeout will fire and treat it as false.
        final neverCompletes = Completer<bool>();
        when(mockRepository.isAuthenticated())
            .thenAnswer((_) => neverCompletes.future);

        final notifier = container.read(authStateProvider.notifier);
        await notifier.checkAuthStatus();

        // Should have timed out and returned false
        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateUnauthenticated>());

        // Complete the future to avoid dangling in the test runner
        neverCompletes.complete(true);
      });

      test('should fetch from server when no cached user', () async {
        when(mockRepository.isAuthenticated()).thenAnswer((_) async => true);
        when(mockRepository.getAccessToken())
            .thenAnswer((_) async => 'mock_access');
        when(mockRepository.getCachedUser()).thenAnswer((_) async => null);
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        final notifier = container.read(authStateProvider.notifier);
        await notifier.checkAuthStatus();

        verify(mockRepository.getCurrentUser()).called(1);
        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateAuthenticated>());
      });

      test('should set unauthenticated when server fetch fails', () async {
        when(mockRepository.isAuthenticated()).thenAnswer((_) async => true);
        when(mockRepository.getAccessToken())
            .thenAnswer((_) async => 'mock_access');
        when(mockRepository.getCachedUser()).thenAnswer((_) async => null);
        when(mockRepository.getCurrentUser())
            .thenThrow(Exception('Network error'));
        when(mockRepository.clearAuthData()).thenAnswer((_) async {});

        final notifier = container.read(authStateProvider.notifier);
        await notifier.checkAuthStatus();

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateUnauthenticated>());
        verify(mockRepository.clearAuthData()).called(1);
      });
    });

    group('login', () {
      test('should set authenticated on successful login', () async {
        when(mockRepository.login(any))
            .thenAnswer((_) async => testLoginResponse);

        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('testuser', 'password123');

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateAuthenticated>());
        state.maybeWhen(
          authenticated: (user) {
            expect(user.username, 'testuser');
          },
          orElse: () => fail('Expected authenticated state'),
        );
      });

      test('should set error state on login failure', () async {
        when(mockRepository.login(any))
            .thenThrow(Exception('Invalid credentials'));

        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('testuser', 'wrongpass');

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateError>());
      });

      test('should set error state on network error', () async {
        when(mockRepository.login(any)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login/'),
            type: DioExceptionType.connectionError,
          ),
        );

        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('testuser', 'password123');

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateError>());
      });

      test('should pass correct credentials to repository', () async {
        when(mockRepository.login(any))
            .thenAnswer((_) async => testLoginResponse);

        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('admin', 'secret');

        final captured =
            verify(mockRepository.login(captureAny)).captured.single
                as LoginRequest;
        expect(captured.username, 'admin');
        expect(captured.password, 'secret');
      });
    });

    group('logout', () {
      test('should set unauthenticated after logout', () async {
        // First login
        when(mockRepository.login(any))
            .thenAnswer((_) async => testLoginResponse);
        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('testuser', 'password123');
        expect(container.read(authStateProvider), isA<AuthStateAuthenticated>());

        // Then logout
        when(mockRepository.logout()).thenAnswer((_) async {});
        await notifier.logout();

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateUnauthenticated>());
      });

      test('should set unauthenticated even if logout API fails', () async {
        when(mockRepository.login(any))
            .thenAnswer((_) async => testLoginResponse);
        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('testuser', 'password123');

        when(mockRepository.logout()).thenThrow(Exception('Network error'));
        await notifier.logout();

        final state = container.read(authStateProvider);
        expect(state, isA<AuthStateUnauthenticated>());
      });
    });

    group('clearError', () {
      test('should transition from error to unauthenticated', () async {
        when(mockRepository.login(any))
            .thenThrow(Exception('Invalid credentials'));

        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('testuser', 'wrongpass');
        expect(container.read(authStateProvider), isA<AuthStateError>());

        notifier.clearError();
        expect(
            container.read(authStateProvider), isA<AuthStateUnauthenticated>());
      });

      test('should not change state if not in error state', () async {
        when(mockRepository.login(any))
            .thenAnswer((_) async => testLoginResponse);
        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('testuser', 'password123');

        notifier.clearError();
        expect(
            container.read(authStateProvider), isA<AuthStateAuthenticated>());
      });
    });

    group('changePassword', () {
      test('should return null on success', () async {
        when(mockRepository.changePassword(any)).thenAnswer((_) async {});

        final notifier = container.read(authStateProvider.notifier);
        final result = await notifier.changePassword(
          oldPassword: 'old123',
          newPassword: 'new123',
          confirmPassword: 'new123',
        );

        expect(result, isNull);
      });

      test('should return error message on failure', () async {
        when(mockRepository.changePassword(any))
            .thenThrow(Exception('Old password incorrect'));

        final notifier = container.read(authStateProvider.notifier);
        final result = await notifier.changePassword(
          oldPassword: 'wrongold',
          newPassword: 'new123',
          confirmPassword: 'new123',
        );

        expect(result, isNotNull);
        expect(result, isA<String>());
      });
    });

    group('refreshSession', () {
      test('should return true when refresh succeeds', () async {
        final refreshResponse = RefreshTokenResponse(
          access:
              'new_access_token_header.eyJleHAiOjk5OTk5OTk5OTl9.signature',
        );
        when(mockRepository.refreshToken())
            .thenAnswer((_) async => refreshResponse);
        when(mockRepository.getCachedUser())
            .thenAnswer((_) async => testUser);

        final notifier = container.read(authStateProvider.notifier);
        final result = await notifier.refreshSession();

        expect(result, true);
        expect(
            container.read(authStateProvider), isA<AuthStateAuthenticated>());
      });

      test('should return false and unauthenticate when refresh returns null',
          () async {
        when(mockRepository.refreshToken()).thenAnswer((_) async => null);

        final notifier = container.read(authStateProvider.notifier);
        final result = await notifier.refreshSession();

        expect(result, false);
        expect(container.read(authStateProvider),
            isA<AuthStateUnauthenticated>());
      });

      test('should return false and unauthenticate on error', () async {
        when(mockRepository.refreshToken())
            .thenThrow(Exception('Token expired'));
        when(mockRepository.clearAuthData()).thenAnswer((_) async {});

        final notifier = container.read(authStateProvider.notifier);
        final result = await notifier.refreshSession();

        expect(result, false);
        verify(mockRepository.clearAuthData()).called(1);
        expect(container.read(authStateProvider),
            isA<AuthStateUnauthenticated>());
      });
    });

    group('handleSessionExpired', () {
      test('should clear auth data and set unauthenticated', () async {
        when(mockRepository.clearAuthData()).thenAnswer((_) async {});
        when(mockRepository.login(any))
            .thenAnswer((_) async => testLoginResponse);

        final notifier = container.read(authStateProvider.notifier);
        await notifier.login('testuser', 'password123');
        expect(
            container.read(authStateProvider), isA<AuthStateAuthenticated>());

        await notifier.handleSessionExpired();

        verify(mockRepository.clearAuthData()).called(1);
        expect(container.read(authStateProvider),
            isA<AuthStateUnauthenticated>());
      });
    });
  });

  group('Derived providers', () {
    test('currentUserProvider returns user when authenticated', () async {
      when(mockRepository.login(any))
          .thenAnswer((_) async => testLoginResponse);

      final notifier = container.read(authStateProvider.notifier);
      await notifier.login('testuser', 'password123');

      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.username, 'testuser');
    });

    test('currentUserProvider returns null when unauthenticated', () {
      final user = container.read(currentUserProvider);
      expect(user, isNull);
    });

    test('isAuthenticatedProvider returns true when authenticated', () async {
      when(mockRepository.login(any))
          .thenAnswer((_) async => testLoginResponse);

      final notifier = container.read(authStateProvider.notifier);
      await notifier.login('testuser', 'password123');

      expect(container.read(isAuthenticatedProvider), true);
    });

    test('isAuthenticatedProvider returns false when unauthenticated', () {
      expect(container.read(isAuthenticatedProvider), false);
    });

    test('isAuthLoadingProvider returns true during loading', () async {
      // Use a Completer so we control when login resolves (no dangling timer)
      final loginCompleter = Completer<LoginResponse>();
      when(mockRepository.login(any)).thenAnswer(
          (_) => loginCompleter.future);

      final notifier = container.read(authStateProvider.notifier);
      // ignore: unawaited_futures
      notifier.login('testuser', 'password123'); // Don't await

      // Allow microtasks to process so state transitions to loading
      await Future.microtask(() {});

      // The state should be loading now
      expect(container.read(isAuthLoadingProvider), true);

      // Complete the future to avoid dangling in the test runner
      loginCompleter.complete(testLoginResponse);
    });
  });
}
