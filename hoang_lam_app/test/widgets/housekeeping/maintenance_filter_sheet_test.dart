import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/housekeeping.dart';
import 'package:hoang_lam_app/providers/housekeeping_provider.dart';
import 'package:hoang_lam_app/widgets/housekeeping/maintenance_filter_sheet.dart';

void main() {
  group('MaintenanceFilterSheet', () {
    Widget buildWidget({
      MaintenanceRequestFilter? initialFilter,
      required void Function(MaintenanceRequestFilter) onApply,
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
          body: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder:
                          (_) => MaintenanceFilterSheet(
                            initialFilter: initialFilter,
                            onApply: onApply,
                          ),
                    );
                  },
                  child: const Text('Open Filter'),
                ),
          ),
        ),
      );
    }

    testWidgets('displays filter sheet when opened', (tester) async {
      await tester.pumpWidget(buildWidget(onApply: (_) {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Title is "Lọc yêu cầu bảo trì"
      expect(find.text('Lọc yêu cầu bảo trì'), findsOneWidget);
    });

    testWidgets('displays status filter section with all statuses', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(onApply: (_) {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Trạng thái'), findsOneWidget);

      // Verify all status displayNames are present
      for (final status in MaintenanceStatus.values) {
        expect(find.text(status.displayName), findsOneWidget);
      }
    });

    testWidgets('displays priority filter section with all priorities', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(onApply: (_) {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Mức ưu tiên'), findsOneWidget);

      // Verify all priority displayNames are present
      for (final priority in MaintenancePriority.values) {
        expect(find.text(priority.displayName), findsOneWidget);
      }
    });

    testWidgets('displays category filter section with all categories', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(onApply: (_) {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Danh mục'), findsOneWidget);

      // Verify all category displayNames are present
      for (final category in MaintenanceCategory.values) {
        expect(find.text(category.displayName), findsOneWidget);
      }
    });

    testWidgets('selects status filter and applies', (tester) async {
      MaintenanceRequestFilter? appliedFilter;
      await tester.pumpWidget(
        buildWidget(onApply: (filter) => appliedFilter = filter),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap on inProgress status (displayName is 'Đang thực hiện')
      await tester.tap(find.text(MaintenanceStatus.inProgress.displayName));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.status, equals(MaintenanceStatus.inProgress));
    });

    testWidgets('selects priority filter and applies', (tester) async {
      MaintenanceRequestFilter? appliedFilter;
      await tester.pumpWidget(
        buildWidget(onApply: (filter) => appliedFilter = filter),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap on urgent priority (displayName is 'Khẩn cấp')
      await tester.tap(find.text(MaintenancePriority.urgent.displayName));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.priority, equals(MaintenancePriority.urgent));
    });

    testWidgets('selects category filter and applies', (tester) async {
      MaintenanceRequestFilter? appliedFilter;
      await tester.pumpWidget(
        buildWidget(onApply: (filter) => appliedFilter = filter),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap on electrical category (displayName is 'Điện')
      await tester.tap(find.text(MaintenanceCategory.electrical.displayName));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.category, equals(MaintenanceCategory.electrical));
    });

    testWidgets('clears all filters when reset button is tapped', (
      tester,
    ) async {
      MaintenanceRequestFilter? appliedFilter;
      await tester.pumpWidget(
        buildWidget(
          initialFilter: MaintenanceRequestFilter(
            status: MaintenanceStatus.pending,
            priority: MaintenancePriority.high,
            category: MaintenanceCategory.plumbing,
          ),
          onApply: (filter) => appliedFilter = filter,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap reset button (text is "Xóa bộ lọc")
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.status, isNull);
      expect(appliedFilter!.priority, isNull);
      expect(appliedFilter!.category, isNull);
    });

    testWidgets('applies multiple filters at once', (tester) async {
      MaintenanceRequestFilter? appliedFilter;
      await tester.pumpWidget(
        buildWidget(onApply: (filter) => appliedFilter = filter),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Select status
      await tester.tap(find.text(MaintenanceStatus.pending.displayName));
      await tester.pump();

      // Select priority
      await tester.tap(find.text(MaintenancePriority.high.displayName));
      await tester.pump();

      // Select category
      await tester.tap(find.text(MaintenanceCategory.electrical.displayName));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.status, equals(MaintenanceStatus.pending));
      expect(appliedFilter!.priority, equals(MaintenancePriority.high));
      expect(appliedFilter!.category, equals(MaintenanceCategory.electrical));
    });
  });
}
