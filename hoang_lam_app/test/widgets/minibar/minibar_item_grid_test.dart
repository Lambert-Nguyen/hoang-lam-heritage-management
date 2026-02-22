import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/minibar.dart';
import 'package:hoang_lam_app/widgets/minibar/minibar_item_card.dart';
import 'package:hoang_lam_app/widgets/minibar/minibar_item_grid.dart';

void main() {
  group('MinibarItemGrid', () {
    late List<MinibarItem> mockItems;

    setUp(() {
      mockItems = [
        const MinibarItem(
          id: 1,
          name: 'Coca Cola',
          price: 25000,
          cost: 15000,
          category: 'beverage',
          isActive: true,
          createdAt: null,
          updatedAt: null,
        ),
        const MinibarItem(
          id: 2,
          name: 'Pepsi',
          price: 23000,
          cost: 14000,
          category: 'beverage',
          isActive: true,
          createdAt: null,
          updatedAt: null,
        ),
        const MinibarItem(
          id: 3,
          name: 'Chips',
          price: 20000,
          cost: 12000,
          category: 'snack',
          isActive: true,
          createdAt: null,
          updatedAt: null,
        ),
        const MinibarItem(
          id: 4,
          name: 'Beer',
          price: 35000,
          cost: 25000,
          category: 'alcohol',
          isActive: false,
          createdAt: null,
          updatedAt: null,
        ),
      ];
    });

    Widget buildWidget({
      List<MinibarItem>? items,
      void Function(MinibarItem)? onItemTap,
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
          body: SizedBox(
            width: 600,
            height: 800,
            child: MinibarItemGrid(
              items: items ?? mockItems,
              onItemTap: onItemTap,
            ),
          ),
        ),
      );
    }

    testWidgets('displays all items in grid', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Should find all item names
      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Pepsi'), findsOneWidget);
      expect(find.text('Chips'), findsOneWidget);
      expect(find.text('Beer'), findsOneWidget);
    });

    testWidgets('renders correct number of MinibarItemCards', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MinibarItemCard), findsNWidgets(4));
    });

    testWidgets('calls onItemTap with correct item when tapped', (
      tester,
    ) async {
      MinibarItem? tappedItem;
      await tester.pumpWidget(
        buildWidget(onItemTap: (item) => tappedItem = item),
      );
      await tester.pumpAndSettle();

      // Tap on the first item (Coca Cola)
      await tester.tap(find.text('Coca Cola'));
      await tester.pump();

      expect(tappedItem, isNotNull);
      expect(tappedItem!.id, equals(1));
      expect(tappedItem!.name, equals('Coca Cola'));
    });

    testWidgets('renders as GridView with scrolling', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays empty grid when no items', (tester) async {
      await tester.pumpWidget(buildWidget(items: []));
      await tester.pumpAndSettle();

      expect(find.byType(MinibarItemCard), findsNothing);
    });

    testWidgets('inactive item does not trigger onItemTap', (tester) async {
      MinibarItem? tappedItem;
      await tester.pumpWidget(
        buildWidget(onItemTap: (item) => tappedItem = item),
      );
      await tester.pumpAndSettle();

      // Tap on inactive item (Beer)
      await tester.tap(find.text('Beer'));
      await tester.pump();

      // Should not have tapped
      expect(tappedItem, isNull);
    });

    testWidgets('shows different categories correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Should display category text for each item
      expect(find.text('beverage'), findsNWidgets(2));
      expect(find.text('snack'), findsOneWidget);
      expect(find.text('alcohol'), findsOneWidget);
    });

    testWidgets('grid has proper layout with 3 columns', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Find the GridView and check its delegate
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, equals(3));
    });
  });
}
