import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/rate_plan.dart';

/// Repository for rate plan and date rate override operations
class RatePlanRepository {
  final ApiClient _apiClient;

  RatePlanRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== Rate Plans ====================

  /// Get all rate plans with optional filters
  Future<List<RatePlanListItem>> getRatePlans({
    int? roomTypeId,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};
    if (roomTypeId != null) {
      queryParams['room_type'] = roomTypeId.toString();
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.ratePlansEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both paginated and non-paginated responses
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final list = dataMap['results'] as List<dynamic>;
        return list
            .map(
              (json) => RatePlanListItem.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    }

    // Non-paginated response (list directly)
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => RatePlanListItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get rate plans for a specific room type
  Future<List<RatePlanListItem>> getRatePlansByRoomType(int roomTypeId) async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.ratePlansEndpoint}by-room-type/$roomTypeId/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => RatePlanListItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get a single rate plan by ID
  Future<RatePlan> getRatePlan(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.ratePlansEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Rate plan not found');
    }
    return RatePlan.fromJson(response.data!);
  }

  /// Create a new rate plan
  Future<RatePlan> createRatePlan(RatePlanCreateRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.ratePlansEndpoint,
      data: request.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to create rate plan');
    }
    return RatePlan.fromJson(response.data!);
  }

  /// Update an existing rate plan
  Future<RatePlan> updateRatePlan(int id, Map<String, dynamic> updates) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.ratePlansEndpoint}$id/',
      data: updates,
    );
    if (response.data == null) {
      throw Exception('Failed to update rate plan');
    }
    return RatePlan.fromJson(response.data!);
  }

  /// Delete a rate plan
  Future<void> deleteRatePlan(int id) async {
    await _apiClient.delete('${AppConstants.ratePlansEndpoint}$id/');
  }

  // ==================== Date Rate Overrides ====================

  /// Get all date rate overrides with optional filters
  Future<List<DateRateOverrideListItem>> getDateRateOverrides({
    int? roomTypeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (roomTypeId != null) {
      queryParams['room_type'] = roomTypeId.toString();
    }
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.dateRateOverridesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both paginated and non-paginated responses
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final list = dataMap['results'] as List<dynamic>;
        return list
            .map(
              (json) => DateRateOverrideListItem.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      }
    }

    // Non-paginated response (list directly)
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) =>
                DateRateOverrideListItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get date rate overrides for a specific room type and date range
  Future<List<DateRateOverrideListItem>> getDateRateOverridesByRoomType(
    int roomTypeId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    };

    final response = await _apiClient.get<dynamic>(
      '${AppConstants.dateRateOverridesEndpoint}by-room-type/$roomTypeId/',
      queryParameters: queryParams,
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) =>
                DateRateOverrideListItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get a single date rate override by ID
  Future<DateRateOverride> getDateRateOverride(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.dateRateOverridesEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Date rate override not found');
    }
    return DateRateOverride.fromJson(response.data!);
  }

  /// Create a new date rate override
  Future<DateRateOverride> createDateRateOverride(
    DateRateOverrideCreateRequest request,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.dateRateOverridesEndpoint,
      data: request.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to create date rate override');
    }
    return DateRateOverride.fromJson(response.data!);
  }

  /// Bulk create date rate overrides for a date range
  Future<List<DateRateOverride>> bulkCreateDateRateOverrides(
    DateRateOverrideBulkCreateRequest request,
  ) async {
    final response = await _apiClient.post<dynamic>(
      '${AppConstants.dateRateOverridesEndpoint}bulk-create/',
      data: request.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to create date rate overrides');
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => DateRateOverride.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Update an existing date rate override
  Future<DateRateOverride> updateDateRateOverride(
    int id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.dateRateOverridesEndpoint}$id/',
      data: updates,
    );
    if (response.data == null) {
      throw Exception('Failed to update date rate override');
    }
    return DateRateOverride.fromJson(response.data!);
  }

  /// Delete a date rate override
  Future<void> deleteDateRateOverride(int id) async {
    await _apiClient.delete('${AppConstants.dateRateOverridesEndpoint}$id/');
  }
}
