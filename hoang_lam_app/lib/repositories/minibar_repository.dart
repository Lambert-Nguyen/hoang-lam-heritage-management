import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/minibar.dart';

/// Repository for minibar item and sale operations
class MinibarRepository {
  final ApiClient _apiClient;

  MinibarRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==================== Minibar Items ====================

  /// Get all minibar items with optional filters
  Future<List<MinibarItem>> getItems({
    bool? isActive,
    String? category,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};

    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.minibarItemsEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle paginated response
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = MinibarItemListResponse.fromJson(dataMap);
        return listResponse.results;
      }
    }

    // Handle non-paginated response
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => MinibarItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get active minibar items
  Future<List<MinibarItem>> getActiveItems() async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.minibarItemsEndpoint}active/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => MinibarItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get minibar item categories
  Future<List<String>> getCategories() async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.minibarItemsEndpoint}categories/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return [];
  }

  /// Get a single minibar item by ID
  Future<MinibarItem> getItem(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.minibarItemsEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Item not found');
    }
    return MinibarItem.fromJson(response.data!);
  }

  /// Create a new minibar item
  Future<MinibarItem> createItem(CreateMinibarItemRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.minibarItemsEndpoint,
      data: request.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to create item');
    }
    return MinibarItem.fromJson(response.data!);
  }

  /// Update an existing minibar item
  Future<MinibarItem> updateItem(int id, UpdateMinibarItemRequest request) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.minibarItemsEndpoint}$id/',
      data: request.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to update item');
    }
    return MinibarItem.fromJson(response.data!);
  }

  /// Delete a minibar item
  Future<void> deleteItem(int id) async {
    await _apiClient.delete('${AppConstants.minibarItemsEndpoint}$id/');
  }

  /// Toggle minibar item active status
  Future<MinibarItem> toggleItemActive(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.minibarItemsEndpoint}$id/toggle_active/',
    );
    if (response.data == null) {
      throw Exception('Failed to toggle item status');
    }
    return MinibarItem.fromJson(response.data!);
  }

  // ==================== Minibar Sales ====================

  /// Get all minibar sales with optional filters
  Future<List<MinibarSale>> getSales({
    int? bookingId,
    int? roomId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isCharged,
  }) async {
    final queryParams = <String, dynamic>{};

    if (bookingId != null) {
      queryParams['booking'] = bookingId.toString();
    }
    if (roomId != null) {
      queryParams['room'] = roomId.toString();
    }
    if (dateFrom != null) {
      queryParams['date_from'] = _formatDate(dateFrom);
    }
    if (dateTo != null) {
      queryParams['date_to'] = _formatDate(dateTo);
    }
    if (isCharged != null) {
      queryParams['is_charged'] = isCharged.toString();
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.minibarSalesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle paginated response
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = MinibarSaleListResponse.fromJson(dataMap);
        return listResponse.results;
      }
    }

    // Handle non-paginated response
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => MinibarSale.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get a single minibar sale by ID
  Future<MinibarSale> getSale(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.minibarSalesEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Sale not found');
    }
    return MinibarSale.fromJson(response.data!);
  }

  /// Create a new minibar sale
  Future<MinibarSale> createSale(CreateMinibarSaleRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.minibarSalesEndpoint,
      data: {
        'booking': request.booking,
        'item': request.item,
        'quantity': request.quantity,
        'date': _formatDate(request.date),
      },
    );
    if (response.data == null) {
      throw Exception('Failed to create sale');
    }
    return MinibarSale.fromJson(response.data!);
  }

  /// Create multiple minibar sales at once
  Future<List<MinibarSale>> bulkCreateSales(
      BulkCreateMinibarSaleRequest request) async {
    final response = await _apiClient.post<dynamic>(
      '${AppConstants.minibarSalesEndpoint}bulk_create/',
      data: {
        'booking': request.booking,
        'items': request.items.map((e) => e.toJson()).toList(),
        if (request.date != null) 'date': _formatDate(request.date!),
      },
    );

    if (response.data == null) {
      throw Exception('Failed to create sales');
    }

    if (response.data is List) {
      return (response.data as List<dynamic>)
          .map((json) => MinibarSale.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Update a minibar sale
  Future<MinibarSale> updateSale(int id, {int? quantity, bool? isCharged}) async {
    final data = <String, dynamic>{};
    if (quantity != null) data['quantity'] = quantity;
    if (isCharged != null) data['is_charged'] = isCharged;

    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.minibarSalesEndpoint}$id/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to update sale');
    }
    return MinibarSale.fromJson(response.data!);
  }

  /// Delete a minibar sale
  Future<void> deleteSale(int id) async {
    await _apiClient.delete('${AppConstants.minibarSalesEndpoint}$id/');
  }

  /// Mark a sale as charged
  Future<MinibarSale> markSaleCharged(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.minibarSalesEndpoint}$id/mark_charged/',
    );
    if (response.data == null) {
      throw Exception('Failed to mark sale as charged');
    }
    return MinibarSale.fromJson(response.data!);
  }

  /// Unmark a sale as charged
  Future<MinibarSale> unmarkSaleCharged(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.minibarSalesEndpoint}$id/unmark_charged/',
    );
    if (response.data == null) {
      throw Exception('Failed to unmark sale as charged');
    }
    return MinibarSale.fromJson(response.data!);
  }

  /// Get uncharged sales for a booking
  Future<List<MinibarSale>> getUnchargedSales(int bookingId) async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.minibarSalesEndpoint}uncharged/',
      queryParameters: {'booking': bookingId.toString()},
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List<dynamic>)
          .map((json) => MinibarSale.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Charge all uncharged sales for a booking
  Future<ChargeAllResponse> chargeAllSales(int bookingId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.minibarSalesEndpoint}charge_all/',
      data: {'booking': bookingId},
    );
    if (response.data == null) {
      throw Exception('Failed to charge all sales');
    }
    return ChargeAllResponse.fromJson(response.data!);
  }

  /// Get sales summary for a booking
  Future<MinibarSalesSummary> getSalesSummary(int bookingId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.minibarSalesEndpoint}summary/',
      queryParameters: {'booking': bookingId.toString()},
    );
    if (response.data == null) {
      throw Exception('Failed to get sales summary');
    }
    return MinibarSalesSummary.fromJson(response.data!);
  }

  // ==================== Helpers ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
