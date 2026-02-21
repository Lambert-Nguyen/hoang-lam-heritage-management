import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/declaration.dart';
import 'package:hoang_lam_app/providers/declaration_provider.dart';
import 'package:hoang_lam_app/repositories/declaration_repository.dart';
import 'package:hoang_lam_app/screens/declaration/declaration_export_screen.dart';

void main() {
  Widget createTestWidget({
    List<Override> overrides = const [],
  }) {
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
        home: DeclarationExportScreen(),
      ),
    );
  }

  group('DeclarationExportScreen', () {
    testWidgets('displays screen title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Khai báo lưu trú'), findsOneWidget);
    });

    testWidgets('displays info card', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Thông tin'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays form type selection chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Loại biểu mẫu'), findsOneWidget);
      // All three form types
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    testWidgets('displays date range section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Khoảng thời gian'), findsOneWidget);
      expect(find.text('Từ ngày'), findsOneWidget);
      expect(find.text('Đến ngày'), findsOneWidget);
    });

    testWidgets('displays quick select date buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('Hôm qua'), findsOneWidget);
      expect(find.text('7 ngày qua'), findsOneWidget);
      expect(find.text('30 ngày qua'), findsOneWidget);
    });

    testWidgets('displays format selection cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Định dạng file'), findsOneWidget);
      expect(find.text('Excel'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('displays export button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Xuất danh sách'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('can select form type DD10', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap ĐD10 chip
      final dd10Chips = find.byType(ChoiceChip);
      // ĐD10 should be the first chip
      await tester.tap(dd10Chips.first);
      await tester.pumpAndSettle();

      // Should show description for DD10
      expect(
        find.text('Sổ quản lý lưu trú (Nghị định 144/2021)'),
        findsOneWidget,
      );
    });

    testWidgets('can select CSV format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the CSV format card
      await tester.tap(find.text('CSV'));
      await tester.pumpAndSettle();

      // CSV card should now be selected (has description icon)
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('shows loading state during export',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            declarationExportProvider.overrideWith((ref) {
              return _LoadingExportNotifier();
            }),
          ],
        ),
      );
      await tester.pump();

      // Should show loading spinner and "exporting" text
      expect(find.text('Đang xuất...'), findsOneWidget);
    });

    testWidgets('shows exported file card on success',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            declarationExportProvider.overrideWith((ref) {
              return _SuccessExportNotifier('/path/to/file.xlsx');
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should show exported file card
      expect(find.text('File đã được xuất thành công'), findsOneWidget);
      expect(find.text('file.xlsx'), findsOneWidget);
      expect(find.text('Mở'), findsOneWidget);
      expect(find.text('Chia sẻ'), findsOneWidget);
    });

    testWidgets('shows calendar icons in date pickers',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Calendar icons in date picker fields
      expect(find.byIcon(Icons.calendar_today), findsNWidgets(2));
    });

    testWidgets('hides form description when all is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Default is "all" which should not show individual description
      expect(
        find.text('Sổ quản lý lưu trú (Nghị định 144/2021)'),
        findsNothing,
      );
      expect(
        find.text(
            'Phiếu khai báo tạm trú người nước ngoài (Thông tư 04/2015)'),
        findsNothing,
      );
    });
  });
}

/// Fake notifier that stays in loading state
class _LoadingExportNotifier extends DeclarationExportNotifier {
  _LoadingExportNotifier() : super(DeclarationRepository()) {
    state = const DeclarationExportState.loading();
  }
}

/// Fake notifier that returns success state
class _SuccessExportNotifier extends DeclarationExportNotifier {
  _SuccessExportNotifier(String filePath)
      : super(DeclarationRepository()) {
    state = DeclarationExportState.success(filePath: filePath);
  }
}
