import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/widgets/folio/add_charge_dialog.dart';

void main() {
  group('AddChargeDialog', () {
    Widget buildWidget({
      int bookingId = 1,
      VoidCallback? onChargeAdded,
    }) {
      return ProviderScope(
        child: MaterialApp(
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
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddChargeDialog(
                      bookingId: bookingId,
                      onChargeAdded: onChargeAdded,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
    }

    testWidgets('displays dialog title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.text('Thêm phí'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays type selector', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.text('Loại phí'), findsOneWidget);
    });

    testWidgets('displays description field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.text('Mô tả *'), findsOneWidget);
    });

    testWidgets('displays quantity field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.text('Số lượng *'), findsOneWidget);
    });

    testWidgets('displays unit price field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.text('Đơn giá *'), findsOneWidget);
    });

    testWidgets('displays cancel button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('displays add button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Button text is "Thêm phí"
      expect(find.text('Thêm phí'), findsAtLeastNWidgets(1));
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Thêm phí'), findsNothing);
    });

    testWidgets('quantity field has default value of 1', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Find the quantity text field
      final quantityField = find.widgetWithText(TextFormField, '1');
      expect(quantityField, findsOneWidget);
    });

    testWidgets('shows validation error when description is empty',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Enter valid values except description
      await tester.enterText(
        find.ancestor(
          of: find.text('Đơn giá *'),
          matching: find.byType(TextFormField),
        ),
        '50000',
      );
      await tester.pump();

      // Try to submit - button text is "Thêm phí"
      await tester.tap(find.text('Thêm phí').last);
      await tester.pump();

      expect(find.text('Vui lòng nhập mô tả'), findsOneWidget);
    });

    testWidgets('displays all folio item types', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Check that type chips are displayed
      // The type selector should show various types
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('can enter description text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nhập mô tả chi phí'),
        'Test description',
      );
      await tester.pump();

      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('can change quantity', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Clear and enter new quantity
      final quantityField = find.ancestor(
        of: find.text('Số lượng *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(quantityField, '5');
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders in AlertDialog', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows date picker button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Should have a date field or picker
      expect(find.textContaining('Ngày'), findsOneWidget);
    });

    testWidgets('total updates when quantity or price changes', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Enter unit price
      final priceField = find.ancestor(
        of: find.text('Đơn giá *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(priceField, '100000');
      await tester.pump();

      // Enter quantity
      final quantityField = find.ancestor(
        of: find.text('Số lượng *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(quantityField, '3');
      await tester.pump();

      // Total should show 300,000
      expect(find.textContaining('300.000'), findsOneWidget);
    });
  });
}
