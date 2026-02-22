import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/user.dart';

void main() {
  group('UserRole', () {
    test('parses from string value', () {
      expect(UserRole.owner.name, 'owner');
      expect(UserRole.manager.name, 'manager');
      expect(UserRole.staff.name, 'staff');
      expect(UserRole.housekeeping.name, 'housekeeping');
    });
  });

  group('User', () {
    test('creates from constructor with required fields', () {
      const user = User(id: 1, username: 'testuser');

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.email, isNull);
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
    });

    test('creates from constructor with all fields', () {
      const user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: UserRole.manager,
        roleDisplay: 'Quản lý',
        phone: '0123456789',
      );

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Test');
      expect(user.lastName, 'User');
      expect(user.role, UserRole.manager);
      expect(user.roleDisplay, 'Quản lý');
      expect(user.phone, '0123456789');
    });

    test('deserializes from JSON with snake_case keys', () {
      final json = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'first_name': 'Test',
        'last_name': 'User',
        'role': 'manager',
        'role_display': 'Quản lý',
        'phone': '0123456789',
      };

      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.firstName, 'Test');
      expect(user.lastName, 'User');
      expect(user.role, UserRole.manager);
      expect(user.roleDisplay, 'Quản lý');
    });

    test('serializes to JSON', () {
      const user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: UserRole.staff,
        phone: '0123456789',
      );

      final json = user.toJson();
      expect(json['id'], 1);
      expect(json['username'], 'testuser');
      expect(json['first_name'], 'Test');
      expect(json['last_name'], 'User');
      expect(json['role'], 'staff');
    });

    group('displayName', () {
      test('returns full name when both first and last name present', () {
        const user = User(
          id: 1,
          username: 'testuser',
          firstName: 'Test',
          lastName: 'User',
        );

        expect(user.displayName, 'Test User');
      });

      test('returns first name only when last name is null', () {
        const user = User(id: 1, username: 'testuser', firstName: 'Test');

        expect(user.displayName, 'Test');
      });

      test('returns last name only when first name is null', () {
        const user = User(id: 1, username: 'testuser', lastName: 'User');

        expect(user.displayName, 'User');
      });

      test('returns username when no names present', () {
        const user = User(id: 1, username: 'testuser');

        expect(user.displayName, 'testuser');
      });
    });

    group('isAdmin', () {
      test('returns true for owner role', () {
        const user = User(id: 1, username: 'owner', role: UserRole.owner);

        expect(user.isAdmin, isTrue);
      });

      test('returns true for manager role', () {
        const user = User(id: 1, username: 'manager', role: UserRole.manager);

        expect(user.isAdmin, isTrue);
      });

      test('returns false for staff role', () {
        const user = User(id: 1, username: 'staff', role: UserRole.staff);

        expect(user.isAdmin, isFalse);
      });

      test('returns false for housekeeping role', () {
        const user = User(
          id: 1,
          username: 'housekeeping',
          role: UserRole.housekeeping,
        );

        expect(user.isAdmin, isFalse);
      });

      test('returns false when role is null', () {
        const user = User(id: 1, username: 'noRole');

        expect(user.isAdmin, isFalse);
      });
    });

    test('supports copyWith', () {
      const user = User(id: 1, username: 'testuser', firstName: 'Test');

      final updated = user.copyWith(firstName: 'Updated');
      expect(updated.id, 1);
      expect(updated.username, 'testuser');
      expect(updated.firstName, 'Updated');
    });

    test('equality works correctly', () {
      const user1 = User(id: 1, username: 'testuser');
      const user2 = User(id: 1, username: 'testuser');
      const user3 = User(id: 2, username: 'otheruser');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });
  });
}
