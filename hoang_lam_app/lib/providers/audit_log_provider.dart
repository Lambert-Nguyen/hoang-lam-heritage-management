import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audit_log.dart';
import '../repositories/audit_log_repository.dart';

/// Provider for the audit log repository
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository();
});

/// Provider for fetching audit logs with optional entity type filter
final auditLogsProvider =
    FutureProvider.family<List<AuditLogEntry>, String?>((ref, entityType) async {
  final repository = ref.read(auditLogRepositoryProvider);
  return repository.getAuditLogs(entityType: entityType, limit: 100);
});
