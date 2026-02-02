import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/finance.dart';
import 'package:hoang_lam_app/widgets/finance/deposit_status.dart';

void main() {
  group('DepositStatusIndicator', () {
    Widget buildTestWidget({
      double requiredDeposit = 1000000,
      double paidDeposit = 500000,
      bool showLabel = true,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: DepositStatusIndicator(
              requiredDeposit: requiredDeposit,
              paidDeposit: paidDeposit,
              showLabel: showLabel,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('displays progress percentage', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 500000,
      ));

      // 500000 / 1000000 = 50%
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('displays 100% when fully paid', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 1000000,
      ));

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('displays 0% when no deposit paid', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 0,
      ));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('displays check icon when fully paid', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 1000000,
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays warning icon when not fully paid', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 500000,
      ));

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('displays "Đã đủ cọc" when fully paid', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 1000000,
        showLabel: true,
      ));

      expect(find.text('Đã đủ cọc'), findsOneWidget);
    });

    testWidgets('displays "Thiếu cọc" when partially paid', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 500000,
        showLabel: true,
      ));

      expect(find.text('Thiếu cọc'), findsOneWidget);
    });

    testWidgets('displays "Chưa cọc" when no deposit paid', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 0,
        showLabel: true,
      ));

      expect(find.text('Chưa cọc'), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 500000,
        showLabel: false,
      ));

      expect(find.text('Thiếu cọc'), findsNothing);
    });

    testWidgets('displays paid amount', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 500000,
      ));

      expect(find.textContaining('Đã cọc:'), findsOneWidget);
      expect(find.textContaining('500,000'), findsOneWidget);
    });

    testWidgets('displays required amount', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 500000,
      ));

      expect(find.textContaining('Yêu cầu:'), findsOneWidget);
      expect(find.textContaining('1,000,000'), findsOneWidget);
    });

    testWidgets('displays progress bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('handles zero required deposit', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 0,
        paidDeposit: 0,
      ));

      // Should show 0% and not crash
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('caps progress at 100% when overpaid', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        requiredDeposit: 1000000,
        paidDeposit: 1500000, // Overpaid
      ));

      // Should still show 100%, not 150%
      expect(find.text('100%'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('OutstandingDepositCard', () {
    Widget buildTestWidget({
      required OutstandingDeposit deposit,
      VoidCallback? onRecordDeposit,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutstandingDepositCard(
              deposit: deposit,
              onRecordDeposit: onRecordDeposit,
            ),
          ),
        ),
      );
    }

    final testDeposit = OutstandingDeposit(
      bookingId: 1,
      guestName: 'Nguyễn Văn A',
      roomNumber: '101',
      requiredDeposit: 1000000,
      paidDeposit: 300000,
      outstanding: 700000,
      totalAmount: 2000000,
      checkInDate: DateTime(2026, 2, 1),
      checkOutDate: DateTime(2026, 2, 3),
    );

    testWidgets('displays guest name', (tester) async {
      await tester.pumpWidget(buildTestWidget(deposit: testDeposit));

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('displays room number', (tester) async {
      await tester.pumpWidget(buildTestWidget(deposit: testDeposit));

      expect(find.textContaining('101'), findsOneWidget);
    });

    testWidgets('displays outstanding amount', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        deposit: testDeposit,
        onRecordDeposit: () {}, // Required for outstanding to show
      ));

      expect(find.textContaining('Còn thiếu:'), findsOneWidget);
      expect(find.textContaining('700,000'), findsOneWidget);
    });

    testWidgets('displays record deposit button', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        deposit: testDeposit,
        onRecordDeposit: () {},
      ));

      expect(find.text('Ghi cọc'), findsOneWidget);
    });

    testWidgets('calls onRecordDeposit when button tapped', (tester) async {
      bool buttonTapped = false;

      await tester.pumpWidget(buildTestWidget(
        deposit: testDeposit,
        onRecordDeposit: () => buttonTapped = true,
      ));

      await tester.tap(find.text('Ghi cọc'));
      await tester.pumpAndSettle();

      expect(buttonTapped, isTrue);
    });

    testWidgets('displays deposit progress indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget(deposit: testDeposit));

      // Should show the deposit status (30% progress)
      expect(find.text('30%'), findsOneWidget);
    });
  });

  group('OutstandingDepositsList', () {
    Widget buildTestWidget({
      required List<OutstandingDeposit> deposits,
      void Function(OutstandingDeposit)? onRecordDeposit,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: OutstandingDepositsList(
            deposits: deposits,
            onRecordDeposit: onRecordDeposit,
            isLoading: isLoading,
          ),
        ),
      );
    }

    final testDeposits = [
      OutstandingDeposit(
        bookingId: 1,
        guestName: 'Guest 1',
        roomNumber: '101',
        requiredDeposit: 1000000,
        paidDeposit: 500000,
        outstanding: 500000,
        totalAmount: 2000000,
        checkInDate: DateTime(2026, 2, 1),
        checkOutDate: DateTime(2026, 2, 3),
      ),
      OutstandingDeposit(
        bookingId: 2,
        guestName: 'Guest 2',
        roomNumber: '102',
        requiredDeposit: 2000000,
        paidDeposit: 0,
        outstanding: 2000000,
        totalAmount: 4000000,
        checkInDate: DateTime(2026, 2, 2),
        checkOutDate: DateTime(2026, 2, 4),
      ),
    ];

    testWidgets('displays loading indicator when loading', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        deposits: [],
        isLoading: true,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty message when no deposits', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        deposits: [],
        isLoading: false,
      ));

      expect(find.textContaining('Không có'), findsOneWidget);
    });

    testWidgets('displays all deposit cards', (tester) async {
      await tester.pumpWidget(buildTestWidget(deposits: testDeposits));

      expect(find.text('Guest 1'), findsOneWidget);
      expect(find.text('Guest 2'), findsOneWidget);
    });

    testWidgets('calls onRecordDeposit with correct deposit', (tester) async {
      OutstandingDeposit? selectedDeposit;

      await tester.pumpWidget(buildTestWidget(
        deposits: testDeposits,
        onRecordDeposit: (deposit) => selectedDeposit = deposit,
      ));

      // Tap the first "Ghi cọc" button
      await tester.tap(find.text('Ghi cọc').first);
      await tester.pumpAndSettle();

      expect(selectedDeposit?.bookingId, 1);
    });

    testWidgets('displays header with count', (tester) async {
      await tester.pumpWidget(buildTestWidget(deposits: testDeposits));

      expect(find.textContaining('2'), findsWidgets); // Should show count
    });
  });
}
