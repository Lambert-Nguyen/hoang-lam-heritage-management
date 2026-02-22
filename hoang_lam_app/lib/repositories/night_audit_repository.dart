import '../core/network/api_client.dart';
import '../models/night_audit.dart';

/// Repository for Night Audit API operations
class NightAuditRepository {
  final ApiClient _apiClient;

  NightAuditRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get the base endpoint for night audits
  String get _endpoint => '/night-audits/';

  /// Get list of all night audits with optional filters
  Future<List<NightAuditListItem>> getAudits({
    NightAuditStatus? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, dynamic>{};

    if (status != null) {
      queryParams['status'] = status.name;
    }
    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get(
      _endpoint,
      queryParameters: queryParams,
    );

    final results = response.data['results'] as List? ?? response.data as List;
    return results
        .map(
          (json) => NightAuditListItem.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get audits for a specific month
  Future<List<NightAuditListItem>> getAuditsForMonth(
    int year,
    int month,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month
    return getAudits(dateFrom: startDate, dateTo: endDate);
  }

  /// Get a single night audit by ID
  Future<NightAudit> getAudit(int id) async {
    final response = await _apiClient.get('$_endpoint$id/');
    return NightAudit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create/generate a new night audit for a specific date
  Future<NightAudit> createAudit(NightAuditRequest request) async {
    final response = await _apiClient.post(_endpoint, data: request.toJson());
    return NightAudit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update a night audit
  Future<NightAudit> updateAudit(int id, NightAuditRequest request) async {
    final response = await _apiClient.patch(
      '$_endpoint$id/',
      data: request.toJson(),
    );
    return NightAudit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Close a night audit (mark as completed)
  Future<NightAudit> closeAudit(int id) async {
    final response = await _apiClient.post('$_endpoint$id/close/');
    return NightAudit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Recalculate audit statistics
  Future<NightAudit> recalculateAudit(int id) async {
    final response = await _apiClient.post('$_endpoint$id/recalculate/');
    return NightAudit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get today's night audit (creates one if it doesn't exist)
  Future<NightAudit> getTodayAudit() async {
    final response = await _apiClient.get('${_endpoint}today/');
    return NightAudit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get the latest night audit
  Future<NightAudit?> getLatestAudit() async {
    final response = await _apiClient.get('${_endpoint}latest/');
    if (response.data == null) return null;
    return NightAudit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a night audit (admin only)
  Future<void> deleteAudit(int id) async {
    await _apiClient.delete('$_endpoint$id/');
  }
}
