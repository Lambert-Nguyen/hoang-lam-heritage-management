import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

part 'room_inspection.freezed.dart';
part 'room_inspection.g.dart';

// ============================================================
// Room Inspection Status Enum
// ============================================================

enum InspectionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('requires_action')
  requiresAction,
}

extension InspectionStatusX on InspectionStatus {
  String get displayName {
    switch (this) {
      case InspectionStatus.pending:
        return 'Chờ kiểm tra';
      case InspectionStatus.inProgress:
        return 'Đang kiểm tra';
      case InspectionStatus.completed:
        return 'Hoàn thành';
      case InspectionStatus.requiresAction:
        return 'Cần xử lý';
    }
  }

  String get displayNameEn {
    switch (this) {
      case InspectionStatus.pending:
        return 'Pending';
      case InspectionStatus.inProgress:
        return 'In Progress';
      case InspectionStatus.completed:
        return 'Completed';
      case InspectionStatus.requiresAction:
        return 'Requires Action';
    }
  }

  Color get color {
    switch (this) {
      case InspectionStatus.pending:
        return Colors.grey;
      case InspectionStatus.inProgress:
        return Colors.blue;
      case InspectionStatus.completed:
        return Colors.green;
      case InspectionStatus.requiresAction:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case InspectionStatus.pending:
        return Icons.schedule;
      case InspectionStatus.inProgress:
        return Icons.play_circle_outline;
      case InspectionStatus.completed:
        return Icons.check_circle;
      case InspectionStatus.requiresAction:
        return Icons.warning_amber;
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case InspectionStatus.pending:
        return l10n.inspectionStatusPending;
      case InspectionStatus.inProgress:
        return l10n.inspectionStatusInProgress;
      case InspectionStatus.completed:
        return l10n.inspectionStatusCompleted;
      case InspectionStatus.requiresAction:
        return l10n.inspectionStatusActionRequired;
    }
  }
}

// ============================================================
// Inspection Type Enum
// ============================================================

enum InspectionType {
  @JsonValue('checkout')
  checkout,
  @JsonValue('checkin')
  checkin,
  @JsonValue('routine')
  routine,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('deep_clean')
  deepClean,
}

extension InspectionTypeX on InspectionType {
  String get displayName {
    switch (this) {
      case InspectionType.checkout:
        return 'Sau trả phòng';
      case InspectionType.checkin:
        return 'Trước nhận phòng';
      case InspectionType.routine:
        return 'Định kỳ';
      case InspectionType.maintenance:
        return 'Bảo trì';
      case InspectionType.deepClean:
        return 'Vệ sinh tổng';
    }
  }

  String get displayNameEn {
    switch (this) {
      case InspectionType.checkout:
        return 'Post-Checkout';
      case InspectionType.checkin:
        return 'Pre-Checkin';
      case InspectionType.routine:
        return 'Routine';
      case InspectionType.maintenance:
        return 'Maintenance';
      case InspectionType.deepClean:
        return 'Deep Clean';
    }
  }

  IconData get icon {
    switch (this) {
      case InspectionType.checkout:
        return Icons.logout;
      case InspectionType.checkin:
        return Icons.login;
      case InspectionType.routine:
        return Icons.event_repeat;
      case InspectionType.maintenance:
        return Icons.build;
      case InspectionType.deepClean:
        return Icons.cleaning_services;
    }
  }

  Color get color {
    switch (this) {
      case InspectionType.checkout:
        return Colors.orange;
      case InspectionType.checkin:
        return Colors.blue;
      case InspectionType.routine:
        return Colors.purple;
      case InspectionType.maintenance:
        return Colors.brown;
      case InspectionType.deepClean:
        return Colors.teal;
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case InspectionType.checkout:
        return l10n.inspectionTypeCheckout;
      case InspectionType.checkin:
        return l10n.inspectionTypeCheckin;
      case InspectionType.routine:
        return l10n.inspectionTypeRoutine;
      case InspectionType.maintenance:
        return l10n.inspectionTypeMaintenance;
      case InspectionType.deepClean:
        return l10n.inspectionTypeDeepClean;
    }
  }
}

// ============================================================
// Checklist Item Model
// ============================================================

@freezed
sealed class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({
    required String category,
    required String item,
    @Default(false) bool critical,
    bool? passed,
    @Default('') String notes,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);
}

// ============================================================
// Room Inspection Model
// ============================================================

@freezed
sealed class RoomInspection with _$RoomInspection {
  const factory RoomInspection({
    required int id,
    required int room,
    @JsonKey(name: 'room_number') required String roomNumber,
    @JsonKey(name: 'room_type_name') String? roomTypeName,
    int? booking,
    @JsonKey(name: 'booking_info') Map<String, dynamic>? bookingInfo,
    @JsonKey(name: 'inspection_type') required InspectionType inspectionType,
    @JsonKey(name: 'inspection_type_display') String? inspectionTypeDisplay,
    @JsonKey(name: 'scheduled_date') required String scheduledDate,
    @JsonKey(name: 'completed_at') String? completedAt,
    int? inspector,
    @JsonKey(name: 'inspector_name') String? inspectorName,
    required InspectionStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @JsonKey(name: 'checklist_items')
    @Default([])
    List<ChecklistItem> checklistItems,
    @JsonKey(name: 'total_items') @Default(0) int totalItems,
    @JsonKey(name: 'passed_items') @Default(0) int passedItems,
    @Default(0.0) double score,
    @JsonKey(name: 'issues_found') @Default(0) int issuesFound,
    @JsonKey(name: 'critical_issues') @Default(0) int criticalIssues,
    @Default([]) List<String> images,
    @Default('') String notes,
    @JsonKey(name: 'action_required') @Default('') String actionRequired,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _RoomInspection;

  factory RoomInspection.fromJson(Map<String, dynamic> json) =>
      _$RoomInspectionFromJson(json);
}

// ============================================================
// Room Inspection Create Model
// ============================================================

@freezed
sealed class RoomInspectionCreate with _$RoomInspectionCreate {
  const factory RoomInspectionCreate({
    required int room,
    int? booking,
    @JsonKey(name: 'inspection_type') required InspectionType inspectionType,
    @JsonKey(name: 'scheduled_date') required String scheduledDate,
    int? inspector,
    @JsonKey(name: 'checklist_items')
    @Default([])
    List<ChecklistItem> checklistItems,
    @Default('') String notes,
    @JsonKey(name: 'template_id') int? templateId,
  }) = _RoomInspectionCreate;

  factory RoomInspectionCreate.fromJson(Map<String, dynamic> json) =>
      _$RoomInspectionCreateFromJson(json);
}

// ============================================================
// Room Inspection Update Model
// ============================================================

@freezed
sealed class RoomInspectionUpdate with _$RoomInspectionUpdate {
  const factory RoomInspectionUpdate({
    @JsonKey(name: 'scheduled_date') String? scheduledDate,
    int? inspector,
    InspectionStatus? status,
    @JsonKey(name: 'checklist_items') List<ChecklistItem>? checklistItems,
    List<String>? images,
    String? notes,
    @JsonKey(name: 'action_required') String? actionRequired,
  }) = _RoomInspectionUpdate;

  factory RoomInspectionUpdate.fromJson(Map<String, dynamic> json) =>
      _$RoomInspectionUpdateFromJson(json);
}

// ============================================================
// Complete Inspection Model
// ============================================================

@freezed
sealed class CompleteInspection with _$CompleteInspection {
  const factory CompleteInspection({
    @JsonKey(name: 'checklist_items')
    required List<ChecklistItem> checklistItems,
    @Default([]) List<String> images,
    @Default('') String notes,
    @JsonKey(name: 'action_required') @Default('') String actionRequired,
  }) = _CompleteInspection;

  factory CompleteInspection.fromJson(Map<String, dynamic> json) =>
      _$CompleteInspectionFromJson(json);
}

// ============================================================
// Inspection Template Model
// ============================================================

@freezed
sealed class InspectionTemplate with _$InspectionTemplate {
  const factory InspectionTemplate({
    required int id,
    required String name,
    @JsonKey(name: 'inspection_type') required InspectionType inspectionType,
    @JsonKey(name: 'inspection_type_display') String? inspectionTypeDisplay,
    @JsonKey(name: 'room_type') int? roomType,
    @JsonKey(name: 'room_type_name') String? roomTypeName,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @Default([]) List<TemplateItem> items,
    @JsonKey(name: 'item_count') @Default(0) int itemCount,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_name') String? createdByName,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _InspectionTemplate;

  factory InspectionTemplate.fromJson(Map<String, dynamic> json) =>
      _$InspectionTemplateFromJson(json);
}

// ============================================================
// Template Item Model
// ============================================================

@freezed
sealed class TemplateItem with _$TemplateItem {
  const factory TemplateItem({
    required String category,
    required String item,
    @Default(false) bool critical,
  }) = _TemplateItem;

  factory TemplateItem.fromJson(Map<String, dynamic> json) =>
      _$TemplateItemFromJson(json);
}

// ============================================================
// Inspection Template Create Model
// ============================================================

@freezed
sealed class InspectionTemplateCreate with _$InspectionTemplateCreate {
  const factory InspectionTemplateCreate({
    required String name,
    @JsonKey(name: 'inspection_type') required InspectionType inspectionType,
    @JsonKey(name: 'room_type') int? roomType,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @Default([]) List<TemplateItem> items,
  }) = _InspectionTemplateCreate;

  factory InspectionTemplateCreate.fromJson(Map<String, dynamic> json) =>
      _$InspectionTemplateCreateFromJson(json);
}

// ============================================================
// Inspection Statistics Model
// ============================================================

@freezed
sealed class InspectionStatistics with _$InspectionStatistics {
  const factory InspectionStatistics({
    @JsonKey(name: 'total_inspections') @Default(0) int totalInspections,
    @JsonKey(name: 'completed_inspections')
    @Default(0)
    int completedInspections,
    @JsonKey(name: 'pending_inspections') @Default(0) int pendingInspections,
    @JsonKey(name: 'requires_action') @Default(0) int requiresAction,
    @JsonKey(name: 'average_score') @Default(0.0) double averageScore,
    @JsonKey(name: 'total_issues') @Default(0) int totalIssues,
    @JsonKey(name: 'critical_issues') @Default(0) int criticalIssues,
    @JsonKey(name: 'inspections_by_type')
    @Default({})
    Map<String, int> inspectionsByType,
    @JsonKey(name: 'inspections_by_room')
    @Default([])
    List<Map<String, dynamic>> inspectionsByRoom,
  }) = _InspectionStatistics;

  factory InspectionStatistics.fromJson(Map<String, dynamic> json) =>
      _$InspectionStatisticsFromJson(json);
}

// ============================================================
// Default Checklist Categories
// ============================================================

class InspectionCategories {
  static const String bedroom = 'bedroom';
  static const String bathroom = 'bathroom';
  static const String amenities = 'amenities';
  static const String electronics = 'electronics';
  static const String safety = 'safety';
  static const String general = 'general';

  static String getDisplayName(String category) {
    switch (category) {
      case bedroom:
        return 'Phòng ngủ';
      case bathroom:
        return 'Phòng tắm';
      case amenities:
        return 'Tiện nghi';
      case electronics:
        return 'Điện tử';
      case safety:
        return 'An toàn';
      case general:
        return 'Tổng quát';
      default:
        return category;
    }
  }

  static IconData getIcon(String category) {
    switch (category) {
      case bedroom:
        return Icons.bed;
      case bathroom:
        return Icons.bathroom;
      case amenities:
        return Icons.room_service;
      case electronics:
        return Icons.electrical_services;
      case safety:
        return Icons.security;
      case general:
        return Icons.list_alt;
      default:
        return Icons.category;
    }
  }

  static List<String> get all => [
    bedroom,
    bathroom,
    amenities,
    electronics,
    safety,
    general,
  ];
}
