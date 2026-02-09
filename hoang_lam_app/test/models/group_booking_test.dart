import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/group_booking.dart';
import 'package:hoang_lam_app/models/booking.dart';

void main() {
  group('GroupBookingStatus', () {
    test('all statuses have display names', () {
      for (final status in GroupBookingStatus.values) {
        expect(status.displayName, isNotEmpty);
        expect(status.displayNameEn, isNotEmpty);
      }
    });

    test('all statuses have colors', () {
      for (final status in GroupBookingStatus.values) {
        expect(status.color, isNotNull);
      }
    });

    test('all statuses have icons', () {
      for (final status in GroupBookingStatus.values) {
        expect(status.icon, isNotNull);
      }
    });

    test('tentative is Đang chờ', () {
      expect(GroupBookingStatus.tentative.displayName, 'Đang chờ');
      expect(GroupBookingStatus.tentative.displayNameEn, 'Tentative');
    });

    test('confirmed is Đã xác nhận', () {
      expect(GroupBookingStatus.confirmed.displayName, 'Đã xác nhận');
    });

    test('checkedIn is Đang ở', () {
      expect(GroupBookingStatus.checkedIn.displayName, 'Đang ở');
    });

    test('checkedOut is Đã trả phòng', () {
      expect(GroupBookingStatus.checkedOut.displayName, 'Đã trả phòng');
    });

    test('cancelled is Đã hủy', () {
      expect(GroupBookingStatus.cancelled.displayName, 'Đã hủy');
    });
  });

  group('GroupBooking Model', () {
    final sampleJson = {
      'id': 1,
      'name': 'Tour ABC',
      'contact_name': 'Trần Văn B',
      'contact_phone': '0922222222',
      'contact_email': 'tour@abc.com',
      'company': 'ABC Travel',
      'check_in_date': '2026-02-09',
      'check_out_date': '2026-02-12',
      'actual_check_in': null,
      'actual_check_out': null,
      'nights': 3,
      'room_count': 3,
      'guest_count': 6,
      'rooms': <int>[],
      'room_numbers': <String>[],
      'total_amount': 3600000.0,
      'deposit_amount': 1000000.0,
      'deposit_paid': false,
      'special_rate': 400000.0,
      'discount_percent': 0.0,
      'currency': 'VND',
      'balance_due': 2600000.0,
      'status': 'tentative',
      'source': 'phone',
      'notes': '',
      'special_requests': '',
      'created_by': 1,
    };

    test('fromJson creates valid model', () {
      final gb = GroupBooking.fromJson(sampleJson);
      expect(gb.id, 1);
      expect(gb.name, 'Tour ABC');
      expect(gb.contactName, 'Trần Văn B');
      expect(gb.contactPhone, '0922222222');
      expect(gb.contactEmail, 'tour@abc.com');
      expect(gb.company, 'ABC Travel');
      expect(gb.status, GroupBookingStatus.tentative);
      expect(gb.totalAmount, 3600000.0);
      expect(gb.depositAmount, 1000000.0);
    });

    test('calculated nights from dates', () {
      final gb = GroupBooking.fromJson(sampleJson);
      expect(gb.calculatedNights, 3);
    });

    test('calculated balance due', () {
      final gb = GroupBooking.fromJson(sampleJson);
      expect(gb.calculatedBalanceDue, 2600000.0);
    });

    test('balance due from API takes precedence', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['balance_due'] = 2500000.0;
      final gb = GroupBooking.fromJson(json);
      expect(gb.calculatedBalanceDue, 2500000.0);
    });

    test('balance due calculated when not provided', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json.remove('balance_due');
      final gb = GroupBooking.fromJson(json);
      // 3600000 - 1000000 = 2600000
      expect(gb.calculatedBalanceDue, 2600000.0);
    });

    test('toJson round-trip', () {
      final gb = GroupBooking.fromJson(sampleJson);
      final json = gb.toJson();
      expect(json['name'], 'Tour ABC');
      expect(json['contact_name'], 'Trần Văn B');
      expect(json['total_amount'], 3600000.0);
    });

    test('copyWith works correctly', () {
      final gb = GroupBooking.fromJson(sampleJson);
      final updated = gb.copyWith(name: 'Tour XYZ', guestCount: 10);
      expect(updated.name, 'Tour XYZ');
      expect(updated.guestCount, 10);
      expect(updated.contactName, 'Trần Văn B'); // preserved
    });
  });

  group('GroupBooking Status Transitions', () {
    final sampleJson = {
      'id': 1,
      'name': 'Test Group',
      'contact_name': 'Test',
      'contact_phone': '0900000000',
      'check_in_date': '2026-02-09',
      'check_out_date': '2026-02-11',
      'room_count': 2,
      'guest_count': 4,
      'total_amount': 2000000.0,
      'status': 'tentative',
      'source': 'phone',
    };

    test('tentative can confirm', () {
      final gb = GroupBooking.fromJson(sampleJson);
      expect(gb.canConfirm, true);
    });

    test('tentative can check-in', () {
      final gb = GroupBooking.fromJson(sampleJson);
      expect(gb.canCheckIn, true);
    });

    test('tentative can cancel', () {
      final gb = GroupBooking.fromJson(sampleJson);
      expect(gb.canCancel, true);
    });

    test('confirmed can check-in', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['status'] = 'confirmed';
      final gb = GroupBooking.fromJson(json);
      expect(gb.canCheckIn, true);
      expect(gb.canConfirm, false);
    });

    test('checked-in can check-out', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['status'] = 'checked_in';
      final gb = GroupBooking.fromJson(json);
      expect(gb.canCheckOut, true);
      expect(gb.canCheckIn, false);
    });

    test('checked-out cannot do anything', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['status'] = 'checked_out';
      final gb = GroupBooking.fromJson(json);
      expect(gb.canCheckOut, false);
      expect(gb.canCheckIn, false);
      expect(gb.canConfirm, false);
      expect(gb.canCancel, false);
    });

    test('cancelled cannot do anything', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['status'] = 'cancelled';
      final gb = GroupBooking.fromJson(json);
      expect(gb.canCheckOut, false);
      expect(gb.canCheckIn, false);
      expect(gb.canConfirm, false);
      expect(gb.canCancel, false);
    });
  });

  group('GroupBookingCreate', () {
    test('toJson creates valid payload', () {
      final create = GroupBookingCreate(
        name: 'New Group',
        contactName: 'Contact Person',
        contactPhone: '0911111111',
        checkInDate: '2026-03-01',
        checkOutDate: '2026-03-03',
        roomCount: 3,
        guestCount: 6,
        totalAmount: 3000000,
      );

      final json = create.toJson();
      expect(json['name'], 'New Group');
      expect(json['contact_name'], 'Contact Person');
      expect(json['room_count'], 3);
      expect(json['total_amount'], 3000000);
    });
  });

  group('GroupBookingUpdate', () {
    test('toJson includes only set fields', () {
      final update = GroupBookingUpdate(
        name: 'Updated Name',
        guestCount: 8,
      );

      final json = update.toJson();
      expect(json['name'], 'Updated Name');
      expect(json['guest_count'], 8);
    });
  });

  group('BookingSource', () {
    test('phone source is default for GroupBooking', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'contact_name': 'Test',
        'contact_phone': '0900000000',
        'check_in_date': '2026-02-09',
        'check_out_date': '2026-02-11',
        'room_count': 1,
        'guest_count': 2,
        'total_amount': 1000000.0,
        'status': 'tentative',
      };

      final gb = GroupBooking.fromJson(json);
      expect(gb.source, BookingSource.phone);
    });
  });
}
