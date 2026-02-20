import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';

import 'package:hoang_lam_app/core/theme/app_colors.dart';
import 'package:hoang_lam_app/models/booking.dart';
import 'package:hoang_lam_app/widgets/bookings/booking_status_badge.dart';

void main() {
  group('BookingStatusBadge Widget Tests', () {
    testWidgets('displays pending status correctly', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.pending,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chờ xác nhận'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('displays confirmed status correctly', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.confirmed,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã xác nhận'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays checked-in status correctly', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.checkedIn,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã nhận phòng'), findsOneWidget);
      expect(find.byIcon(Icons.hotel), findsOneWidget);
    });

    testWidgets('displays checked-out status correctly', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.checkedOut,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã trả phòng'), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('displays cancelled status correctly', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.cancelled,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã hủy'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays no-show status correctly', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.noShow,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không đến'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('compact mode hides label text', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.confirmed,
              compact: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In compact mode, text should not be visible
      expect(find.text('Đã xác nhận'), findsNothing);

      // But icon should still be present
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('normal mode shows both icon and label', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.confirmed,
              compact: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both text and icon should be visible
      expect(find.text('Đã xác nhận'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('has proper color coding for each status', (tester) async {
      final statusColors = {
        BookingStatus.pending: AppColors.warning,
        BookingStatus.confirmed: AppColors.statusBlue,
        BookingStatus.checkedIn: AppColors.success,
        BookingStatus.checkedOut: AppColors.mutedAccent,
        BookingStatus.cancelled: AppColors.error,
        BookingStatus.noShow: AppColors.error,
      };

      for (final entry in statusColors.entries) {
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
              body: BookingStatusBadge(
                status: entry.key,
              ),
            ),
          ),
        );
      await tester.pumpAndSettle();

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(BookingStatusBadge),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, entry.value);
      }
    });

    testWidgets('has rounded corners', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.confirmed,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BookingStatusBadge),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
      expect(
        (decoration.borderRadius as BorderRadius).topLeft.x,
        12,
      );
    });

    testWidgets('compact mode has smaller padding', (tester) async {
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
                BookingStatusBadge(
                  status: BookingStatus.confirmed,
                  compact: true,
                ),
                BookingStatusBadge(
                  status: BookingStatus.confirmed,
                  compact: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(BookingStatusBadge),
          matching: find.byType(Container),
        ),
      );

      final compactContainer = containers.first;
      final normalContainer = containers.last;

      final compactPadding = compactContainer.padding as EdgeInsets;
      final normalPadding = normalContainer.padding as EdgeInsets;

      expect(compactPadding.horizontal, lessThan(normalPadding.horizontal));
      expect(compactPadding.vertical, lessThan(normalPadding.vertical));
    });

    testWidgets('icon and text are white colored', (tester) async {
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
            body: BookingStatusBadge(
              status: BookingStatus.confirmed,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.white);

      final text = tester.widget<Text>(
        find.text('Đã xác nhận'),
      );
      expect(text.style?.color, Colors.white);
    });

    testWidgets('compact mode has smaller icon size', (tester) async {
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
                BookingStatusBadge(
                  status: BookingStatus.confirmed,
                  compact: true,
                ),
                BookingStatusBadge(
                  status: BookingStatus.confirmed,
                  compact: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icons = tester.widgetList<Icon>(find.byType(Icon));

      final compactIcon = icons.first;
      final normalIcon = icons.last;

      expect(compactIcon.size, 12);
      expect(normalIcon.size, 14);
    });
  });
}
