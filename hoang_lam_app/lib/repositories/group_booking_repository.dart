import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/group_booking.dart';

/// Repository for Group Booking operations
class GroupBookingRepository {
  final ApiClient _apiClient;

  GroupBookingRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==================== Group Bookings ====================

  /// Get all group bookings with optional filters
  Future<List<GroupBooking>> getGroupBookings({
    GroupBookingStatus? status,
    DateTime? checkInFrom,
    DateTime? checkInTo,
    DateTime? checkOutFrom,
    DateTime? checkOutTo,
    String? search,
    int? roomId,
  }) async {
    final queryParams = <String, dynamic>{};

    if (status != null) {
      queryParams['status'] = status.name;
    }
    if (checkInFrom != null) {
      queryParams['check_in_date_after'] = _formatDate(checkInFrom);
    }
    if (checkInTo != null) {
      queryParams['check_in_date_before'] = _formatDate(checkInTo);
    }
    if (checkOutFrom != null) {
      queryParams['check_out_date_after'] = _formatDate(checkOutFrom);
    }
    if (checkOutTo != null) {
      queryParams['check_out_date_before'] = _formatDate(checkOutTo);
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (roomId != null) {
      queryParams['rooms'] = roomId.toString();
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.groupBookingsEndpoint,
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
            .map((json) => GroupBooking.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    // Handle non-paginated response
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => GroupBooking.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get a single group booking by ID
  Future<GroupBooking> getGroupBooking(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.groupBookingsEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Group booking not found');
    }
    return GroupBooking.fromJson(response.data!);
  }

  /// Create a new group booking
  Future<GroupBooking> createGroupBooking(GroupBookingCreate booking) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.groupBookingsEndpoint,
      data: booking.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to create group booking');
    }
    return GroupBooking.fromJson(response.data!);
  }

  /// Update an existing group booking
  Future<GroupBooking> updateGroupBooking(
    int id,
    GroupBookingUpdate update,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.groupBookingsEndpoint}$id/',
      data: update.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to update group booking');
    }
    return GroupBooking.fromJson(response.data!);
  }

  /// Delete a group booking
  Future<void> deleteGroupBooking(int id) async {
    await _apiClient.delete<dynamic>(
      '${AppConstants.groupBookingsEndpoint}$id/',
    );
  }

  // ==================== Actions ====================

  /// Confirm a tentative group booking
  Future<GroupBooking> confirmGroupBooking(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.groupBookingsEndpoint}$id/confirm/',
    );
    if (response.data == null) {
      throw Exception('Failed to confirm group booking');
    }
    return GroupBooking.fromJson(response.data!);
  }

  /// Check in a group booking
  Future<GroupBooking> checkInGroupBooking(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.groupBookingsEndpoint}$id/check-in/',
    );
    if (response.data == null) {
      throw Exception('Failed to check in group booking');
    }
    return GroupBooking.fromJson(response.data!);
  }

  /// Check out a group booking
  Future<GroupBooking> checkOutGroupBooking(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.groupBookingsEndpoint}$id/check-out/',
    );
    if (response.data == null) {
      throw Exception('Failed to check out group booking');
    }
    return GroupBooking.fromJson(response.data!);
  }

  /// Cancel a group booking
  Future<GroupBooking> cancelGroupBooking(int id, {String? reason}) async {
    final data = <String, dynamic>{};
    if (reason != null) {
      data['reason'] = reason;
    }
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.groupBookingsEndpoint}$id/cancel/',
      data: data.isNotEmpty ? data : null,
    );
    if (response.data == null) {
      throw Exception('Failed to cancel group booking');
    }
    return GroupBooking.fromJson(response.data!);
  }

  /// Assign rooms to a group booking
  Future<GroupBooking> assignRooms(int id, List<int> roomIds) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.groupBookingsEndpoint}$id/assign-rooms/',
      data: {'rooms': roomIds},
    );
    if (response.data == null) {
      throw Exception('Failed to assign rooms');
    }
    return GroupBooking.fromJson(response.data!);
  }

  // ==================== Statistics ====================

  /// Get upcoming group bookings (next 7 days)
  Future<List<GroupBooking>> getUpcomingGroupBookings() async {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    return getGroupBookings(
      checkInFrom: now,
      checkInTo: weekLater,
      status: GroupBookingStatus.confirmed,
    );
  }

  /// Get today's check-ins
  Future<List<GroupBooking>> getTodayCheckIns() async {
    final now = DateTime.now();
    return getGroupBookings(
      checkInFrom: now,
      checkInTo: now,
      status: GroupBookingStatus.confirmed,
    );
  }

  /// Get today's check-outs
  Future<List<GroupBooking>> getTodayCheckOuts() async {
    final now = DateTime.now();
    return getGroupBookings(
      checkOutFrom: now,
      checkOutTo: now,
      status: GroupBookingStatus.checkedIn,
    );
  }

  // ==================== Helper Methods ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
