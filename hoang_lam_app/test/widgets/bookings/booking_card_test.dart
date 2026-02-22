import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hoang_lam_app/models/booking.dart';
import 'package:hoang_lam_app/widgets/bookings/booking_card.dart';
import 'package:hoang_lam_app/widgets/bookings/booking_status_badge.dart';

void main() {
  group('BookingCard Widget Tests', () {
    late Booking testBooking;

    setUpAll(() async {
      // Initialize Vietnamese locale for date formatting
      await initializeDateFormatting('vi', null);
    });

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
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: BookingCard(booking: testBooking)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BookingCard), findsOneWidget);
      expect(find.byType(BookingStatusBadge), findsOneWidget);
    });

    testWidgets('displays room number when showRoom is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: BookingCard(booking: testBooking, showRoom: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('displays guest name when showGuest is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: BookingCard(booking: testBooking, showGuest: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: BookingCard(booking: testBooking)),
        ),
      );
      await tester.pumpAndSettle();

      final badge = tester.widget<BookingStatusBadge>(
        find.byType(BookingStatusBadge),
      );
      expect(badge.status, BookingStatus.confirmed);
    });

    testWidgets('displays booking dates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: BookingCard(booking: testBooking)),
        ),
      );
      await tester.pumpAndSettle();

      // Dates are formatted as dd/MM
      expect(find.textContaining('15/01'), findsOneWidget);
      expect(find.textContaining('20/01'), findsOneWidget);
    });

    testWidgets('displays nights count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: BookingCard(booking: testBooking)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('đêm'), findsOneWidget);
    });

    testWidgets('displays total amount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: BookingCard(booking: testBooking)),
        ),
      );
      await tester.pumpAndSettle();

      // Amount is formatted with Vietnamese locale
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
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
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('compact mode renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: BookingCard(booking: testBooking, compact: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Compact mode should still render the card
      expect(find.byType(BookingCard), findsOneWidget);

      // In compact mode, source chip shouldn't be visible
      expect(find.textContaining('Booking.com'), findsNothing);
    });

    testWidgets('hides room when showRoom is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: BookingCard(
              booking: testBooking,
              showRoom: false,
              showGuest: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: Scaffold(body: BookingCard(booking: booking)),
          ),
        );
        await tester.pumpAndSettle();

        final badge = tester.widget<BookingStatusBadge>(
          find.byType(BookingStatusBadge),
        );
        expect(badge.status, status);
      }
    });

    testWidgets('handles null room number gracefully', (tester) async {
      final bookingNoRoomNumber = testBooking.copyWith(roomNumber: null);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: BookingCard(booking: bookingNoRoomNumber, showRoom: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should fall back to room ID
      expect(find.textContaining('Phòng 101'), findsOneWidget);
    });

    testWidgets('handles null guest details gracefully', (tester) async {
      final bookingNoGuest = testBooking.copyWith(guestDetails: null);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: BookingCard(booking: bookingNoGuest, showGuest: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: BookingCard(booking: pendingBooking, compact: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Đặt cọc'), findsOneWidget);
    });

    testWidgets('displays check-in time for checked-in bookings', (
      tester,
    ) async {
      final checkedInBooking = testBooking.copyWith(
        status: BookingStatus.checkedIn,
        actualCheckIn: DateTime(2024, 1, 15, 14, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: BookingCard(booking: checkedInBooking, compact: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Check-in'), findsOneWidget);
    });

    testWidgets('shows chevron icon when onTap is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: BookingCard(booking: testBooking, onTap: () {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('wraps in Card widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: BookingCard(booking: testBooking)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
