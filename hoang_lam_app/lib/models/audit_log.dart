/// Audit log entry model
class AuditLogEntry {
  final int id;
  final String action;
  final String entityType;
  final int? entityId;
  final int? userId;
  final String userName;
  final String details;
  final String createdAt;

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.userId,
    required this.userName,
    required this.details,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as int,
      action: json['action'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as int?,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String? ?? '',
      details: json['details'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
