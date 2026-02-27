import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/night_audit.dart';
import 'package:hoang_lam_app/providers/night_audit_provider.dart';
import 'package:hoang_lam_app/screens/night_audit/night_audit_screen.dart';
import 'package:hoang_lam_app/core/utils/currency_formatter.dart';

void main() {
  late NightAudit mockAudit;

  setUp(() {
    mockAudit = NightAudit(
      id: 1,
      auditDate: DateTime(2026, 1, 28),
      status: NightAuditStatus.draft,
      totalRooms: 10,
      roomsOccupied: 7,
      roomsAvailable: 2,
      roomsCleaning: 1,
      roomsMaintenance: 0,
      occupancyRate: 70.0,
      checkInsToday: 3,
      checkOutsToday: 2,
      noShows: 1,
      cancellations: 0,
      newBookings: 4,
      totalIncome: 5000000,
      roomRevenue: 4000000,
      otherRevenue: 1000000,
      totalExpense: 1200000,
      netRevenue: 3800000,
      cashCollected: 2000000,
      bankTransferCollected: 1500000,
      momoCollected: 500000,
      otherPayments: 800000,
      pendingPayments: 0,
      unpaidBookingsCount: 0,
      notes: '',
      performedByName: 'Admin',
    );
  });

  Widget createTestWidget({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: NightAuditScreen(),
      ),
    );
  }

  group('NightAuditScreen', () {
    testWidgets('shows loading indicator while fetching audit', (
      WidgetTester tester,
    ) async {
      final completer = Completer<NightAudit>();
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid pending futures
      completer.complete(mockAudit);
    });

    testWidgets('displays audit content when data loads', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Kiểm toán cuối ngày'), findsOneWidget);
    });

    testWidgets('shows room statistics card', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Room stats section
      expect(find.text('Thống kê phòng'), findsOneWidget);
      expect(find.text('70% lấp đầy'), findsOneWidget);
      // Room counts
      expect(find.text('10'), findsOneWidget); // total rooms
      expect(find.text('7'), findsOneWidget); // occupied
    });

    testWidgets('shows booking statistics card', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Booking stats section
      expect(find.text('Thống kê đặt phòng'), findsOneWidget);
      expect(find.text('Nhận phòng'), findsOneWidget);
      expect(find.text('Trả phòng'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // check-ins
    });

    testWidgets('shows financial summary card', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Financial overview section
      expect(find.text('Tổng quan tài chính'), findsOneWidget);
      expect(find.text('Tổng thu'), findsOneWidget);
      expect(find.text('Tổng chi phí'), findsOneWidget);
      expect(find.text('Lợi nhuận ròng'), findsOneWidget);

      // Check formatted amounts
      expect(find.text(CurrencyFormatter.format(5000000)), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(1200000)), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(3800000)), findsOneWidget);
    });

    testWidgets('shows payment breakdown card', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Payment details
      expect(find.text('Chi tiết thanh toán'), findsOneWidget);
      expect(find.text('Tiền mặt'), findsOneWidget);
      expect(find.text('Chuyển khoản'), findsOneWidget);
      expect(find.text('MoMo'), findsOneWidget);
    });

    testWidgets('shows status badge for draft audit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nháp'), findsOneWidget);
    });

    testWidgets('shows performed by name', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Admin'), findsOneWidget);
    });

    testWidgets('shows not completed when no performer', (
      WidgetTester tester,
    ) async {
      final unperformedAudit = mockAudit.copyWith(performedByName: null);
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => unperformedAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa hoàn thành'), findsOneWidget);
    });

    testWidgets('shows bottom action buttons for draft audit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should show recalculate and close buttons
      expect(find.text('Tính lại'), findsOneWidget);
      expect(find.text('Đóng kiểm toán'), findsOneWidget);
    });

    testWidgets('hides bottom actions for closed audit', (
      WidgetTester tester,
    ) async {
      final closedAudit = mockAudit.copyWith(status: NightAuditStatus.closed);
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => closedAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should NOT show action buttons
      expect(find.text('Tính lại'), findsNothing);
      expect(find.text('Đóng kiểm toán'), findsNothing);
    });

    testWidgets('shows closed status badge', (WidgetTester tester) async {
      final closedAudit = mockAudit.copyWith(status: NightAuditStatus.closed);
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => closedAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã đóng'), findsOneWidget);
    });

    testWidgets('shows notes section when notes present', (
      WidgetTester tester,
    ) async {
      final auditWithNotes = mockAudit.copyWith(notes: 'Test audit notes');
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => auditWithNotes),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ghi chú'), findsOneWidget);
      expect(find.text('Test audit notes'), findsOneWidget);
    });

    testWidgets('hides notes section when notes empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Notes section header should not appear
      // (only the note-related "Ghi chú" - check it's absent as a section)
      expect(find.byIcon(Icons.note), findsNothing);
    });

    testWidgets('shows pending payments when present', (
      WidgetTester tester,
    ) async {
      final auditWithPending = mockAudit.copyWith(
        pendingPayments: 3000000,
        unpaidBookingsCount: 3,
      );
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => auditWithPending),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Thanh toán chờ'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(3000000)), findsOneWidget);
    });

    testWidgets('shows error display on failure', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith(
              (ref) async => throw Exception('Network error'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('has history button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('has calendar button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows room revenue and other revenue sub-items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Doanh thu phòng'), findsOneWidget);
      expect(find.textContaining('Doanh thu khác'), findsOneWidget);
    });

    testWidgets('shows cleaning and maintenance room stats', (
      WidgetTester tester,
    ) async {
      final auditWithMaintenance = mockAudit.copyWith(roomsMaintenance: 2);
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith(
              (ref) async => auditWithMaintenance,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đang dọn'), findsOneWidget);
      expect(find.text('Bảo trì'), findsOneWidget);
    });

    testWidgets('shows no-shows and cancellations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => mockAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không đến'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('shows 100% occupancy correctly', (WidgetTester tester) async {
      final fullAudit = mockAudit.copyWith(
        occupancyRate: 100.0,
        roomsOccupied: 10,
        roomsAvailable: 0,
      );
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            todayAuditProvider.overrideWith((ref) async => fullAudit),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100% lấp đầy'), findsOneWidget);
    });
  });
}
