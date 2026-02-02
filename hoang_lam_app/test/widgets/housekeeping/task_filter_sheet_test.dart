import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoang_lam_app/models/housekeeping.dart';
import 'package:hoang_lam_app/providers/housekeeping_provider.dart';
import 'package:hoang_lam_app/widgets/housekeeping/task_filter_sheet.dart';

void main() {
  group('TaskFilterSheet', () {
    Widget buildWidget({
      HousekeepingTaskFilter? initialFilter,
      required void Function(HousekeepingTaskFilter) onApply,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => TaskFilterSheet(
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
      await tester.pumpWidget(buildWidget(
        onApply: (_) {},
      ));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Title is "Lọc công việc"
      expect(find.text('Lọc công việc'), findsOneWidget);
    });

    testWidgets('displays status filter section with all statuses',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        onApply: (_) {},
      ));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Trạng thái'), findsOneWidget);

      // Verify all status displayNames are present
      for (final status in HousekeepingTaskStatus.values) {
        expect(find.text(status.displayName), findsOneWidget);
      }
    });

    testWidgets('displays task type filter section with all types',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        onApply: (_) {},
      ));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Loại công việc'), findsOneWidget);

      // Verify all task type displayNames are present
      for (final taskType in HousekeepingTaskType.values) {
        expect(find.text(taskType.displayName), findsOneWidget);
      }
    });

    testWidgets('displays date filter section', (tester) async {
      await tester.pumpWidget(buildWidget(
        onApply: (_) {},
      ));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Ngày dự kiến'), findsOneWidget);
      expect(find.text('Chọn ngày'), findsOneWidget);
    });

    testWidgets('displays quick date filter buttons', (tester) async {
      await tester.pumpWidget(buildWidget(
        onApply: (_) {},
      ));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('Ngày mai'), findsOneWidget);
      expect(find.text('Hôm qua'), findsOneWidget);
    });

    testWidgets('selects status filter and applies', (tester) async {
      HousekeepingTaskFilter? appliedFilter;
      await tester.pumpWidget(buildWidget(
        onApply: (filter) => appliedFilter = filter,
      ));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap on inProgress status (displayName is 'Đang làm')
      await tester.tap(find.text(HousekeepingTaskStatus.inProgress.displayName));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.status, equals(HousekeepingTaskStatus.inProgress));
    });

    testWidgets('selects task type filter and applies', (tester) async {
      HousekeepingTaskFilter? appliedFilter;
      await tester.pumpWidget(buildWidget(
        onApply: (filter) => appliedFilter = filter,
      ));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap on deepClean type (displayName is 'Dọn sâu')
      await tester.tap(find.text(HousekeepingTaskType.deepClean.displayName));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.taskType, equals(HousekeepingTaskType.deepClean));
    });

    testWidgets('clears all filters when reset button is tapped',
        (tester) async {
      HousekeepingTaskFilter? appliedFilter;
      await tester.pumpWidget(buildWidget(
        initialFilter: HousekeepingTaskFilter(
          status: HousekeepingTaskStatus.pending,
          taskType: HousekeepingTaskType.checkoutClean,
        ),
        onApply: (filter) => appliedFilter = filter,
      ));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap reset button (text is "Xóa bộ lọc")
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.status, isNull);
      expect(appliedFilter!.taskType, isNull);
      expect(appliedFilter!.scheduledDate, isNull);
    });
  });
}
