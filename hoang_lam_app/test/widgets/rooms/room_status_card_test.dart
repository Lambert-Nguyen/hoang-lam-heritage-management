import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/room.dart';
import 'package:hoang_lam_app/widgets/rooms/room_status_card.dart';

void main() {
  const testRoom = Room(
    id: 1,
    number: '101',
    roomTypeId: 1,
    roomTypeName: 'Phòng đơn',
    floor: 1,
    status: RoomStatus.available,
    baseRate: 300000,
  );

  Widget buildTestWidget({
    Room? room,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
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
          child: RoomStatusCard(
            room: room ?? testRoom,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ),
    );
  }

  group('RoomStatusCard', () {
    testWidgets('displays room number', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('displays status icon for available room', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays status icon for occupied room', (tester) async {
      const occupiedRoom = Room(
        id: 2,
        number: '102',
        roomTypeId: 1,
        status: RoomStatus.occupied,
      );

      await tester.pumpWidget(buildTestWidget(room: occupiedRoom));
      await tester.pumpAndSettle();

      expect(find.text('102'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays status icon for cleaning room', (tester) async {
      const cleaningRoom = Room(
        id: 3,
        number: '103',
        roomTypeId: 1,
        status: RoomStatus.cleaning,
      );

      await tester.pumpWidget(buildTestWidget(room: cleaningRoom));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cleaning_services), findsOneWidget);
    });

    testWidgets('displays status icon for maintenance room', (tester) async {
      const maintenanceRoom = Room(
        id: 4,
        number: '104',
        roomTypeId: 1,
        status: RoomStatus.maintenance,
      );

      await tester.pumpWidget(buildTestWidget(room: maintenanceRoom));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.build), findsOneWidget);
    });

    testWidgets('displays status icon for blocked room', (tester) async {
      const blockedRoom = Room(
        id: 5,
        number: '105',
        roomTypeId: 1,
        status: RoomStatus.blocked,
      );

      await tester.pumpWidget(buildTestWidget(room: blockedRoom));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildTestWidget(
        onTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RoomStatusCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long pressed', (tester) async {
      var longPressed = false;

      await tester.pumpWidget(buildTestWidget(
        onLongPress: () => longPressed = true,
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(RoomStatusCard));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('has correct size (80x80)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 80);
      expect(sizedBox.height, 80);
    });
  });

  group('RoomDetailCard', () {
    testWidgets('displays room number', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RoomDetailCard(room: testRoom),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('displays room type name', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RoomDetailCard(room: testRoom),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Phòng đơn'), findsOneWidget);
    });

    testWidgets('displays status', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RoomDetailCard(room: testRoom),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Trống'), findsOneWidget);
    });

    testWidgets('displays floor info', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RoomDetailCard(room: testRoom),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tầng 1'), findsOneWidget);
    });

    testWidgets('displays formatted rate', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RoomDetailCard(room: testRoom),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('300.000đ'), findsOneWidget);
    });

    testWidgets('displays notes when present', (tester) async {
      const roomWithNotes = Room(
        id: 1,
        number: '101',
        roomTypeId: 1,
        notes: 'VIP guest room',
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RoomDetailCard(room: roomWithNotes),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('VIP guest room'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RoomDetailCard(
            room: testRoom,
            onTap: () => tapped = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RoomDetailCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onStatusTap when status is tapped', (tester) async {
      var statusTapped = false;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RoomDetailCard(
            room: testRoom,
            onStatusTap: () => statusTapped = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Find and tap the status container
      await tester.tap(find.text('Trống'));
      await tester.pump();

      expect(statusTapped, isTrue);
    });
  });
}
