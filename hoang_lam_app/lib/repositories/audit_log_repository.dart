import '../core/network/api_client.dart';
import '../models/audit_log.dart';

/// Repository for audit log operations
class AuditLogRepository {
  final ApiClient _apiClient;

  AuditLogRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get audit log entries with optional filters
  Future<List<AuditLogEntry>> getAuditLogs({
    String? entityType,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (entityType != null && entityType.isNotEmpty) {
      queryParams['entity_type'] = entityType;
    }
    if (limit != null) queryParams['limit'] = limit;

    final response = await _apiClient.get<List<dynamic>>(
      '/audit-logs/',
      queryParameters: queryParams,
    );

    if (response.data == null) return [];
    return response.data!
        .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
