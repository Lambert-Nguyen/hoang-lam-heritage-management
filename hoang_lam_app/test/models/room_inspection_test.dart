import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/room_inspection.dart';

void main() {
  group('InspectionStatus', () {
    test('has correct display names', () {
      expect(InspectionStatus.pending.displayName, 'Chờ kiểm tra');
      expect(InspectionStatus.inProgress.displayName, 'Đang kiểm tra');
      expect(InspectionStatus.completed.displayName, 'Hoàn thành');
      expect(InspectionStatus.requiresAction.displayName, 'Cần xử lý');
    });

    test('has correct English display names', () {
      expect(InspectionStatus.pending.displayNameEn, 'Pending');
      expect(InspectionStatus.inProgress.displayNameEn, 'In Progress');
      expect(InspectionStatus.completed.displayNameEn, 'Completed');
      expect(InspectionStatus.requiresAction.displayNameEn, 'Requires Action');
    });
  });

  group('InspectionType', () {
    test('has correct display names', () {
      expect(InspectionType.checkout.displayName, 'Sau trả phòng');
      expect(InspectionType.checkin.displayName, 'Trước nhận phòng');
      expect(InspectionType.routine.displayName, 'Định kỳ');
      expect(InspectionType.maintenance.displayName, 'Bảo trì');
      expect(InspectionType.deepClean.displayName, 'Vệ sinh tổng');
    });
  });

  group('ChecklistItem', () {
    test('can be created with required fields', () {
      final item = ChecklistItem(
        category: 'bedroom',
        item: 'Check bed sheets',
      );

      expect(item.category, 'bedroom');
      expect(item.item, 'Check bed sheets');
      expect(item.critical, false);
      expect(item.passed, null);
      expect(item.notes, '');
    });

    test('can be created with all fields', () {
      final item = ChecklistItem(
        category: 'bathroom',
        item: 'Check towels',
        critical: true,
        passed: true,
        notes: 'All good',
      );

      expect(item.category, 'bathroom');
      expect(item.item, 'Check towels');
      expect(item.critical, true);
      expect(item.passed, true);
      expect(item.notes, 'All good');
    });

    test('can serialize to JSON', () {
      final item = ChecklistItem(
        category: 'bedroom',
        item: 'Check bed',
        critical: true,
        passed: true,
        notes: 'OK',
      );

      final json = item.toJson();

      expect(json['category'], 'bedroom');
      expect(json['item'], 'Check bed');
      expect(json['critical'], true);
      expect(json['passed'], true);
      expect(json['notes'], 'OK');
    });

    test('can deserialize from JSON', () {
      final json = {
        'category': 'bathroom',
        'item': 'Check soap',
        'critical': false,
        'passed': null,
        'notes': '',
      };

      final item = ChecklistItem.fromJson(json);

      expect(item.category, 'bathroom');
      expect(item.item, 'Check soap');
      expect(item.critical, false);
      expect(item.passed, null);
      expect(item.notes, '');
    });
  });

  group('RoomInspection', () {
    test('can be created from JSON', () {
      final json = {
        'id': 1,
        'room': 101,
        'room_number': '101',
        'room_type_name': 'Deluxe',
        'booking': 5,
        'inspection_type': 'checkout',
        'scheduled_date': '2024-01-15',
        'status': 'pending',
        'checklist_items': [],
        'total_items': 10,
        'passed_items': 0,
        'score': 0.0,
        'issues_found': 0,
        'critical_issues': 0,
        'images': [],
        'notes': '',
        'action_required': '',
      };

      final inspection = RoomInspection.fromJson(json);

      expect(inspection.id, 1);
      expect(inspection.room, 101);
      expect(inspection.roomNumber, '101');
      expect(inspection.roomTypeName, 'Deluxe');
      expect(inspection.booking, 5);
      expect(inspection.inspectionType, InspectionType.checkout);
      expect(inspection.status, InspectionStatus.pending);
    });
  });

  group('RoomInspectionCreate', () {
    test('can serialize to JSON correctly', () {
      final create = RoomInspectionCreate(
        room: 101,
        inspectionType: InspectionType.checkout,
        scheduledDate: '2024-01-15',
        templateId: 1,
      );

      final json = create.toJson();

      expect(json['room'], 101);
      expect(json['inspection_type'], 'checkout');
      expect(json['scheduled_date'], '2024-01-15');
      expect(json['template_id'], 1);
    });
  });

  group('CompleteInspection', () {
    test('can serialize to JSON correctly', () {
      final complete = CompleteInspection(
        checklistItems: [
          ChecklistItem(category: 'bedroom', item: 'Bed made', passed: true),
        ],
        images: ['image1.jpg'],
        notes: 'All good',
        actionRequired: '',
      );

      final json = complete.toJson();

      expect(json['checklist_items'], isA<List>());
      expect((json['checklist_items'] as List).length, 1);
      expect(json['images'], ['image1.jpg']);
      expect(json['notes'], 'All good');
      expect(json['action_required'], '');
    });
  });

  group('InspectionTemplate', () {
    test('can be created from JSON', () {
      final json = {
        'id': 1,
        'name': 'Standard Checkout',
        'inspection_type': 'checkout',
        'is_default': true,
        'is_active': true,
        'items': [
          {'category': 'bedroom', 'item': 'Bed made', 'critical': false},
        ],
        'item_count': 1,
      };

      final template = InspectionTemplate.fromJson(json);

      expect(template.id, 1);
      expect(template.name, 'Standard Checkout');
      expect(template.inspectionType, InspectionType.checkout);
      expect(template.isDefault, true);
      expect(template.isActive, true);
      expect(template.items.length, 1);
      expect(template.itemCount, 1);
    });
  });

  group('TemplateItem', () {
    test('can be created and serialized', () {
      final item = TemplateItem(
        category: 'bathroom',
        item: 'Check towels',
        critical: true,
      );

      expect(item.category, 'bathroom');
      expect(item.item, 'Check towels');
      expect(item.critical, true);

      final json = item.toJson();
      expect(json['category'], 'bathroom');
      expect(json['item'], 'Check towels');
      expect(json['critical'], true);
    });
  });

  group('InspectionCategories', () {
    test('returns correct display names', () {
      expect(InspectionCategories.getDisplayName('bedroom'), 'Phòng ngủ');
      expect(InspectionCategories.getDisplayName('bathroom'), 'Phòng tắm');
      expect(InspectionCategories.getDisplayName('amenities'), 'Tiện nghi');
      expect(InspectionCategories.getDisplayName('electronics'), 'Điện tử');
      expect(InspectionCategories.getDisplayName('safety'), 'An toàn');
      expect(InspectionCategories.getDisplayName('general'), 'Tổng quát');
    });

    test('returns all categories', () {
      expect(InspectionCategories.all.length, 6);
      expect(InspectionCategories.all, contains('bedroom'));
      expect(InspectionCategories.all, contains('bathroom'));
    });
  });

  group('InspectionStatistics', () {
    test('can be created from JSON', () {
      final json = {
        'total_inspections': 100,
        'completed_inspections': 80,
        'pending_inspections': 15,
        'requires_action': 5,
        'average_score': 92.5,
        'total_issues': 20,
        'critical_issues': 3,
        'inspections_by_type': {'checkout': 50, 'checkin': 30},
        'inspections_by_room': [],
      };

      final stats = InspectionStatistics.fromJson(json);

      expect(stats.totalInspections, 100);
      expect(stats.completedInspections, 80);
      expect(stats.pendingInspections, 15);
      expect(stats.requiresAction, 5);
      expect(stats.averageScore, 92.5);
      expect(stats.totalIssues, 20);
      expect(stats.criticalIssues, 3);
      expect(stats.inspectionsByType['checkout'], 50);
    });
  });
}
