import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/guest.dart';

void main() {
  group('IDType', () {
    test('has correct display names in Vietnamese', () {
      expect(IDType.cccd.displayName, 'CCCD');
      expect(IDType.passport.displayName, 'Hộ chiếu');
      expect(IDType.cmnd.displayName, 'CMND');
      expect(IDType.gplx.displayName, 'GPLX');
      expect(IDType.other.displayName, 'Khác');
    });

    test('has correct display names in English', () {
      expect(IDType.cccd.displayNameEn, 'Citizen ID Card');
      expect(IDType.passport.displayNameEn, 'Passport');
      expect(IDType.cmnd.displayNameEn, 'Old ID Card');
      expect(IDType.gplx.displayNameEn, "Driver's License");
      expect(IDType.other.displayNameEn, 'Other');
    });

    test('has correct full display names', () {
      expect(IDType.cccd.fullDisplayName, 'CCCD (Căn cước công dân)');
      expect(IDType.passport.fullDisplayName, 'Hộ chiếu');
      expect(IDType.cmnd.fullDisplayName, 'CMND (Chứng minh nhân dân)');
      expect(IDType.gplx.fullDisplayName, 'GPLX (Giấy phép lái xe)');
      expect(IDType.other.fullDisplayName, 'Khác');
    });

    test('has correct icons', () {
      expect(IDType.cccd.icon, Icons.badge);
      expect(IDType.passport.icon, Icons.flight);
      expect(IDType.cmnd.icon, Icons.credit_card);
      expect(IDType.gplx.icon, Icons.drive_eta);
      expect(IDType.other.icon, Icons.description);
    });
  });

  group('Gender', () {
    test('has correct display names in Vietnamese', () {
      expect(Gender.male.displayName, 'Nam');
      expect(Gender.female.displayName, 'Nữ');
      expect(Gender.other.displayName, 'Khác');
    });

    test('has correct display names in English', () {
      expect(Gender.male.displayNameEn, 'Male');
      expect(Gender.female.displayNameEn, 'Female');
      expect(Gender.other.displayNameEn, 'Other');
    });

    test('has correct icons', () {
      expect(Gender.male.icon, Icons.male);
      expect(Gender.female.icon, Icons.female);
      expect(Gender.other.icon, Icons.person);
    });
  });

  group('Nationalities', () {
    test('contains common nationalities', () {
      expect(Nationalities.common, contains('Vietnam'));
      expect(Nationalities.common, contains('China'));
      expect(Nationalities.common, contains('South Korea'));
      expect(Nationalities.common, contains('Japan'));
      expect(Nationalities.common, contains('USA'));
    });

    test('getDisplayName returns Vietnamese for common nationalities', () {
      expect(Nationalities.getDisplayName('Vietnam'), 'Việt Nam');
      expect(Nationalities.getDisplayName('China'), 'Trung Quốc');
      expect(Nationalities.getDisplayName('South Korea'), 'Hàn Quốc');
      expect(Nationalities.getDisplayName('Japan'), 'Nhật Bản');
      expect(Nationalities.getDisplayName('USA'), 'Mỹ');
      expect(Nationalities.getDisplayName('France'), 'Pháp');
      expect(Nationalities.getDisplayName('UK'), 'Anh');
      expect(Nationalities.getDisplayName('Australia'), 'Úc');
    });

    test('getDisplayName returns input for unknown nationalities', () {
      expect(Nationalities.getDisplayName('Canada'), 'Canada');
      expect(Nationalities.getDisplayName('Unknown'), 'Unknown');
    });
  });

  group('Guest', () {
    const testGuest = Guest(
      id: 1,
      fullName: 'Nguyễn Văn A',
      phone: '0901234567',
      email: 'test@example.com',
      idType: IDType.cccd,
      idNumber: '012345678901',
      nationality: 'Vietnam',
      isVip: false,
      totalStays: 5,
      bookingCount: 3,
    );

    test('creates from constructor', () {
      expect(testGuest.id, 1);
      expect(testGuest.fullName, 'Nguyễn Văn A');
      expect(testGuest.phone, '0901234567');
      expect(testGuest.email, 'test@example.com');
      expect(testGuest.idType, IDType.cccd);
      expect(testGuest.idNumber, '012345678901');
      expect(testGuest.nationality, 'Vietnam');
      expect(testGuest.isVip, isFalse);
    });

    test('creates via Guest.create factory', () {
      final guest = Guest.create(
        fullName: 'Test User',
        phone: '0987654321',
        email: 'user@test.com',
        nationality: 'Japan',
        isVip: true,
      );

      expect(guest.id, 0); // Assigned by backend
      expect(guest.fullName, 'Test User');
      expect(guest.phone, '0987654321');
      expect(guest.email, 'user@test.com');
      expect(guest.nationality, 'Japan');
      expect(guest.isVip, isTrue);
    });

    test('initials returns correct initials from full name', () {
      expect(testGuest.initials, 'NA');

      const singleNameGuest = Guest(
        id: 2,
        fullName: 'John',
        phone: '0901111111',
      );
      expect(singleNameGuest.initials, 'J');

      const threeNameGuest = Guest(
        id: 3,
        fullName: 'Nguyễn Thị Hoa',
        phone: '0902222222',
      );
      expect(threeNameGuest.initials, 'NH');
    });

    test('nationalityDisplay returns Vietnamese display name', () {
      expect(testGuest.nationalityDisplay, 'Việt Nam');

      const japaneseGuest = Guest(
        id: 2,
        fullName: 'Tanaka',
        phone: '0901111111',
        nationality: 'Japan',
      );
      expect(japaneseGuest.nationalityDisplay, 'Nhật Bản');
    });

    test('age calculates correctly from dateOfBirth', () {
      final guestWithBirthday = Guest(
        id: 2,
        fullName: 'Test',
        phone: '0901111111',
        dateOfBirth: DateTime(1990, 6, 15),
      );

      final now = DateTime.now();
      final expectedAge =
          now.year -
          1990 -
          (now.month < 6 || (now.month == 6 && now.day < 15) ? 1 : 0);

      expect(guestWithBirthday.age, expectedAge);
    });

    test('age returns null when dateOfBirth is null', () {
      expect(testGuest.age, isNull);
    });

    test('formattedPhone formats 10-digit phone correctly', () {
      expect(testGuest.formattedPhone, '0901 234 567');
    });

    test('formattedPhone formats 11-digit phone correctly', () {
      const guest11Digit = Guest(id: 2, fullName: 'Test', phone: '02812345678');
      expect(guest11Digit.formattedPhone, '0281 2345 678');
    });

    test('formattedPhone returns original for non-standard length', () {
      const guestShortPhone = Guest(id: 2, fullName: 'Test', phone: '123');
      expect(guestShortPhone.formattedPhone, '123');
    });

    test('vipColor returns correct color based on VIP status', () {
      expect(testGuest.vipColor, const Color(0xFF9E9E9E));

      const vipGuest = Guest(
        id: 2,
        fullName: 'VIP',
        phone: '0901111111',
        isVip: true,
      );
      expect(vipGuest.vipColor, const Color(0xFFFFD700));
    });

    test('vipIcon returns correct icon based on VIP status', () {
      expect(testGuest.vipIcon, Icons.star_border);

      const vipGuest = Guest(
        id: 2,
        fullName: 'VIP',
        phone: '0901111111',
        isVip: true,
      );
      expect(vipGuest.vipIcon, Icons.star);
    });

    test('hasCompleteProfile checks required fields', () {
      const incompleteGuest = Guest(
        id: 1,
        fullName: 'Test',
        phone: '0901234567',
      );
      expect(incompleteGuest.hasCompleteProfile, isFalse);

      const completeGuest = Guest(
        id: 2,
        fullName: 'Test',
        phone: '0901234567',
        idNumber: '012345678901',
      );
      expect(completeGuest.hasCompleteProfile, isTrue);
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 1,
        'full_name': 'Nguyễn Văn B',
        'phone': '0901234567',
        'email': 'b@test.com',
        'id_type': 'cccd',
        'id_number': '012345678901',
        'nationality': 'Vietnam',
        'is_vip': true,
        'total_stays': 10,
        'booking_count': 5,
        'is_returning_guest': true,
      };

      final guest = Guest.fromJson(json);
      expect(guest.id, 1);
      expect(guest.fullName, 'Nguyễn Văn B');
      expect(guest.phone, '0901234567');
      expect(guest.email, 'b@test.com');
      expect(guest.idType, IDType.cccd);
      expect(guest.idNumber, '012345678901');
      expect(guest.nationality, 'Vietnam');
      expect(guest.isVip, isTrue);
      expect(guest.totalStays, 10);
      expect(guest.bookingCount, 5);
      expect(guest.isReturningGuest, isTrue);
    });
  });

  group('GuestListResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'count': 2,
        'next': 'http://api.com/guests?page=2',
        'previous': null,
        'results': [
          {'id': 1, 'full_name': 'Guest 1', 'phone': '0901111111'},
          {'id': 2, 'full_name': 'Guest 2', 'phone': '0902222222'},
        ],
      };

      final response = GuestListResponse.fromJson(json);
      expect(response.count, 2);
      expect(response.next, 'http://api.com/guests?page=2');
      expect(response.previous, isNull);
      expect(response.results.length, 2);
      expect(response.results[0].fullName, 'Guest 1');
      expect(response.results[1].fullName, 'Guest 2');
    });
  });

  group('GuestSearchRequest', () {
    test('creates from constructor', () {
      const request = GuestSearchRequest(query: 'test', searchBy: 'name');

      expect(request.query, 'test');
      expect(request.searchBy, 'name');
    });

    test('has default searchBy value', () {
      const request = GuestSearchRequest(query: 'test');
      expect(request.searchBy, 'all');
    });
  });

  group('GuestBookingSummary', () {
    test('deserializes from JSON', () {
      final json = {
        'id': 1,
        'room_number': '101',
        'room_type_name': 'Phòng đơn',
        'check_in_date': '2024-01-15T14:00:00.000',
        'check_out_date': '2024-01-17T12:00:00.000',
        'status': 'checked_out',
        'status_display': 'Đã trả phòng',
        'total_amount': 600000,
        'is_paid': true,
      };

      final booking = GuestBookingSummary.fromJson(json);
      expect(booking.id, 1);
      expect(booking.roomNumber, '101');
      expect(booking.roomTypeName, 'Phòng đơn');
      expect(booking.status, 'checked_out');
      expect(booking.statusDisplay, 'Đã trả phòng');
      expect(booking.totalAmount, 600000);
      expect(booking.isPaid, isTrue);
    });
  });

  group('GuestHistoryResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'guest': {'id': 1, 'full_name': 'Test Guest', 'phone': '0901234567'},
        'bookings': [
          {
            'id': 1,
            'room_number': '101',
            'check_in_date': '2024-01-15T14:00:00.000',
            'check_out_date': '2024-01-17T12:00:00.000',
            'status': 'checked_out',
            'total_amount': 600000,
          },
        ],
        'total_bookings': 1,
        'total_stays': 2,
        'total_spent': 600000,
      };

      final response = GuestHistoryResponse.fromJson(json);
      expect(response.guest.fullName, 'Test Guest');
      expect(response.bookings.length, 1);
      expect(response.totalBookings, 1);
      expect(response.totalStays, 2);
      expect(response.totalSpent, 600000);
    });
  });
}
