import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/models/housekeeping.dart';
import 'package:hoang_lam_app/widgets/housekeeping/maintenance_card.dart';

void main() {
  group('MaintenanceCard', () {
    late MaintenanceRequest mockRequest;

    setUp(() {
      mockRequest = MaintenanceRequest(
        id: 1,
        room: 201,
        roomNumber: '201',
        title: 'Vòi nước bị rỉ',
        description: 'Vòi trong phòng tắm bị rỉ nước',
        category: MaintenanceCategory.plumbing,
        priority: MaintenancePriority.medium,
        status: MaintenanceStatus.pending,
        reportedBy: 1,
        reportedByName: 'Lễ tân A',
        assignedTo: null,
        assignedToName: null,
        estimatedCost: null,
        resolutionNotes: null,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
        completedAt: null,
      );
    });

    Widget buildWidget({
      MaintenanceRequest? request,
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
          body: MaintenanceCard(
            request: request ?? mockRequest,
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

      expect(find.text('P.201'), findsOneWidget);
    });

    testWidgets('displays request title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Vòi nước bị rỉ'), findsOneWidget);
    });

    testWidgets('displays priority using displayName', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(MaintenancePriority.medium.displayName),
        findsOneWidget,
      );
    });

    testWidgets('displays pending status using displayName', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(MaintenanceStatus.pending.displayName),
        findsOneWidget,
      );
    });

    testWidgets('displays category icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // plumbing category has water_drop icon
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('displays description', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Vòi trong phòng tắm bị rỉ nước'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildWidget(
        onTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MaintenanceCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows assign button for pending requests without assignee',
        (tester) async {
      var assignCalled = false;
      await tester.pumpWidget(buildWidget(
        onAssign: () => assignCalled = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Phân công'), findsOneWidget);

      await tester.tap(find.text('Phân công'));
      await tester.pump();

      expect(assignCalled, isTrue);
    });

    testWidgets('shows complete button for in-progress requests',
        (tester) async {
      final inProgressRequest = MaintenanceRequest(
        id: 1,
        room: 201,
        roomNumber: '201',
        title: 'Đang sửa',
        description: 'Công việc đang được xử lý',
        category: MaintenanceCategory.electrical,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.inProgress,
        reportedBy: 1,
        reportedByName: 'Lễ tân A',
        assignedTo: 5,
        assignedToName: 'Thợ điện',
        estimatedCost: null,
        resolutionNotes: null,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
        completedAt: null,
      );

      var completeCalled = false;
      await tester.pumpWidget(buildWidget(
        request: inProgressRequest,
        onComplete: () => completeCalled = true,
      ));
      await tester.pumpAndSettle();

      // The complete button shows text "Hoàn thành"
      expect(find.text('Hoàn thành'), findsOneWidget);

      await tester.tap(find.text('Hoàn thành'));
      await tester.pump();

      expect(completeCalled, isTrue);
    });

    testWidgets('does not show complete button for completed requests',
        (tester) async {
      final completedRequest = MaintenanceRequest(
        id: 1,
        room: 201,
        roomNumber: '201',
        title: 'Đã sửa xong',
        description: 'Sửa hoàn tất',
        category: MaintenanceCategory.furniture,
        priority: MaintenancePriority.low,
        status: MaintenanceStatus.completed,
        reportedBy: 1,
        reportedByName: 'Lễ tân A',
        assignedTo: 5,
        assignedToName: 'Thợ mộc',
        estimatedCost: 200000,
        resolutionNotes: 'Đã thay ghế mới',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 17),
        completedAt: DateTime(2024, 1, 17),
      );

      await tester.pumpWidget(buildWidget(
        request: completedRequest,
        onComplete: () {},
      ));
      await tester.pumpAndSettle();

      // Status badge shows "Hoàn thành" but the TextButton should not exist
      expect(find.widgetWithText(TextButton, 'Hoàn thành'), findsNothing);
    });

    testWidgets('displays urgent priority using displayName', (tester) async {
      final urgentRequest = MaintenanceRequest(
        id: 1,
        room: 201,
        roomNumber: '201',
        title: 'Rò rỉ nước',
        description: 'Nước rỉ mạnh từ trần',
        category: MaintenanceCategory.plumbing,
        priority: MaintenancePriority.urgent,
        status: MaintenanceStatus.pending,
        reportedBy: 1,
        reportedByName: 'Lễ tân A',
        assignedTo: null,
        assignedToName: null,
        estimatedCost: null,
        resolutionNotes: null,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
        completedAt: null,
      );

      await tester.pumpWidget(buildWidget(request: urgentRequest));
      await tester.pumpAndSettle();

      expect(
        find.text(MaintenancePriority.urgent.displayName),
        findsOneWidget,
      );
    });

    testWidgets('displays all priority levels correctly', (tester) async {
      for (final priority in MaintenancePriority.values) {
        final request = MaintenanceRequest(
          id: 1,
          room: 201,
          roomNumber: '201',
          title: 'Test',
          description: 'Test description',
          category: MaintenanceCategory.electrical,
          priority: priority,
          status: MaintenanceStatus.pending,
          reportedBy: 1,
          reportedByName: 'Staff',
          assignedTo: null,
          assignedToName: null,
          estimatedCost: null,
          resolutionNotes: null,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
          completedAt: null,
        );

        await tester.pumpWidget(buildWidget(request: request));
      await tester.pumpAndSettle();

        expect(find.text(priority.displayName), findsOneWidget);
      }
    });

    testWidgets('displays all statuses correctly', (tester) async {
      for (final status in MaintenanceStatus.values) {
        final request = MaintenanceRequest(
          id: 1,
          room: 201,
          roomNumber: '201',
          title: 'Test',
          description: 'Test description',
          category: MaintenanceCategory.electrical,
          priority: MaintenancePriority.medium,
          status: status,
          reportedBy: 1,
          reportedByName: 'Staff',
          assignedTo: 2,
          assignedToName: 'Technician',
          estimatedCost: null,
          resolutionNotes: null,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
          completedAt: status == MaintenanceStatus.completed
              ? DateTime(2024, 1, 16)
              : null,
        );

        await tester.pumpWidget(buildWidget(request: request));
      await tester.pumpAndSettle();

        expect(find.text(status.displayName), findsOneWidget);
      }
    });

    testWidgets('displays assignee name when assigned', (tester) async {
      final assignedRequest = MaintenanceRequest(
        id: 1,
        room: 201,
        roomNumber: '201',
        title: 'Công việc đã phân công',
        description: 'Mô tả',
        category: MaintenanceCategory.acHeating,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.assigned,
        reportedBy: 1,
        reportedByName: 'Lễ tân B',
        assignedTo: 3,
        assignedToName: 'Kỹ thuật viên A',
        estimatedCost: null,
        resolutionNotes: null,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
        completedAt: null,
      );

      await tester.pumpWidget(buildWidget(request: assignedRequest));
      await tester.pumpAndSettle();

      expect(find.text('Kỹ thuật viên A'), findsOneWidget);
    });
  });
}
