import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/widgets/finance/record_deposit_dialog.dart';

void main() {
  group('RecordDepositDialog', () {
    Widget buildTestWidget({
      int bookingId = 1,
      double? suggestedAmount,
      String? roomNumber,
      String? guestName,
    }) {
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
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<dynamic>(
                    context: context,
                    builder: (context) => RecordDepositDialog(
                      bookingId: bookingId,
                      suggestedAmount: suggestedAmount,
                      roomNumber: roomNumber,
                      guestName: guestName,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );
    }

    testWidgets('displays dialog title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('Ghi nhận đặt cọc'), findsOneWidget);
    });

    testWidgets('displays room number when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(roomNumber: '101'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Phòng 101'), findsOneWidget);
    });

    testWidgets('displays guest name when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(guestName: 'Nguyễn Văn A'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('displays both room and guest when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        roomNumber: '102',
        guestName: 'Trần Văn B',
      ));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Phòng 102'), findsOneWidget);
      expect(find.textContaining('Trần Văn B'), findsOneWidget);
    });

    testWidgets('pre-fills suggested amount', (tester) async {
      await tester.pumpWidget(buildTestWidget(suggestedAmount: 500000));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('500000'), findsOneWidget);
    });

    testWidgets('displays amount field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('Số tiền cọc'), findsOneWidget);
    });

    testWidgets('displays payment method options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('Tiền mặt'), findsOneWidget);
    });

    testWidgets('displays notes field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('Ghi chú (tùy chọn)'), findsOneWidget);
    });

    testWidgets('displays cancel button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('displays submit button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('Ghi nhận'), findsOneWidget);
    });

    testWidgets('closes dialog when cancel pressed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      
      expect(find.text('Ghi nhận đặt cọc'), findsNothing);
    });

    testWidgets('validates empty amount', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      // Try to submit without entering amount
      await tester.tap(find.text('Ghi nhận'));
      await tester.pumpAndSettle();
      
      // Should show validation error
      expect(find.textContaining('Vui lòng nhập'), findsOneWidget);
    });

    testWidgets('allows entering amount', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      // Find the first TextFormField (amount field)
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, '1000000');
      await tester.pumpAndSettle();
      
      expect(find.text('1,000,000'), findsOneWidget); // Formatted with thousands separator
    });

    testWidgets('allows entering notes', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      // Find the second TextFormField (notes field) - after amount field
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(1), 'Test note');
      await tester.pumpAndSettle();
      
      expect(find.text('Test note'), findsOneWidget);
    });

    testWidgets('can select different payment method', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      // Look for payment method chips - "Chuyển khoản" should exist
      expect(find.text('Chuyển khoản'), findsOneWidget);
      
      // Tap on bank transfer chip
      await tester.tap(find.text('Chuyển khoản'));
      await tester.pumpAndSettle();
      
      // Chip should be selected (visual change, hard to test explicitly)
    });

    testWidgets('does not pre-fill when suggestedAmount is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(suggestedAmount: null));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      // Amount field should be empty - check by looking for hint text visible
      expect(find.text('Nhập số tiền'), findsOneWidget);
    });

    testWidgets('does not pre-fill when suggestedAmount is zero', (tester) async {
      await tester.pumpWidget(buildTestWidget(suggestedAmount: 0));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      // Amount field should be empty - check by looking for hint text visible
      expect(find.text('Nhập số tiền'), findsOneWidget);
    });
  });
}
