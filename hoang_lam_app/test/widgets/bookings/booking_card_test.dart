import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/models/booking.dart';
import '../../../lib/widgets/bookings/booking_card.dart';
import '../../../lib/widgets/bookings/booking_status_badge.dart';

void main() {
  group('BookingCard Widget Tests', () {
    late Booking testBooking;

    setUp(() {
      testBooking = Booking(
        id: 1,
        room: 101,
        roomNumber: '101',
        guest: 1,
        guestDetails: const GuestSummary(
          id: 1,
          fullName: 'Nguyễn Văn A',
          phone: '0901234567',
          email: 'nguyenvana@example.com',
        ),
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        nights: 5,
        guestCount: 2,
        nightlyRate: 1000000,
        totalAmount: 5000000,
        status: BookingStatus.confirmed,
        source: BookingSource.bookingCom,
        specialRequests: 'Phòng tầng cao',
        createdAt: DateTime(2024, 1, 10),
        updatedAt: DateTime(2024, 1, 10),
      );
    });

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
            ),
          ),
        ),
      );

      expect(find.byType(BookingCard), findsOneWidget);
      expect(find.byType(BookingStatusBadge), findsOneWidget);
    });

    testWidgets('displays room number when showRoom is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
              showRoom: true,
            ),
          ),
        ),
      );

      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('displays guest name when showGuest is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
              showGuest: true,
            ),
          ),
        ),
      );

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
            ),
          ),
        ),
      );

      final badge = tester.widget<BookingStatusBadge>(
        find.byType(BookingStatusBadge),
      );
      expect(badge.status, BookingStatus.confirmed);
    });

    testWidgets('displays booking dates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
            ),
          ),
        ),
      );

      // Dates are formatted as dd/MM
      expect(find.textContaining('15/01'), findsOneWidget);
      expect(find.textContaining('20/01'), findsOneWidget);
    });

    testWidgets('displays nights count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
            ),
          ),
        ),
      );

      expect(find.textContaining('đêm'), findsOneWidget);
    });

    testWidgets('displays total amount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
            ),
          ),
        ),
      );

      // Amount is formatted with Vietnamese locale
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('compact mode renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
              compact: true,
            ),
          ),
        ),
      );

      // Compact mode should still render the card
      expect(find.byType(BookingCard), findsOneWidget);
      
      // In compact mode, source chip shouldn't be visible
      expect(find.textContaining('Booking.com'), findsNothing);
    });

    testWidgets('hides room when showRoom is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
              showRoom: false,
              showGuest: true,
            ),
          ),
        ),
      );

      // Room number should not be displayed, but guest name should
      expect(find.text('101'), findsNothing);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('displays different statuses correctly', (tester) async {
      final statuses = [
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.checkedIn,
        BookingStatus.checkedOut,
        BookingStatus.cancelled,
      ];

      for (final status in statuses) {
        final booking = testBooking.copyWith(status: status);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(booking: booking),
            ),
          ),
        );

        final badge = tester.widget<BookingStatusBadge>(
          find.byType(BookingStatusBadge),
        );
        expect(badge.status, status);
      }
    });

    testWidgets('handles null room number gracefully', (tester) async {
      final bookingNoRoomNumber = testBooking.copyWith(
        roomNumber: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: bookingNoRoomNumber,
              showRoom: true,
            ),
          ),
        ),
      );

      // Should fall back to room ID
      expect(find.textContaining('Phòng 101'), findsOneWidget);
    });

    testWidgets('handles null guest details gracefully', (tester) async {
      final bookingNoGuest = testBooking.copyWith(
        guestDetails: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: bookingNoGuest,
              showGuest: true,
            ),
          ),
        ),
      );

      // Should show fallback guest ID
      expect(find.textContaining('Khách #1'), findsOneWidget);
    });

    testWidgets('displays deposit info for pending bookings', (tester) async {
      final pendingBooking = testBooking.copyWith(
        status: BookingStatus.pending,
        depositAmount: 1000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: pendingBooking,
              compact: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Đặt cọc'), findsOneWidget);
    });

    testWidgets('displays check-in time for checked-in bookings', (tester) async {
      final checkedInBooking = testBooking.copyWith(
        status: BookingStatus.checkedIn,
        actualCheckIn: DateTime(2024, 1, 15, 14, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: checkedInBooking,
              compact: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Check-in'), findsOneWidget);
    });

    testWidgets('shows chevron icon when onTap is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('wraps in Card widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
