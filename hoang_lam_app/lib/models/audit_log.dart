import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

/// Audit log entry model
@freezed
sealed class AuditLogEntry with _$AuditLogEntry {
  const factory AuditLogEntry({
    required int id,
    @Default('') String action,
    @JsonKey(name: 'entity_type') @Default('') String entityType,
    @JsonKey(name: 'entity_id') int? entityId,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'user_name') @Default('') String userName,
    @Default('') String details,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _AuditLogEntry;

  const AuditLogEntry._();

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditLogEntryFromJson(json);
}

/// Paginated audit log list response
@freezed
sealed class AuditLogListResponse with _$AuditLogListResponse {
  const factory AuditLogListResponse({
    @Default(0) int count,
    String? next,
    String? previous,
    @Default([]) List<AuditLogEntry> results,
  }) = _AuditLogListResponse;

  factory AuditLogListResponse.fromJson(Map<String, dynamic> json) =>
      _$AuditLogListResponseFromJson(json);
}
