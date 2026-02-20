import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/guest.dart';
import 'package:hoang_lam_app/widgets/guests/guest_card.dart';

void main() {
  const testGuest = Guest(
    id: 1,
    fullName: 'Nguyễn Văn A',
    phone: '0901234567',
    email: 'test@example.com',
    idType: IDType.cccd,
    idNumber: '012345678901',
    nationality: 'Vietnam',
    isVip: false,
    totalStays: 5,
    bookingCount: 3,
  );

  const vipGuest = Guest(
    id: 2,
    fullName: 'Trần Thị B',
    phone: '0987654321',
    email: 'vip@example.com',
    idType: IDType.passport,
    idNumber: 'B12345678',
    nationality: 'Japan',
    isVip: true,
    totalStays: 10,
    bookingCount: 8,
  );

  Widget buildTestWidget({
    Guest? guest,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool showVipBadge = true,
    bool showBookingCount = true,
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
        body: Center(
          child: GuestCard(
            guest: guest ?? testGuest,
            onTap: onTap,
            onLongPress: onLongPress,
            showVipBadge: showVipBadge,
            showBookingCount: showBookingCount,
          ),
        ),
      ),
    );
  }

  group('GuestCard', () {
    testWidgets('displays guest full name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('displays formatted phone number', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('0901 234 567'), findsOneWidget);
    });

    testWidgets('displays guest initials in avatar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('NA'), findsOneWidget);
    });

    testWidgets('displays ID type', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CCCD'), findsOneWidget);
    });

    testWidgets('displays nationality', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Việt Nam'), findsOneWidget);
    });

    testWidgets('displays booking count when showBookingCount is true', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('3 lần'), findsOneWidget);
    });

    testWidgets('hides booking count when showBookingCount is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(showBookingCount: false));
      await tester.pumpAndSettle();

      expect(find.text('3 lần'), findsNothing);
    });

    testWidgets('does not show VIP badge for non-VIP guest', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('VIP'), findsNothing);
    });

    testWidgets('shows VIP badge for VIP guest', (tester) async {
      await tester.pumpWidget(buildTestWidget(guest: vipGuest));
      await tester.pumpAndSettle();

      expect(find.text('VIP'), findsOneWidget);
    });

    testWidgets('hides VIP badge when showVipBadge is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        guest: vipGuest,
        showVipBadge: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('VIP'), findsNothing);
    });

    testWidgets('displays passport ID type for passport guest', (tester) async {
      await tester.pumpWidget(buildTestWidget(guest: vipGuest));
      await tester.pumpAndSettle();

      expect(find.text('Hộ chiếu'), findsOneWidget);
    });

    testWidgets('displays Japanese nationality correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(guest: vipGuest));
      await tester.pumpAndSettle();

      expect(find.text('Nhật Bản'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildTestWidget(
        onTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GuestCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long pressed', (tester) async {
      var longPressed = false;

      await tester.pumpWidget(buildTestWidget(
        onLongPress: () => longPressed = true,
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(GuestCard));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('displays phone icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    });

    testWidgets('displays chevron right icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('GuestCompactCard', () {
    Widget buildCompactWidget({
      Guest? guest,
      VoidCallback? onTap,
      bool isSelected = false,
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
          body: Center(
            child: GuestCompactCard(
              guest: guest ?? testGuest,
              onTap: onTap,
              isSelected: isSelected,
            ),
          ),
        ),
      );
    }

    testWidgets('displays guest full name', (tester) async {
      await tester.pumpWidget(buildCompactWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('displays formatted phone number', (tester) async {
      await tester.pumpWidget(buildCompactWidget());
      await tester.pumpAndSettle();

      expect(find.text('0901 234 567'), findsOneWidget);
    });

    testWidgets('displays guest initials in avatar', (tester) async {
      await tester.pumpWidget(buildCompactWidget());
      await tester.pumpAndSettle();

      expect(find.text('NA'), findsOneWidget);
    });

    testWidgets('shows star icon for VIP guest', (tester) async {
      await tester.pumpWidget(buildCompactWidget(guest: vipGuest));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('does not show star icon for non-VIP guest', (tester) async {
      await tester.pumpWidget(buildCompactWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(buildCompactWidget(isSelected: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('does not show check icon when not selected', (tester) async {
      await tester.pumpWidget(buildCompactWidget(isSelected: false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildCompactWidget(
        onTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GuestCompactCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
