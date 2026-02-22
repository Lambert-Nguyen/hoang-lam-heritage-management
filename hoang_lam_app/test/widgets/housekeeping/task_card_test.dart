import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/housekeeping.dart';
import 'package:hoang_lam_app/widgets/housekeeping/task_card.dart';

void main() {
  group('TaskCard', () {
    late HousekeepingTask mockTask;

    setUp(() {
      mockTask = HousekeepingTask(
        id: 1,
        room: 101,
        roomNumber: '101',
        taskType: HousekeepingTaskType.checkoutClean,
        status: HousekeepingTaskStatus.pending,
        scheduledDate: DateTime(2024, 1, 15),
        assignedTo: null,
        assignedToName: null,
        createdBy: 1,
        createdByName: 'Admin',
        notes: 'Test notes',
        createdAt: DateTime(2024, 1, 14),
        updatedAt: DateTime(2024, 1, 14),
        completedAt: null,
      );
    });

    Widget buildWidget({
      HousekeepingTask? task,
      VoidCallback? onTap,
      VoidCallback? onAssign,
      VoidCallback? onComplete,
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
          body: TaskCard(
            task: task ?? mockTask,
            onTap: onTap,
            onAssign: onAssign,
            onComplete: onComplete,
          ),
        ),
      );
    }

    testWidgets('displays room number correctly', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('P.101'), findsOneWidget);
    });

    testWidgets('displays task type using displayName', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Uses displayName from HousekeepingTaskType extension
      expect(
        find.text(HousekeepingTaskType.checkoutClean.displayName),
        findsOneWidget,
      );
    });

    testWidgets('displays pending status using displayName', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(HousekeepingTaskStatus.pending.displayName),
        findsOneWidget,
      );
    });

    testWidgets('displays scheduled date', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('15/01'), findsOneWidget);
    });

    testWidgets('displays "Chưa phân công" when no assignee', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Chưa phân công'), findsOneWidget);
    });

    testWidgets('displays assignee name when assigned', (tester) async {
      final assignedTask = HousekeepingTask(
        id: 1,
        room: 101,
        roomNumber: '101',
        taskType: HousekeepingTaskType.stayClean,
        status: HousekeepingTaskStatus.inProgress,
        scheduledDate: DateTime(2024, 1, 15),
        assignedTo: 2,
        assignedToName: 'Nguyễn Văn A',
        createdBy: 1,
        createdByName: 'Admin',
        notes: null,
        createdAt: DateTime(2024, 1, 14),
        updatedAt: DateTime(2024, 1, 14),
        completedAt: null,
      );

      await tester.pumpWidget(buildWidget(task: assignedTask));
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('displays notes when present', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test notes'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildWidget(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TaskCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows assign button for pending tasks without assignee', (
      tester,
    ) async {
      var assignCalled = false;
      await tester.pumpWidget(buildWidget(onAssign: () => assignCalled = true));
      await tester.pumpAndSettle();

      expect(find.text('Phân công'), findsOneWidget);

      await tester.tap(find.text('Phân công'));
      await tester.pump();

      expect(assignCalled, isTrue);
    });

    testWidgets('shows complete button when canComplete is true', (
      tester,
    ) async {
      final pendingTask = HousekeepingTask(
        id: 1,
        room: 101,
        roomNumber: '101',
        taskType: HousekeepingTaskType.stayClean,
        status: HousekeepingTaskStatus.pending,
        scheduledDate: DateTime(2024, 1, 15),
        assignedTo: 2,
        assignedToName: 'Staff',
        createdBy: 1,
        createdByName: 'Admin',
        notes: null,
        createdAt: DateTime(2024, 1, 14),
        updatedAt: DateTime(2024, 1, 14),
        completedAt: null,
      );

      var completeCalled = false;
      await tester.pumpWidget(
        buildWidget(task: pendingTask, onComplete: () => completeCalled = true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hoàn thành'), findsOneWidget);

      await tester.tap(find.text('Hoàn thành'));
      await tester.pump();

      expect(completeCalled, isTrue);
    });

    testWidgets('does not show complete button for completed tasks', (
      tester,
    ) async {
      final completedTask = HousekeepingTask(
        id: 1,
        room: 101,
        roomNumber: '101',
        taskType: HousekeepingTaskType.checkoutClean,
        status: HousekeepingTaskStatus.completed,
        scheduledDate: DateTime(2024, 1, 15),
        assignedTo: 2,
        assignedToName: 'Staff',
        createdBy: 1,
        createdByName: 'Admin',
        notes: null,
        createdAt: DateTime(2024, 1, 14),
        updatedAt: DateTime(2024, 1, 15),
        completedAt: DateTime(2024, 1, 15),
      );

      await tester.pumpWidget(
        buildWidget(task: completedTask, onComplete: () {}),
      );
      await tester.pumpAndSettle();

      // Status badge shows "Hoàn thành" but there's no TextButton with that text
      expect(find.widgetWithText(TextButton, 'Hoàn thành'), findsNothing);
    });

    testWidgets('displays completed time when task is completed', (
      tester,
    ) async {
      final completedTask = HousekeepingTask(
        id: 1,
        room: 101,
        roomNumber: '101',
        taskType: HousekeepingTaskType.checkoutClean,
        status: HousekeepingTaskStatus.completed,
        scheduledDate: DateTime(2024, 1, 15),
        assignedTo: 2,
        assignedToName: 'Staff',
        createdBy: 1,
        createdByName: 'Admin',
        notes: null,
        createdAt: DateTime(2024, 1, 14),
        updatedAt: DateTime(2024, 1, 15, 10, 30),
        completedAt: DateTime(2024, 1, 15, 10, 30),
      );

      await tester.pumpWidget(buildWidget(task: completedTask));
      await tester.pumpAndSettle();

      expect(find.text('10:30'), findsOneWidget);
    });

    testWidgets('displays different task types correctly', (tester) async {
      for (final taskType in HousekeepingTaskType.values) {
        final task = HousekeepingTask(
          id: 1,
          room: 101,
          roomNumber: '101',
          taskType: taskType,
          status: HousekeepingTaskStatus.pending,
          scheduledDate: DateTime(2024, 1, 15),
          assignedTo: null,
          assignedToName: null,
          createdBy: 1,
          createdByName: 'Admin',
          notes: null,
          createdAt: DateTime(2024, 1, 14),
          updatedAt: DateTime(2024, 1, 14),
          completedAt: null,
        );

        await tester.pumpWidget(buildWidget(task: task));
        await tester.pumpAndSettle();

        expect(find.text(taskType.displayName), findsOneWidget);
      }
    });

    testWidgets('displays different statuses correctly', (tester) async {
      for (final status in HousekeepingTaskStatus.values) {
        final task = HousekeepingTask(
          id: 1,
          room: 101,
          roomNumber: '101',
          taskType: HousekeepingTaskType.stayClean,
          status: status,
          scheduledDate: DateTime(2024, 1, 15),
          assignedTo: 2,
          assignedToName: 'Staff',
          createdBy: 1,
          createdByName: 'Admin',
          notes: null,
          createdAt: DateTime(2024, 1, 14),
          updatedAt: DateTime(2024, 1, 14),
          completedAt:
              status == HousekeepingTaskStatus.completed
                  ? DateTime.now()
                  : null,
        );

        await tester.pumpWidget(buildWidget(task: task));
        await tester.pumpAndSettle();

        expect(find.text(status.displayName), findsOneWidget);
      }
    });
  });
}
