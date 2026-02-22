import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/room_inspection.dart';

/// Repository for Room Inspection operations
class RoomInspectionRepository {
  final ApiClient _apiClient;

  RoomInspectionRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== Room Inspections ====================

  /// Get all room inspections with optional filters
  Future<List<RoomInspection>> getInspections({
    int? roomId,
    InspectionStatus? status,
    InspectionType? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (roomId != null) {
      queryParams['room'] = roomId.toString();
    }
    if (status != null) {
      queryParams['status'] = _statusToApi(status);
    }
    if (type != null) {
      queryParams['inspection_type'] = _typeToApi(type);
    }
    if (fromDate != null) {
      queryParams['from_date'] = _formatDate(fromDate);
    }
    if (toDate != null) {
      queryParams['to_date'] = _formatDate(toDate);
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.roomInspectionsEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return _parseListResponse(response.data);
  }

  /// Get a single inspection by ID
  Future<RoomInspection> getInspection(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.roomInspectionsEndpoint}$id/',
    );
    return RoomInspection.fromJson(response.data!);
  }

  /// Create a new inspection
  Future<RoomInspection> createInspection(RoomInspectionCreate data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.roomInspectionsEndpoint,
      data: data.toJson(),
    );
    return RoomInspection.fromJson(response.data!);
  }

  /// Update an inspection
  Future<RoomInspection> updateInspection(
    int id,
    RoomInspectionUpdate data,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.roomInspectionsEndpoint}$id/',
      data: data.toJson(),
    );
    return RoomInspection.fromJson(response.data!);
  }

  /// Delete an inspection
  Future<void> deleteInspection(int id) async {
    await _apiClient.delete('${AppConstants.roomInspectionsEndpoint}$id/');
  }

  /// Start an inspection
  Future<RoomInspection> startInspection(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.roomInspectionsEndpoint}$id/start/',
    );
    return RoomInspection.fromJson(response.data!);
  }

  /// Complete an inspection
  Future<RoomInspection> completeInspection(
    int id,
    CompleteInspection data,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.roomInspectionsEndpoint}$id/complete/',
      data: data.toJson(),
    );
    return RoomInspection.fromJson(response.data!);
  }

  /// Create inspection from checkout
  Future<RoomInspection> createFromCheckout(
    int bookingId, {
    int? templateId,
  }) async {
    final data = <String, dynamic>{'booking_id': bookingId};
    if (templateId != null) {
      data['template_id'] = templateId;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.roomInspectionsEndpoint}from-checkout/',
      data: data,
    );
    return RoomInspection.fromJson(response.data!);
  }

  /// Get pending inspections for today
  Future<List<RoomInspection>> getPendingToday() async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.roomInspectionsEndpoint}pending-today/',
    );
    return _parseListResponse(response.data);
  }

  /// Get inspection statistics
  Future<InspectionStatistics> getStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (fromDate != null) {
      queryParams['from_date'] = _formatDate(fromDate);
    }
    if (toDate != null) {
      queryParams['to_date'] = _formatDate(toDate);
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.roomInspectionsEndpoint}statistics/',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return InspectionStatistics.fromJson(response.data!);
  }

  // ==================== Inspection Templates ====================

  /// Get all inspection templates
  Future<List<InspectionTemplate>> getTemplates({
    InspectionType? type,
    int? roomTypeId,
    bool? isDefault,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};

    if (type != null) {
      queryParams['inspection_type'] = _typeToApi(type);
    }
    if (roomTypeId != null) {
      queryParams['room_type'] = roomTypeId.toString();
    }
    if (isDefault != null) {
      queryParams['is_default'] = isDefault.toString();
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.inspectionTemplatesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return _parseTemplateListResponse(response.data);
  }

  /// Get a single template by ID
  Future<InspectionTemplate> getTemplate(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.inspectionTemplatesEndpoint}$id/',
    );
    return InspectionTemplate.fromJson(response.data!);
  }

  /// Create a new template
  Future<InspectionTemplate> createTemplate(
    InspectionTemplateCreate data,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.inspectionTemplatesEndpoint,
      data: data.toJson(),
    );
    return InspectionTemplate.fromJson(response.data!);
  }

  /// Update a template
  Future<InspectionTemplate> updateTemplate(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.inspectionTemplatesEndpoint}$id/',
      data: data,
    );
    return InspectionTemplate.fromJson(response.data!);
  }

  /// Delete a template
  Future<void> deleteTemplate(int id) async {
    await _apiClient.delete('${AppConstants.inspectionTemplatesEndpoint}$id/');
  }

  /// Get default templates by type
  Future<List<InspectionTemplate>> getDefaultTemplates({
    InspectionType? type,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) {
      queryParams['inspection_type'] = _typeToApi(type);
    }

    final response = await _apiClient.get<dynamic>(
      '${AppConstants.inspectionTemplatesEndpoint}defaults/',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return _parseTemplateListResponse(response.data);
  }

  // ==================== Helper Methods ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _statusToApi(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.pending:
        return 'pending';
      case InspectionStatus.inProgress:
        return 'in_progress';
      case InspectionStatus.completed:
        return 'completed';
      case InspectionStatus.requiresAction:
        return 'requires_action';
    }
  }

  String _typeToApi(InspectionType type) {
    switch (type) {
      case InspectionType.checkout:
        return 'checkout';
      case InspectionType.checkin:
        return 'checkin';
      case InspectionType.routine:
        return 'routine';
      case InspectionType.maintenance:
        return 'maintenance';
      case InspectionType.deepClean:
        return 'deep_clean';
    }
  }

  List<RoomInspection> _parseListResponse(dynamic data) {
    if (data == null) {
      return [];
    }

    // Handle paginated response
    if (data is Map<String, dynamic>) {
      if (data.containsKey('results')) {
        final results = data['results'] as List<dynamic>;
        return results
            .map(
              (json) => RoomInspection.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    }

    // Handle non-paginated response
    if (data is List) {
      return data
          .map((json) => RoomInspection.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  List<InspectionTemplate> _parseTemplateListResponse(dynamic data) {
    if (data == null) {
      return [];
    }

    // Handle paginated response
    if (data is Map<String, dynamic>) {
      if (data.containsKey('results')) {
        final results = data['results'] as List<dynamic>;
        return results
            .map(
              (json) =>
                  InspectionTemplate.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    }

    // Handle non-paginated response
    if (data is List) {
      return data
          .map(
            (json) => InspectionTemplate.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }
}
