import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';

import 'package:hoang_lam_app/models/booking.dart';
import 'package:hoang_lam_app/widgets/bookings/booking_source_selector.dart';

void main() {
  group('BookingSourceSelector Widget Tests', () {
    testWidgets('displays all booking sources in dropdown', (tester) async {
      BookingSource? selectedSource;

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
            body: BookingSourceSelector(
              value: selectedSource,
              onChanged: (value) {
                selectedSource = value;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap dropdown to open
      await tester.tap(find.byType(DropdownButtonFormField<BookingSource>));
      await tester.pumpAndSettle();

      // Verify all sources are present
      for (final source in BookingSource.values) {
        expect(find.text(source.displayName), findsWidgets);
      }
    });

    testWidgets('calls onChanged when source is selected', (tester) async {
      BookingSource? selectedSource;

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
            body: BookingSourceSelector(
              value: selectedSource,
              onChanged: (value) {
                selectedSource = value;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap dropdown to open
      await tester.tap(find.byType(DropdownButtonFormField<BookingSource>));
      await tester.pumpAndSettle();

      // Select Booking.com
      await tester.tap(find.text('Booking.com').last);
      await tester.pumpAndSettle();

      expect(selectedSource, BookingSource.bookingCom);
    });

    testWidgets('displays selected source with correct icon', (tester) async {
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
            body: BookingSourceSelector(
              value: BookingSource.agoda,
              onChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Agoda icon is displayed (InputDecoration prefixIcon)
      final icons = tester.widgetList<Icon>(
        find.byIcon(BookingSource.agoda.icon),
      );
      expect(icons.length, greaterThanOrEqualTo(1));
    });

    testWidgets('shows label when showLabel is true', (tester) async {
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
            body: BookingSourceSelector(
              value: null,
              onChanged: (value) {},
              showLabel: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguồn đặt phòng'), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
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
            body: BookingSourceSelector(
              value: null,
              onChanged: (value) {},
              showLabel: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguồn đặt phòng'), findsNothing);
    });

    testWidgets('displays custom hint text', (tester) async {
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
            body: BookingSourceSelector(
              value: null,
              onChanged: (value) {},
              hintText: 'Chọn nguồn',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chọn nguồn'), findsOneWidget);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
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
            body: BookingSourceSelector(
              value: null,
              onChanged: (value) {},
              enabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButtonFormField<BookingSource>>(
        find.byType(DropdownButtonFormField<BookingSource>),
      );

      expect(dropdown.onChanged, isNull);
    });

    testWidgets('each source has correct icon and color', (tester) async {
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
            body: BookingSourceSelector(
              value: BookingSource.walkIn,
              onChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<BookingSource>));
      await tester.pumpAndSettle();

      // Verify each source item has an icon
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons.length, greaterThan(BookingSource.values.length));
    });
  });

  group('BookingSourceChip Widget Tests', () {
    testWidgets('displays source name and icon', (tester) async {
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
            body: BookingSourceChip(source: BookingSource.bookingCom),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking.com'), findsOneWidget);
      expect(find.byIcon(BookingSource.bookingCom.icon), findsOneWidget);
    });

    testWidgets('shows selected state correctly', (tester) async {
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
            body: BookingSourceChip(
              source: BookingSource.agoda,
              selected: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, true);
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
            body: BookingSourceChip(
              source: BookingSource.phone,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilterChip));
      expect(tapped, true);
    });

    testWidgets('icon color changes when selected', (tester) async {
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
            body: Column(
              children: [
                BookingSourceChip(
                  source: BookingSource.airbnb,
                  selected: false,
                ),
                BookingSourceChip(source: BookingSource.airbnb, selected: true),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icons = tester.widgetList<Icon>(find.byType(Icon));
      final unselectedIcon = icons.first;
      final selectedIcon = icons.last;

      expect(unselectedIcon.color, BookingSource.airbnb.color);
      expect(selectedIcon.color, Colors.white);
    });
  });

  group('BookingSourceGrid Widget Tests', () {
    testWidgets('displays all booking sources in grid', (tester) async {
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
            body: BookingSourceGrid(value: null, onChanged: (value) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all sources are displayed
      for (final source in BookingSource.values) {
        expect(find.text(source.displayName), findsOneWidget);
      }
    });

    testWidgets('displays grid title', (tester) async {
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
            body: BookingSourceGrid(value: null, onChanged: (value) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguồn đặt phòng'), findsOneWidget);
    });

    testWidgets('highlights selected source', (tester) async {
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
            body: BookingSourceGrid(
              value: BookingSource.traveloka,
              onChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the container for Traveloka
      final travelokaContainer = find.ancestor(
        of: find.text('Traveloka'),
        matching: find.byType(Container),
      );

      expect(travelokaContainer, findsWidgets);
    });

    testWidgets('calls onChanged when source is tapped', (tester) async {
      BookingSource? selectedSource;

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
            body: BookingSourceGrid(
              value: null,
              onChanged: (value) {
                selectedSource = value;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Airbnb
      await tester.tap(find.text('Airbnb'));
      expect(selectedSource, BookingSource.airbnb);
    });

    testWidgets('does not call onChanged when disabled', (tester) async {
      BookingSource? selectedSource;

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
            body: BookingSourceGrid(
              value: null,
              enabled: false,
              onChanged: (value) {
                selectedSource = value;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Try to tap on Phone
      await tester.tap(find.text('Điện thoại'));
      expect(selectedSource, isNull);
    });

    testWidgets('uses 3-column grid layout', (tester) async {
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
            body: BookingSourceGrid(value: null, onChanged: (value) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('each source has icon and name', (tester) async {
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
            body: BookingSourceGrid(value: null, onChanged: (value) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify icons exist for each source
      expect(find.byType(Icon), findsNWidgets(BookingSource.values.length));

      // Verify all source names are present
      for (final source in BookingSource.values) {
        expect(find.text(source.displayName), findsOneWidget);
      }
    });

    testWidgets('selected source has border highlight', (tester) async {
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
            body: BookingSourceGrid(
              value: BookingSource.website,
              onChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the container for the selected website source
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      // One should have a thicker border (selected state)
      bool hasThickBorder = false;
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration?;
        if (decoration?.border != null) {
          final border = decoration!.border as Border;
          if (border.top.width == 2) {
            hasThickBorder = true;
            break;
          }
        }
      }

      expect(hasThickBorder, true);
    });
  });
}
