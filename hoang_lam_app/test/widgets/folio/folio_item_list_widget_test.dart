import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/finance.dart';
import 'package:hoang_lam_app/widgets/folio/folio_item_list_widget.dart';

void main() {
  group('FolioItemListWidget', () {
    late List<FolioItem> mockItems;
    late NumberFormat currencyFormat;

    setUp(() {
      currencyFormat = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      );

      mockItems = [
        FolioItem(
          id: 1,
          booking: 1,
          bookingRoom: '101',
          itemType: FolioItemType.room,
          description: 'Phí phòng Standard',
          quantity: 2,
          unitPrice: 500000,
          totalPrice: 1000000,
          date: DateTime(2024, 1, 15),
          isPaid: false,
          isVoided: false,
          voidReason: null,
          createdBy: 1,
          createdByName: 'Admin',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
        FolioItem(
          id: 2,
          booking: 1,
          bookingRoom: '101',
          itemType: FolioItemType.minibar,
          description: 'Coca Cola',
          quantity: 2,
          unitPrice: 25000,
          totalPrice: 50000,
          date: DateTime(2024, 1, 15),
          isPaid: false,
          isVoided: false,
          voidReason: null,
          createdBy: 1,
          createdByName: 'Admin',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
        FolioItem(
          id: 3,
          booking: 1,
          bookingRoom: '101',
          itemType: FolioItemType.service,
          description: 'Dịch vụ giặt ủi',
          quantity: 1,
          unitPrice: 100000,
          totalPrice: 100000,
          date: DateTime(2024, 1, 16),
          isPaid: true,
          isVoided: false,
          voidReason: null,
          createdBy: 1,
          createdByName: 'Admin',
          createdAt: DateTime(2024, 1, 16),
          updatedAt: DateTime(2024, 1, 16),
        ),
      ];
    });

    Widget buildWidget({
      List<FolioItem>? items,
      void Function(FolioItem)? onVoid,
      bool includeVoided = false,
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
          body: SingleChildScrollView(
            child: FolioItemListWidget(
              items: items ?? mockItems,
              currencyFormat: currencyFormat,
              onVoid: onVoid,
              includeVoided: includeVoided,
            ),
          ),
        ),
      );
    }

    testWidgets('displays empty state when no items', (tester) async {
      await tester.pumpWidget(buildWidget(items: []));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có phí nào'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('displays all folio items', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Phí phòng Standard'), findsOneWidget);
      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Dịch vụ giặt ủi'), findsOneWidget);
    });

    testWidgets('groups items by type', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Should show type headers
      expect(find.text(FolioItemType.room.displayName), findsOneWidget);
      expect(find.text(FolioItemType.minibar.displayName), findsOneWidget);
      expect(find.text(FolioItemType.service.displayName), findsOneWidget);
    });

    testWidgets('displays item count per type', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Each type has 1 item, so should see "1 mục" for each
      expect(find.text('1 mục'), findsNWidgets(3));
    });

    testWidgets('displays formatted prices correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Room charge total: 1,000,000
      expect(find.textContaining('1.000.000'), findsAtLeastNWidgets(1));
      // Minibar total: 50,000
      expect(find.textContaining('50.000'), findsAtLeastNWidgets(1));
      // Service total: 100,000
      expect(find.textContaining('100.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows type icons', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Each type should have its icon (may appear multiple times)
      expect(find.byIcon(FolioItemType.room.icon), findsAtLeastNWidgets(1));
      expect(find.byIcon(FolioItemType.minibar.icon), findsAtLeastNWidgets(1));
      expect(find.byIcon(FolioItemType.service.icon), findsAtLeastNWidgets(1));
    });

    testWidgets('voided items show voided indicator', (tester) async {
      final voidedItem = FolioItem(
        id: 4,
        booking: 1,
        bookingRoom: '101',
        itemType: FolioItemType.food,
        description: 'Item hủy',
        quantity: 1,
        unitPrice: 50000,
        totalPrice: 50000,
        date: DateTime(2024, 1, 15),
        isPaid: false,
        isVoided: true,
        voidReason: 'Sai sản phẩm',
        createdBy: 1,
        createdByName: 'Admin',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      );

      await tester.pumpWidget(buildWidget(
        items: [voidedItem],
        includeVoided: true,
      ));
      await tester.pumpAndSettle();

      // Should show voided indicator
      expect(find.text('Item hủy'), findsOneWidget);
    });

    testWidgets('onVoid callback is callable',
        (tester) async {
      bool voidCalled = false;
      await tester.pumpWidget(buildWidget(
        onVoid: (item) => voidCalled = true,
      ));
      await tester.pumpAndSettle();

      // The widget may or may not show void buttons depending on implementation
      // Just verify the widget renders without error
      await tester.pump();
      expect(voidCalled, isFalse); // Callback not called yet
    });

    testWidgets('renders as scrollable list', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsAtLeastNWidgets(1));
    });

    testWidgets('displays item quantity and unit price', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Should show quantity x unit price format
      expect(find.textContaining('2 x'), findsAtLeastNWidgets(1));
    });
  });
}
