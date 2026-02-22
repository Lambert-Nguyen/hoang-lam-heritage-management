import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/core/utils/currency_formatter.dart';
import 'package:hoang_lam_app/models/dashboard.dart';
import 'package:hoang_lam_app/widgets/dashboard/dashboard_revenue_card.dart';

void main() {
  group('DashboardRevenueCard', () {
    late TodaySummary mockTodaySummary;

    setUp(() {
      mockTodaySummary = TodaySummary(
        date: '2026-01-28',
        checkIns: 2,
        checkOuts: 1,
        pendingArrivals: 3,
        pendingDepartures: 2,
      );
    });

    testWidgets('displays revenue correctly', (WidgetTester tester) async {
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
            body: DashboardRevenueCard(
              todaySummary: mockTodaySummary,
              todayRevenue: 5000000,
              todayExpense: 1000000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doanh thu hôm nay'), findsOneWidget);
      expect(find.text(CurrencyFormatter.formatVND(5000000)), findsOneWidget);
      expect(
        find.text('Chi phí: ${CurrencyFormatter.formatVND(1000000)}'),
        findsOneWidget,
      );
    });

    testWidgets('calculates net profit correctly', (WidgetTester tester) async {
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
            body: DashboardRevenueCard(
              todaySummary: mockTodaySummary,
              todayRevenue: 5000000,
              todayExpense: 1000000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Net = 4,000,000
      expect(
        find.text('+${CurrencyFormatter.formatCompact(4000000)}'),
        findsOneWidget,
      );
    });

    testWidgets('handles zero revenue', (WidgetTester tester) async {
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
            body: DashboardRevenueCard(
              todaySummary: mockTodaySummary,
              todayRevenue: 0,
              todayExpense: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(CurrencyFormatter.formatVND(0)), findsOneWidget);
    });

    testWidgets('handles null revenue and expense', (
      WidgetTester tester,
    ) async {
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
            body: DashboardRevenueCard(todaySummary: mockTodaySummary),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(CurrencyFormatter.formatVND(0)), findsOneWidget);
    });

    testWidgets('displays negative net correctly', (WidgetTester tester) async {
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
            body: DashboardRevenueCard(
              todaySummary: mockTodaySummary,
              todayRevenue: 1000000,
              todayExpense: 2000000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Net = -1,000,000
      expect(
        find.text(CurrencyFormatter.formatCompact(-1000000)),
        findsOneWidget,
      );
    });

    testWidgets('shows trending up icon', (WidgetTester tester) async {
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
            body: DashboardRevenueCard(
              todaySummary: mockTodaySummary,
              todayRevenue: 5000000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('does not show expense text when expense is zero', (
      WidgetTester tester,
    ) async {
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
            body: DashboardRevenueCard(
              todaySummary: mockTodaySummary,
              todayRevenue: 5000000,
              todayExpense: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Chi phí:'), findsNothing);
    });

    testWidgets('formats large numbers correctly', (WidgetTester tester) async {
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
            body: DashboardRevenueCard(
              todaySummary: mockTodaySummary,
              todayRevenue: 125000000, // 125 million
              todayExpense: 25000000, // 25 million
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(CurrencyFormatter.formatVND(125000000)), findsOneWidget);
      expect(
        find.text('Chi phí: ${CurrencyFormatter.formatVND(25000000)}'),
        findsOneWidget,
      );
    });
  });
}
