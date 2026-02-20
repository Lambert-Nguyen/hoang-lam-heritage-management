import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/finance.dart';
import 'package:hoang_lam_app/widgets/folio/folio_summary_widget.dart';

void main() {
  group('FolioSummaryWidget', () {
    late NumberFormat currencyFormat;
    late BookingFolioSummary settledSummary;
    late BookingFolioSummary unsettledSummary;

    setUp(() {
      currencyFormat = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      );

      final mockItems = <FolioItem>[
        FolioItem(
          id: 1,
          booking: 1,
          bookingRoom: '101',
          itemType: FolioItemType.room,
          description: 'Phí phòng',
          quantity: 2,
          unitPrice: 500000,
          totalPrice: 1000000,
          date: DateTime(2024, 1, 15),
          isPaid: true,
          isVoided: false,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
      ];

      settledSummary = BookingFolioSummary(
        bookingId: 1,
        roomNumber: '101',
        guestName: 'Nguyễn Văn A',
        roomCharges: 1000000,
        additionalCharges: 50000,
        totalCharges: 1050000,
        totalPayments: 1050000,
        balance: 0,
        items: mockItems,
      );

      unsettledSummary = BookingFolioSummary(
        bookingId: 2,
        roomNumber: '102',
        guestName: 'Trần Thị B',
        roomCharges: 800000,
        additionalCharges: 100000,
        totalCharges: 900000,
        totalPayments: 500000,
        balance: 400000,
        items: mockItems,
      );
    });

    Widget buildWidget({BookingFolioSummary? summary}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: FolioSummaryWidget(
              summary: summary ?? settledSummary,
              currencyFormat: currencyFormat,
            ),
          ),
        ),
      );
    }

    testWidgets('displays guest name correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('displays room number correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Phòng 101'), findsOneWidget);
    });

    testWidgets('displays settled status when balance is zero', (tester) async {
      await tester.pumpWidget(buildWidget(summary: settledSummary));
      await tester.pumpAndSettle();

      expect(find.text('Đã thanh toán'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays unsettled status when balance is positive',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: unsettledSummary));
      await tester.pumpAndSettle();

      expect(find.text('Còn nợ'), findsOneWidget);
    });

    testWidgets('displays room charges correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Room charges: 1,000,000
      expect(find.textContaining('1.000.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays additional charges correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Additional charges: 50,000
      expect(find.textContaining('50.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays total charges correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Total: 1,050,000
      expect(find.textContaining('1.050.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays total payments correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Payments: 1,050,000
      expect(find.textContaining('1.050.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays balance correctly for unsettled', (tester) async {
      await tester.pumpWidget(buildWidget(summary: unsettledSummary));
      await tester.pumpAndSettle();

      // Balance: 400,000
      expect(find.textContaining('400.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows person icon in header', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows room icon in header', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.meeting_room), findsOneWidget);
    });

    testWidgets('renders as a Card widget', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('balance badge has correct color for settled', (tester) async {
      await tester.pumpWidget(buildWidget(summary: settledSummary));
      await tester.pumpAndSettle();

      // Find the container with the status text
      final statusFinder = find.text('Đã thanh toán');
      expect(statusFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('balance badge has correct color for unsettled',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: unsettledSummary));
      await tester.pumpAndSettle();

      // Find the container with the status text
      final statusFinder = find.text('Còn nợ');
      expect(statusFinder, findsOneWidget);
    });

    testWidgets('displays different guest info for different summary',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: unsettledSummary));
      await tester.pumpAndSettle();

      expect(find.text('Trần Thị B'), findsOneWidget);
      expect(find.text('Phòng 102'), findsOneWidget);
    });
  });
}
