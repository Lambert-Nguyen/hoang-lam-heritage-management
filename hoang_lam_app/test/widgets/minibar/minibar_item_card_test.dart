import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/minibar.dart';
import 'package:hoang_lam_app/widgets/minibar/minibar_item_card.dart';

void main() {
  group('MinibarItemCard', () {
    late MinibarItem mockItem;

    setUp(() {
      mockItem = const MinibarItem(
        id: 1,
        name: 'Coca Cola',
        price: 25000,
        cost: 15000,
        category: 'beverage',
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
    });

    Widget buildWidget({MinibarItem? item, VoidCallback? onTap}) {
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
            width: 200,
            height: 250,
            child: MinibarItemCard(item: item ?? mockItem, onTap: onTap),
          ),
        ),
      );
    }

    testWidgets('displays item name correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Coca Cola'), findsOneWidget);
    });

    testWidgets('displays formatted price correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Price should be formatted in Vietnamese currency
      expect(find.textContaining('25.000'), findsOneWidget);
    });

    testWidgets('displays category correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('beverage'), findsOneWidget);
    });

    testWidgets('calls onTap when active item is tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildWidget(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MinibarItemCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when inactive item is tapped', (
      tester,
    ) async {
      bool tapped = false;
      final inactiveItem = const MinibarItem(
        id: 2,
        name: 'Inactive Item',
        price: 30000,
        cost: 20000,
        category: 'snack',
        isActive: false,
        createdAt: null,
        updatedAt: null,
      );

      await tester.pumpWidget(
        buildWidget(item: inactiveItem, onTap: () => tapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MinibarItemCard));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('shows beverage icon for beverage category', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Beverage category should show local_bar icon
      expect(find.byIcon(Icons.local_bar), findsOneWidget);
    });

    testWidgets('shows snack icon for snack category', (tester) async {
      final snackItem = const MinibarItem(
        id: 3,
        name: 'Chips',
        price: 20000,
        cost: 12000,
        category: 'snack',
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );

      await tester.pumpWidget(buildWidget(item: snackItem));
      await tester.pumpAndSettle();

      // Snack category should show bakery_dining icon
      expect(find.byIcon(Icons.bakery_dining), findsOneWidget);
    });

    testWidgets('displays inactive overlay for inactive items', (tester) async {
      final inactiveItem = const MinibarItem(
        id: 4,
        name: 'Inactive Item',
        price: 30000,
        cost: 20000,
        category: 'alcohol',
        isActive: false,
        createdAt: null,
        updatedAt: null,
      );

      await tester.pumpWidget(buildWidget(item: inactiveItem));
      await tester.pumpAndSettle();

      // Should show "Ngừng bán" text for inactive items
      expect(find.text('Ngừng bán'), findsOneWidget);
    });

    testWidgets('different categories display different icons', (tester) async {
      // Test alcohol category
      final alcoholItem = const MinibarItem(
        id: 5,
        name: 'Beer',
        price: 35000,
        cost: 25000,
        category: 'alcohol',
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );

      await tester.pumpWidget(buildWidget(item: alcoholItem));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wine_bar), findsOneWidget);
    });
  });
}
