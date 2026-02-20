import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/dashboard.dart';
import 'package:hoang_lam_app/widgets/dashboard/dashboard_occupancy_widget.dart';

void main() {
  group('DashboardOccupancyWidget', () {
    late OccupancySummary mockOccupancy;
    late RoomStatusSummary mockRoomStatus;

    setUp(() {
      mockOccupancy = OccupancySummary(
        rate: 75.5,
        occupiedRooms: 6,
        totalRooms: 8,
      );

      mockRoomStatus = RoomStatusSummary(
        total: 8,
        available: 2,
        occupied: 6,
        cleaning: 0,
        maintenance: 0,
        blocked: 0,
      );
    });

    testWidgets('displays occupancy rate correctly', (WidgetTester tester) async {
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
            body: DashboardOccupancyWidget(
              occupancy: mockOccupancy,
              roomStatus: mockRoomStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tỷ lệ lấp đầy'), findsOneWidget);
      expect(find.text('75.5%'), findsOneWidget);
      expect(find.text('6/8'), findsOneWidget);
    });

    testWidgets('displays room status breakdown', (WidgetTester tester) async {
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
            body: DashboardOccupancyWidget(
              occupancy: mockOccupancy,
              roomStatus: mockRoomStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trống'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Có khách'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('displays circular progress indicator', (WidgetTester tester) async {
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
            body: DashboardOccupancyWidget(
              occupancy: mockOccupancy,
              roomStatus: mockRoomStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('handles 100% occupancy', (WidgetTester tester) async {
      final fullOccupancy = OccupancySummary(
        rate: 100.0,
        occupiedRooms: 8,
        totalRooms: 8,
      );

      final fullRoomStatus = RoomStatusSummary(
        total: 8,
        available: 0,
        occupied: 8,
        cleaning: 0,
        maintenance: 0,
        blocked: 0,
      );

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
            body: DashboardOccupancyWidget(
              occupancy: fullOccupancy,
              roomStatus: fullRoomStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('8/8'), findsOneWidget);
      expect(find.text('Trống'), findsOneWidget); // Available label present
    });

    testWidgets('handles 0% occupancy', (WidgetTester tester) async {
      final emptyOccupancy = OccupancySummary(
        rate: 0.0,
        occupiedRooms: 0,
        totalRooms: 8,
      );

      final emptyRoomStatus = RoomStatusSummary(
        total: 8,
        available: 8,
        occupied: 0,
        cleaning: 0,
        maintenance: 0,
        blocked: 0,
      );

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
            body: DashboardOccupancyWidget(
              occupancy: emptyOccupancy,
              roomStatus: emptyRoomStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('0/8'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // Available count
    });

    testWidgets('shows cleaning status when present', (WidgetTester tester) async {
      final roomStatusWithCleaning = RoomStatusSummary(
        total: 8,
        available: 2,
        occupied: 4,
        cleaning: 2,
        maintenance: 0,
        blocked: 0,
      );

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
            body: DashboardOccupancyWidget(
              occupancy: mockOccupancy,
              roomStatus: roomStatusWithCleaning,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đang dọn'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2)); // Available and Cleaning both = 2
    });

    testWidgets('shows maintenance status when present', (WidgetTester tester) async {
      final roomStatusWithMaintenance = RoomStatusSummary(
        total: 8,
        available: 2,
        occupied: 4,
        cleaning: 0,
        maintenance: 1,
        blocked: 1,
      );

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
            body: DashboardOccupancyWidget(
              occupancy: mockOccupancy,
              roomStatus: roomStatusWithMaintenance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bảo trì'), findsOneWidget);
      expect(find.text('Khóa'), findsOneWidget);
    });

    testWidgets('displays pie chart icon', (WidgetTester tester) async {
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
            body: DashboardOccupancyWidget(
              occupancy: mockOccupancy,
              roomStatus: mockRoomStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    });

    testWidgets('formats decimal occupancy rate correctly', (WidgetTester tester) async {
      final decimalOccupancy = OccupancySummary(
        rate: 66.67,
        occupiedRooms: 4,
        totalRooms: 6,
      );

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
            body: DashboardOccupancyWidget(
              occupancy: decimalOccupancy,
              roomStatus: mockRoomStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('66.7%'), findsOneWidget);
    });
  });
}
