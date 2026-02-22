import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/lost_found.dart';

/// Repository for Lost & Found operations
class LostFoundRepository {
  final ApiClient _apiClient;

  LostFoundRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== Lost & Found Items ====================

  /// Get all lost & found items with optional filters
  Future<List<LostFoundItem>> getItems({
    LostFoundStatus? status,
    LostFoundCategory? category,
    int? roomId,
    int? guestId,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (status != null) {
      queryParams['status'] = status.name;
    }
    if (category != null) {
      queryParams['category'] = category.name;
    }
    if (roomId != null) {
      queryParams['room'] = roomId.toString();
    }
    if (guestId != null) {
      queryParams['guest'] = guestId.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (fromDate != null) {
      queryParams['found_date_after'] = _formatDate(fromDate);
    }
    if (toDate != null) {
      queryParams['found_date_before'] = _formatDate(toDate);
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.lostFoundEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle paginated response
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final results = dataMap['results'] as List<dynamic>;
        return results
            .map((json) => LostFoundItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    // Handle non-paginated response
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => LostFoundItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get a single lost & found item by ID
  Future<LostFoundItem> getItem(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.lostFoundEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Item not found');
    }
    return LostFoundItem.fromJson(response.data!);
  }

  /// Create a new lost & found item
  Future<LostFoundItem> createItem(LostFoundItemCreate item) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.lostFoundEndpoint,
      data: item.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to create item');
    }
    return LostFoundItem.fromJson(response.data!);
  }

  /// Update an existing lost & found item
  Future<LostFoundItem> updateItem(int id, LostFoundItemUpdate update) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.lostFoundEndpoint}$id/',
      data: update.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to update item');
    }
    return LostFoundItem.fromJson(response.data!);
  }

  /// Delete a lost & found item
  Future<void> deleteItem(int id) async {
    await _apiClient.delete<dynamic>('${AppConstants.lostFoundEndpoint}$id/');
  }

  // ==================== Actions ====================

  /// Mark item as stored (moved to storage location)
  Future<LostFoundItem> storeItem(int id, {String? storageLocation}) async {
    final data = <String, dynamic>{};
    if (storageLocation != null) {
      data['storage_location'] = storageLocation;
    }
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.lostFoundEndpoint}$id/store/',
      data: data.isNotEmpty ? data : null,
    );
    if (response.data == null) {
      throw Exception('Failed to store item');
    }
    return LostFoundItem.fromJson(response.data!);
  }

  /// Mark item as claimed by guest
  Future<LostFoundItem> claimItem(
    int id, {
    int? claimedByStaff,
    String? notes,
  }) async {
    final data = <String, dynamic>{};
    if (claimedByStaff != null) {
      data['claimed_by_staff'] = claimedByStaff;
    }
    if (notes != null) {
      data['notes'] = notes;
    }
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.lostFoundEndpoint}$id/claim/',
      data: data.isNotEmpty ? data : null,
    );
    if (response.data == null) {
      throw Exception('Failed to claim item');
    }
    return LostFoundItem.fromJson(response.data!);
  }

  /// Mark item as disposed or donated
  Future<LostFoundItem> disposeItem(
    int id, {
    required String reason,
    String? notes,
  }) async {
    final data = <String, dynamic>{'reason': reason};
    if (notes != null) {
      data['notes'] = notes;
    }
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.lostFoundEndpoint}$id/dispose/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to dispose item');
    }
    return LostFoundItem.fromJson(response.data!);
  }

  // ==================== Statistics ====================

  /// Get lost & found statistics
  Future<LostFoundStatistics> getStatistics() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.lostFoundEndpoint}statistics/',
    );
    if (response.data == null) {
      throw Exception('Failed to get statistics');
    }
    return LostFoundStatistics.fromJson(response.data!);
  }

  // ==================== Helper Methods ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
