import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/booking.dart';
import 'package:hoang_lam_app/models/finance.dart';

Booking _makeBooking({
  int earlyCheckInFee = 0,
  int lateCheckOutFee = 0,
  double earlyCheckInHours = 0,
  double lateCheckOutHours = 0,
  int depositAmount = 0,
  int totalAmount = 1000000,
}) {
  return Booking(
    id: 1,
    room: 1,
    guest: 1,
    roomNumber: '101',
    checkInDate: DateTime(2026, 2, 9),
    checkOutDate: DateTime(2026, 2, 11),
    status: BookingStatus.checkedIn,
    source: BookingSource.walkIn,
    nightlyRate: 500000,
    totalAmount: totalAmount,
    depositAmount: depositAmount,
    earlyCheckInFee: earlyCheckInFee,
    lateCheckOutFee: lateCheckOutFee,
    earlyCheckInHours: earlyCheckInHours,
    lateCheckOutHours: lateCheckOutHours,
  );
}

void main() {
  group('Early/Late Fee Fields in Booking Model', () {
    test('default fee values should be zero', () {
      final booking = _makeBooking();

      expect(booking.earlyCheckInFee, 0);
      expect(booking.lateCheckOutFee, 0);
      expect(booking.earlyCheckInHours, 0);
      expect(booking.lateCheckOutHours, 0);
    });

    test('balance calculation without fees', () {
      final booking = _makeBooking(depositAmount: 500000);

      // total + additional + earlyFee + lateFee - deposit
      // 1000000 + 0 + 0 + 0 - 500000 = 500000
      expect(booking.calculatedBalanceDue, 500000);
    });

    test('balance calculation with early check-in fee', () {
      final booking = _makeBooking(
        depositAmount: 500000,
        earlyCheckInFee: 100000,
        earlyCheckInHours: 2.0,
      );

      // 1000000 + 0 + 100000 + 0 - 500000 = 600000
      expect(booking.calculatedBalanceDue, 600000);
      expect(booking.totalFees, 100000);
    });

    test('balance calculation with late check-out fee', () {
      final booking = _makeBooking(
        depositAmount: 500000,
        lateCheckOutFee: 150000,
        lateCheckOutHours: 3.0,
      );

      // 1000000 + 0 + 0 + 150000 - 500000 = 650000
      expect(booking.calculatedBalanceDue, 650000);
      expect(booking.totalFees, 150000);
    });

    test('balance calculation with both fees', () {
      final booking = _makeBooking(
        depositAmount: 500000,
        earlyCheckInFee: 100000,
        earlyCheckInHours: 2.0,
        lateCheckOutFee: 150000,
        lateCheckOutHours: 3.0,
      );

      // 1000000 + 0 + 100000 + 150000 - 500000 = 750000
      expect(booking.calculatedBalanceDue, 750000);
      expect(booking.totalFees, 250000);
    });

    test('fee fields in JSON serialization', () {
      final json = {
        'id': 1,
        'room': 1,
        'guest': 1,
        'room_number': '101',
        'guest_name': 'Test Guest',
        'check_in_date': '2026-02-09T14:00:00',
        'check_out_date': '2026-02-11T12:00:00',
        'status': 'checked_in',
        'source': 'walk_in',
        'nightly_rate': 500000,
        'total_amount': 1000000,
        'early_check_in_fee': 100000,
        'late_check_out_fee': 150000,
        'early_check_in_hours': 2.0,
        'late_check_out_hours': 3.0,
      };

      final booking = Booking.fromJson(json);
      expect(booking.earlyCheckInFee, 100000);
      expect(booking.lateCheckOutFee, 150000);
      expect(booking.earlyCheckInHours, 2.0);
      expect(booking.lateCheckOutHours, 3.0);
    });

    test('copyWith preserves fee fields', () {
      final booking = _makeBooking(earlyCheckInFee: 100000);

      final updated = booking.copyWith(lateCheckOutFee: 150000);
      expect(updated.earlyCheckInFee, 100000);
      expect(updated.lateCheckOutFee, 150000);
    });
  });

  group('FolioItemType for Early/Late', () {
    test('earlyCheckin type exists', () {
      expect(FolioItemType.earlyCheckin, isNotNull);
      expect(FolioItemType.earlyCheckin.toApiValue, 'early_checkin');
    });

    test('lateCheckout type exists', () {
      expect(FolioItemType.lateCheckout, isNotNull);
      expect(FolioItemType.lateCheckout.toApiValue, 'late_checkout');
    });

    test('earlyCheckin display names', () {
      expect(FolioItemType.earlyCheckin.displayName, 'Nhận sớm');
      expect(FolioItemType.earlyCheckin.displayNameEn, 'Early Check-in');
    });

    test('lateCheckout display names', () {
      expect(FolioItemType.lateCheckout.displayName, 'Trả muộn');
      expect(FolioItemType.lateCheckout.displayNameEn, 'Late Checkout');
    });

    test('earlyCheckin icon', () {
      expect(FolioItemType.earlyCheckin.icon, isNotNull);
    });

    test('lateCheckout icon', () {
      expect(FolioItemType.lateCheckout.icon, isNotNull);
    });
  });
}
