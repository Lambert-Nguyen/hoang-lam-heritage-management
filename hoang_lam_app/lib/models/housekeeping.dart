import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'housekeeping.freezed.dart';
part 'housekeeping.g.dart';

// ============================================================
// Housekeeping Task Enums
// ============================================================

/// Task type matching backend HousekeepingTask.TaskType choices
enum HousekeepingTaskType {
  @JsonValue('checkout_clean')
  checkoutClean,
  @JsonValue('stay_clean')
  stayClean,
  @JsonValue('deep_clean')
  deepClean,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('inspection')
  inspection,
}

extension HousekeepingTaskTypeExtension on HousekeepingTaskType {
  String get displayName {
    switch (this) {
      case HousekeepingTaskType.checkoutClean:
        return 'Dọn trả phòng';
      case HousekeepingTaskType.stayClean:
        return 'Dọn phòng đang ở';
      case HousekeepingTaskType.deepClean:
        return 'Dọn sâu';
      case HousekeepingTaskType.maintenance:
        return 'Bảo trì';
      case HousekeepingTaskType.inspection:
        return 'Kiểm tra';
    }
  }

  String get displayNameEn {
    switch (this) {
      case HousekeepingTaskType.checkoutClean:
        return 'Checkout Clean';
      case HousekeepingTaskType.stayClean:
        return 'Stay Clean';
      case HousekeepingTaskType.deepClean:
        return 'Deep Clean';
      case HousekeepingTaskType.maintenance:
        return 'Maintenance';
      case HousekeepingTaskType.inspection:
        return 'Inspection';
    }
  }

  Color get color {
    switch (this) {
      case HousekeepingTaskType.checkoutClean:
        return const Color(0xFF2196F3); // Blue
      case HousekeepingTaskType.stayClean:
        return const Color(0xFF4CAF50); // Green
      case HousekeepingTaskType.deepClean:
        return const Color(0xFF9C27B0); // Purple
      case HousekeepingTaskType.maintenance:
        return const Color(0xFFFF9800); // Orange
      case HousekeepingTaskType.inspection:
        return const Color(0xFF00BCD4); // Cyan
    }
  }

  IconData get icon {
    switch (this) {
      case HousekeepingTaskType.checkoutClean:
        return Icons.cleaning_services;
      case HousekeepingTaskType.stayClean:
        return Icons.bed;
      case HousekeepingTaskType.deepClean:
        return Icons.auto_fix_high;
      case HousekeepingTaskType.maintenance:
        return Icons.build;
      case HousekeepingTaskType.inspection:
        return Icons.fact_check;
    }
  }

  String get apiValue {
    switch (this) {
      case HousekeepingTaskType.checkoutClean:
        return 'checkout_clean';
      case HousekeepingTaskType.stayClean:
        return 'stay_clean';
      case HousekeepingTaskType.deepClean:
        return 'deep_clean';
      case HousekeepingTaskType.maintenance:
        return 'maintenance';
      case HousekeepingTaskType.inspection:
        return 'inspection';
    }
  }
}

/// Task status matching backend HousekeepingTask.Status choices
enum HousekeepingTaskStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('verified')
  verified,
}

extension HousekeepingTaskStatusExtension on HousekeepingTaskStatus {
  String get displayName {
    switch (this) {
      case HousekeepingTaskStatus.pending:
        return 'Chờ xử lý';
      case HousekeepingTaskStatus.inProgress:
        return 'Đang làm';
      case HousekeepingTaskStatus.completed:
        return 'Hoàn thành';
      case HousekeepingTaskStatus.verified:
        return 'Đã xác nhận';
    }
  }

  String get displayNameEn {
    switch (this) {
      case HousekeepingTaskStatus.pending:
        return 'Pending';
      case HousekeepingTaskStatus.inProgress:
        return 'In Progress';
      case HousekeepingTaskStatus.completed:
        return 'Completed';
      case HousekeepingTaskStatus.verified:
        return 'Verified';
    }
  }

  Color get color {
    switch (this) {
      case HousekeepingTaskStatus.pending:
        return const Color(0xFFFFC107); // Amber
      case HousekeepingTaskStatus.inProgress:
        return const Color(0xFF2196F3); // Blue
      case HousekeepingTaskStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case HousekeepingTaskStatus.verified:
        return const Color(0xFF8BC34A); // Light Green
    }
  }

  IconData get icon {
    switch (this) {
      case HousekeepingTaskStatus.pending:
        return Icons.schedule;
      case HousekeepingTaskStatus.inProgress:
        return Icons.play_circle;
      case HousekeepingTaskStatus.completed:
        return Icons.check_circle;
      case HousekeepingTaskStatus.verified:
        return Icons.verified;
    }
  }

  String get apiValue {
    switch (this) {
      case HousekeepingTaskStatus.pending:
        return 'pending';
      case HousekeepingTaskStatus.inProgress:
        return 'in_progress';
      case HousekeepingTaskStatus.completed:
        return 'completed';
      case HousekeepingTaskStatus.verified:
        return 'verified';
    }
  }

  bool get canAssign => this == HousekeepingTaskStatus.pending;
  bool get canComplete =>
      this == HousekeepingTaskStatus.pending ||
      this == HousekeepingTaskStatus.inProgress;
  bool get canVerify => this == HousekeepingTaskStatus.completed;
}

// ============================================================
// Maintenance Request Enums
// ============================================================

/// Priority matching backend MaintenanceRequest.Priority choices
enum MaintenancePriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

extension MaintenancePriorityExtension on MaintenancePriority {
  String get displayName {
    switch (this) {
      case MaintenancePriority.low:
        return 'Thấp';
      case MaintenancePriority.medium:
        return 'Trung bình';
      case MaintenancePriority.high:
        return 'Cao';
      case MaintenancePriority.urgent:
        return 'Khẩn cấp';
    }
  }

  String get displayNameEn {
    switch (this) {
      case MaintenancePriority.low:
        return 'Low';
      case MaintenancePriority.medium:
        return 'Medium';
      case MaintenancePriority.high:
        return 'High';
      case MaintenancePriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case MaintenancePriority.low:
        return const Color(0xFF4CAF50); // Green
      case MaintenancePriority.medium:
        return const Color(0xFFFFC107); // Amber
      case MaintenancePriority.high:
        return const Color(0xFFFF9800); // Orange
      case MaintenancePriority.urgent:
        return const Color(0xFFF44336); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case MaintenancePriority.low:
        return Icons.arrow_downward;
      case MaintenancePriority.medium:
        return Icons.remove;
      case MaintenancePriority.high:
        return Icons.arrow_upward;
      case MaintenancePriority.urgent:
        return Icons.priority_high;
    }
  }

  String get apiValue {
    switch (this) {
      case MaintenancePriority.low:
        return 'low';
      case MaintenancePriority.medium:
        return 'medium';
      case MaintenancePriority.high:
        return 'high';
      case MaintenancePriority.urgent:
        return 'urgent';
    }
  }
}

/// Status matching backend MaintenanceRequest.Status choices
enum MaintenanceStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('assigned')
  assigned,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('on_hold')
  onHold,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

extension MaintenanceStatusExtension on MaintenanceStatus {
  String get displayName {
    switch (this) {
      case MaintenanceStatus.pending:
        return 'Chờ xử lý';
      case MaintenanceStatus.assigned:
        return 'Đã phân công';
      case MaintenanceStatus.inProgress:
        return 'Đang thực hiện';
      case MaintenanceStatus.onHold:
        return 'Tạm dừng';
      case MaintenanceStatus.completed:
        return 'Hoàn thành';
      case MaintenanceStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String get displayNameEn {
    switch (this) {
      case MaintenanceStatus.pending:
        return 'Pending';
      case MaintenanceStatus.assigned:
        return 'Assigned';
      case MaintenanceStatus.inProgress:
        return 'In Progress';
      case MaintenanceStatus.onHold:
        return 'On Hold';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case MaintenanceStatus.pending:
        return const Color(0xFFFFC107); // Amber
      case MaintenanceStatus.assigned:
        return const Color(0xFF2196F3); // Blue
      case MaintenanceStatus.inProgress:
        return const Color(0xFF03A9F4); // Light Blue
      case MaintenanceStatus.onHold:
        return const Color(0xFF9E9E9E); // Grey
      case MaintenanceStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case MaintenanceStatus.cancelled:
        return const Color(0xFFF44336); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case MaintenanceStatus.pending:
        return Icons.schedule;
      case MaintenanceStatus.assigned:
        return Icons.person_add;
      case MaintenanceStatus.inProgress:
        return Icons.play_circle;
      case MaintenanceStatus.onHold:
        return Icons.pause_circle;
      case MaintenanceStatus.completed:
        return Icons.check_circle;
      case MaintenanceStatus.cancelled:
        return Icons.cancel;
    }
  }

  String get apiValue {
    switch (this) {
      case MaintenanceStatus.pending:
        return 'pending';
      case MaintenanceStatus.assigned:
        return 'assigned';
      case MaintenanceStatus.inProgress:
        return 'in_progress';
      case MaintenanceStatus.onHold:
        return 'on_hold';
      case MaintenanceStatus.completed:
        return 'completed';
      case MaintenanceStatus.cancelled:
        return 'cancelled';
    }
  }

  bool get canAssign =>
      this == MaintenanceStatus.pending || this == MaintenanceStatus.assigned;
  bool get canComplete =>
      this == MaintenanceStatus.assigned ||
      this == MaintenanceStatus.inProgress;
  bool get canHold =>
      this != MaintenanceStatus.completed &&
      this != MaintenanceStatus.cancelled;
  bool get canResume => this == MaintenanceStatus.onHold;
  bool get canCancel =>
      this != MaintenanceStatus.completed &&
      this != MaintenanceStatus.cancelled;
  bool get isActive =>
      this != MaintenanceStatus.completed &&
      this != MaintenanceStatus.cancelled;
}

/// Category matching backend MaintenanceRequest.Category choices
enum MaintenanceCategory {
  @JsonValue('electrical')
  electrical,
  @JsonValue('plumbing')
  plumbing,
  @JsonValue('ac_heating')
  acHeating,
  @JsonValue('furniture')
  furniture,
  @JsonValue('appliance')
  appliance,
  @JsonValue('structural')
  structural,
  @JsonValue('safety')
  safety,
  @JsonValue('other')
  other,
}

extension MaintenanceCategoryExtension on MaintenanceCategory {
  String get displayName {
    switch (this) {
      case MaintenanceCategory.electrical:
        return 'Điện';
      case MaintenanceCategory.plumbing:
        return 'Nước';
      case MaintenanceCategory.acHeating:
        return 'Điều hòa/Sưởi';
      case MaintenanceCategory.furniture:
        return 'Nội thất';
      case MaintenanceCategory.appliance:
        return 'Thiết bị';
      case MaintenanceCategory.structural:
        return 'Kết cấu';
      case MaintenanceCategory.safety:
        return 'An toàn';
      case MaintenanceCategory.other:
        return 'Khác';
    }
  }

  String get displayNameEn {
    switch (this) {
      case MaintenanceCategory.electrical:
        return 'Electrical';
      case MaintenanceCategory.plumbing:
        return 'Plumbing';
      case MaintenanceCategory.acHeating:
        return 'AC/Heating';
      case MaintenanceCategory.furniture:
        return 'Furniture';
      case MaintenanceCategory.appliance:
        return 'Appliance';
      case MaintenanceCategory.structural:
        return 'Structural';
      case MaintenanceCategory.safety:
        return 'Safety';
      case MaintenanceCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case MaintenanceCategory.electrical:
        return const Color(0xFFFFC107); // Amber
      case MaintenanceCategory.plumbing:
        return const Color(0xFF2196F3); // Blue
      case MaintenanceCategory.acHeating:
        return const Color(0xFF00BCD4); // Cyan
      case MaintenanceCategory.furniture:
        return const Color(0xFF795548); // Brown
      case MaintenanceCategory.appliance:
        return const Color(0xFF9C27B0); // Purple
      case MaintenanceCategory.structural:
        return const Color(0xFF607D8B); // Blue Grey
      case MaintenanceCategory.safety:
        return const Color(0xFFF44336); // Red
      case MaintenanceCategory.other:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData get icon {
    switch (this) {
      case MaintenanceCategory.electrical:
        return Icons.bolt;
      case MaintenanceCategory.plumbing:
        return Icons.water_drop;
      case MaintenanceCategory.acHeating:
        return Icons.ac_unit;
      case MaintenanceCategory.furniture:
        return Icons.chair;
      case MaintenanceCategory.appliance:
        return Icons.tv;
      case MaintenanceCategory.structural:
        return Icons.foundation;
      case MaintenanceCategory.safety:
        return Icons.health_and_safety;
      case MaintenanceCategory.other:
        return Icons.more_horiz;
    }
  }

  String get apiValue {
    switch (this) {
      case MaintenanceCategory.electrical:
        return 'electrical';
      case MaintenanceCategory.plumbing:
        return 'plumbing';
      case MaintenanceCategory.acHeating:
        return 'ac_heating';
      case MaintenanceCategory.furniture:
        return 'furniture';
      case MaintenanceCategory.appliance:
        return 'appliance';
      case MaintenanceCategory.structural:
        return 'structural';
      case MaintenanceCategory.safety:
        return 'safety';
      case MaintenanceCategory.other:
        return 'other';
    }
  }
}

// ============================================================
// Models
// ============================================================

/// HousekeepingTask model matching backend HousekeepingTaskSerializer
@freezed
sealed class HousekeepingTask with _$HousekeepingTask {
  const factory HousekeepingTask({
    required int id,
    int? room,
    @JsonKey(name: 'room_number') String? roomNumber,
    @JsonKey(name: 'task_type') required HousekeepingTaskType taskType,
    @JsonKey(name: 'task_type_display') String? taskTypeDisplay,
    @Default(HousekeepingTaskStatus.pending) HousekeepingTaskStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @JsonKey(name: 'scheduled_date') required DateTime scheduledDate,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'assigned_to') int? assignedTo,
    @JsonKey(name: 'assigned_to_name') String? assignedToName,
    String? notes,
    int? booking,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_name') String? createdByName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _HousekeepingTask;

  const HousekeepingTask._();

  factory HousekeepingTask.fromJson(Map<String, dynamic> json) =>
      _$HousekeepingTaskFromJson(json);

  /// Check if task is overdue
  bool get isOverdue {
    if (status == HousekeepingTaskStatus.completed ||
        status == HousekeepingTaskStatus.verified) {
      return false;
    }
    return scheduledDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Check if task is scheduled for today
  bool get isToday {
    final today = DateTime.now();
    return scheduledDate.year == today.year &&
        scheduledDate.month == today.month &&
        scheduledDate.day == today.day;
  }
}

/// HousekeepingTask create request
@freezed
sealed class HousekeepingTaskCreate with _$HousekeepingTaskCreate {
  const factory HousekeepingTaskCreate({
    required int room,
    @JsonKey(name: 'task_type') required String taskType,
    @JsonKey(name: 'scheduled_date') required String scheduledDate,
    @JsonKey(name: 'assigned_to') int? assignedTo,
    String? notes,
    int? booking,
  }) = _HousekeepingTaskCreate;

  factory HousekeepingTaskCreate.fromJson(Map<String, dynamic> json) =>
      _$HousekeepingTaskCreateFromJson(json);
}

/// HousekeepingTask update request
@freezed
sealed class HousekeepingTaskUpdate with _$HousekeepingTaskUpdate {
  const factory HousekeepingTaskUpdate({
    @JsonKey(includeIfNull: false) String? status,
    @JsonKey(name: 'assigned_to', includeIfNull: false) int? assignedTo,
    @JsonKey(includeIfNull: false) String? notes,
    @JsonKey(name: 'completed_at', includeIfNull: false) String? completedAt,
  }) = _HousekeepingTaskUpdate;

  factory HousekeepingTaskUpdate.fromJson(Map<String, dynamic> json) =>
      _$HousekeepingTaskUpdateFromJson(json);
}

/// List response for HousekeepingTask
@freezed
sealed class HousekeepingTaskListResponse with _$HousekeepingTaskListResponse {
  const factory HousekeepingTaskListResponse({
    required int count,
    String? next,
    String? previous,
    required List<HousekeepingTask> results,
  }) = _HousekeepingTaskListResponse;

  factory HousekeepingTaskListResponse.fromJson(Map<String, dynamic> json) =>
      _$HousekeepingTaskListResponseFromJson(json);
}

/// MaintenanceRequest model matching backend MaintenanceRequestSerializer
@freezed
sealed class MaintenanceRequest with _$MaintenanceRequest {
  const factory MaintenanceRequest({
    required int id,
    int? room,
    @JsonKey(name: 'room_number') String? roomNumber,
    @JsonKey(name: 'location_description') String? locationDescription,
    required String title,
    required String description,
    @Default(MaintenanceCategory.other) MaintenanceCategory category,
    @JsonKey(name: 'category_display') String? categoryDisplay,
    @Default(MaintenancePriority.medium) MaintenancePriority priority,
    @JsonKey(name: 'priority_display') String? priorityDisplay,
    @Default(MaintenanceStatus.pending) MaintenanceStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @JsonKey(name: 'assigned_to') int? assignedTo,
    @JsonKey(name: 'assigned_to_name') String? assignedToName,
    @JsonKey(name: 'assigned_at') DateTime? assignedAt,
    @JsonKey(name: 'estimated_cost') int? estimatedCost,
    @JsonKey(name: 'actual_cost') int? actualCost,
    @JsonKey(name: 'resolution_notes') String? resolutionNotes,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'completed_by') int? completedBy,
    @JsonKey(name: 'completed_by_name') String? completedByName,
    @JsonKey(name: 'reported_by') int? reportedBy,
    @JsonKey(name: 'reported_by_name') String? reportedByName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MaintenanceRequest;

  const MaintenanceRequest._();

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRequestFromJson(json);

  /// Get the location (room number or description)
  String get location => roomNumber ?? locationDescription ?? 'Unknown';

  /// Check if request is urgent (high or urgent priority and not completed)
  bool get isUrgent =>
      (priority == MaintenancePriority.high ||
          priority == MaintenancePriority.urgent) &&
      status.isActive;
}

/// MaintenanceRequest create request
@freezed
sealed class MaintenanceRequestCreate with _$MaintenanceRequestCreate {
  const factory MaintenanceRequestCreate({
    int? room,
    @JsonKey(name: 'location_description') String? locationDescription,
    required String title,
    required String description,
    @Default('other') String category,
    @Default('medium') String priority,
  }) = _MaintenanceRequestCreate;

  factory MaintenanceRequestCreate.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRequestCreateFromJson(json);
}

/// MaintenanceRequest update request
@freezed
sealed class MaintenanceRequestUpdate with _$MaintenanceRequestUpdate {
  const factory MaintenanceRequestUpdate({
    @JsonKey(includeIfNull: false) String? title,
    @JsonKey(includeIfNull: false) String? description,
    @JsonKey(includeIfNull: false) String? category,
    @JsonKey(includeIfNull: false) String? priority,
    @JsonKey(includeIfNull: false) String? status,
    @JsonKey(name: 'assigned_to', includeIfNull: false) int? assignedTo,
    @JsonKey(name: 'estimated_cost', includeIfNull: false) int? estimatedCost,
    @JsonKey(name: 'actual_cost', includeIfNull: false) int? actualCost,
    @JsonKey(name: 'resolution_notes', includeIfNull: false) String? resolutionNotes,
  }) = _MaintenanceRequestUpdate;

  factory MaintenanceRequestUpdate.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRequestUpdateFromJson(json);
}

/// List response for MaintenanceRequest
@freezed
sealed class MaintenanceRequestListResponse with _$MaintenanceRequestListResponse {
  const factory MaintenanceRequestListResponse({
    required int count,
    String? next,
    String? previous,
    required List<MaintenanceRequest> results,
  }) = _MaintenanceRequestListResponse;

  factory MaintenanceRequestListResponse.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRequestListResponseFromJson(json);
}
