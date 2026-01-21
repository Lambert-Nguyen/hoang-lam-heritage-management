import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/auth.dart';
import 'package:hoang_lam_app/models/user.dart';

void main() {
  group('LoginRequest', () {
    test('creates from constructor', () {
      const request = LoginRequest(
        username: 'testuser',
        password: 'testpass123',
      );

      expect(request.username, 'testuser');
      expect(request.password, 'testpass123');
    });

    test('serializes to JSON', () {
      const request = LoginRequest(
        username: 'testuser',
        password: 'testpass123',
      );

      final json = request.toJson();
      expect(json['username'], 'testuser');
      expect(json['password'], 'testpass123');
    });

    test('deserializes from JSON', () {
      final json = {
        'username': 'testuser',
        'password': 'testpass123',
      };

      final request = LoginRequest.fromJson(json);
      expect(request.username, 'testuser');
      expect(request.password, 'testpass123');
    });
  });

  group('LoginResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'access': 'access_token_123',
        'refresh': 'refresh_token_456',
        'user': {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'first_name': 'Test',
          'last_name': 'User',
          'role': 'manager',
          'role_display': 'Quản lý',
          'phone': '0123456789',
        },
      };

      final response = LoginResponse.fromJson(json);
      expect(response.access, 'access_token_123');
      expect(response.refresh, 'refresh_token_456');
      expect(response.user.username, 'testuser');
      expect(response.user.email, 'test@example.com');
    });
  });

  group('RefreshTokenRequest', () {
    test('serializes to JSON', () {
      const request = RefreshTokenRequest(refresh: 'refresh_token_123');

      final json = request.toJson();
      expect(json['refresh'], 'refresh_token_123');
    });
  });

  group('RefreshTokenResponse', () {
    test('deserializes from JSON with new refresh token', () {
      final json = {
        'access': 'new_access_token',
        'refresh': 'new_refresh_token',
      };

      final response = RefreshTokenResponse.fromJson(json);
      expect(response.access, 'new_access_token');
      expect(response.refresh, 'new_refresh_token');
    });

    test('deserializes from JSON without new refresh token', () {
      final json = {
        'access': 'new_access_token',
      };

      final response = RefreshTokenResponse.fromJson(json);
      expect(response.access, 'new_access_token');
      expect(response.refresh, isNull);
    });
  });

  group('LogoutRequest', () {
    test('serializes to JSON', () {
      const request = LogoutRequest(refresh: 'refresh_token_123');

      final json = request.toJson();
      expect(json['refresh'], 'refresh_token_123');
    });
  });

  group('PasswordChangeRequest', () {
    test('serializes to JSON with snake_case keys', () {
      const request = PasswordChangeRequest(
        oldPassword: 'oldpass123',
        newPassword: 'newpass456',
        confirmPassword: 'newpass456',
      );

      final json = request.toJson();
      expect(json['old_password'], 'oldpass123');
      expect(json['new_password'], 'newpass456');
      expect(json['confirm_password'], 'newpass456');
    });
  });

  group('AuthState', () {
    test('creates initial state', () {
      const state = AuthState.initial();

      state.maybeWhen(
        initial: () => expect(true, isTrue),
        orElse: () => fail('Expected initial state'),
      );
    });

    test('creates loading state', () {
      const state = AuthState.loading();

      state.maybeWhen(
        loading: () => expect(true, isTrue),
        orElse: () => fail('Expected loading state'),
      );
    });

    test('creates authenticated state with user', () {
      final user = User.fromJson({
        'id': 1,
        'username': 'testuser',
      });
      final state = AuthState.authenticated(user: user);

      state.maybeWhen(
        authenticated: (u) {
          expect(u.id, 1);
          expect(u.username, 'testuser');
        },
        orElse: () => fail('Expected authenticated state'),
      );
    });

    test('creates unauthenticated state', () {
      const state = AuthState.unauthenticated();

      state.maybeWhen(
        unauthenticated: () => expect(true, isTrue),
        orElse: () => fail('Expected unauthenticated state'),
      );
    });

    test('creates error state with message', () {
      const state = AuthState.error(message: 'Test error');

      state.maybeWhen(
        error: (msg) => expect(msg, 'Test error'),
        orElse: () => fail('Expected error state'),
      );
    });
  });
}
