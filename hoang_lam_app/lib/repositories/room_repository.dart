import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/room.dart';

/// Repository for room management operations
class RoomRepository {
  final ApiClient _apiClient;

  RoomRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // ==================== Room Types ====================

  /// Get all room types
  Future<List<RoomType>> getRoomTypes({bool? isActive}) async {
    final queryParams = <String, dynamic>{};
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      AppConstants.roomTypesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    // Handle both paginated and non-paginated responses
    if (response.data!.containsKey('results')) {
      final listResponse = RoomTypeListResponse.fromJson(response.data!);
      return listResponse.results;
    } else {
      // Non-paginated response (list directly)
      final list = response.data! as List<dynamic>;
      return list
          .map((json) => RoomType.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  /// Get a single room type by ID
  Future<RoomType> getRoomType(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.roomTypesEndpoint}$id/',
    );
    return RoomType.fromJson(response.data!);
  }

  /// Create a new room type
  Future<RoomType> createRoomType(RoomType roomType) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.roomTypesEndpoint,
      data: roomType.toJson(),
    );
    return RoomType.fromJson(response.data!);
  }

  /// Update an existing room type
  Future<RoomType> updateRoomType(RoomType roomType) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${AppConstants.roomTypesEndpoint}${roomType.id}/',
      data: roomType.toJson(),
    );
    return RoomType.fromJson(response.data!);
  }

  /// Delete a room type
  Future<void> deleteRoomType(int id) async {
    await _apiClient.delete('${AppConstants.roomTypesEndpoint}$id/');
  }

  // ==================== Rooms ====================

  /// Get all rooms with optional filters
  Future<List<Room>> getRooms({
    RoomStatus? status,
    int? roomTypeId,
    int? floor,
    bool? isActive,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};

    if (status != null) {
      queryParams['status'] = status.name;
    }
    if (roomTypeId != null) {
      queryParams['room_type'] = roomTypeId.toString();
    }
    if (floor != null) {
      queryParams['floor'] = floor.toString();
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      AppConstants.roomsEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    // Handle both paginated and non-paginated responses
    if (response.data!.containsKey('results')) {
      final listResponse = RoomListResponse.fromJson(response.data!);
      return listResponse.results;
    } else {
      // Non-paginated response (list directly)
      final list = response.data! as List<dynamic>;
      return list
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  /// Get a single room by ID
  Future<Room> getRoom(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.roomsEndpoint}$id/',
    );
    return Room.fromJson(response.data!);
  }

  /// Create a new room
  Future<Room> createRoom(Room room) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.roomsEndpoint,
      data: room.toJson(),
    );
    return Room.fromJson(response.data!);
  }

  /// Update an existing room
  Future<Room> updateRoom(Room room) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${AppConstants.roomsEndpoint}${room.id}/',
      data: room.toJson(),
    );
    return Room.fromJson(response.data!);
  }

  /// Delete a room
  Future<void> deleteRoom(int id) async {
    await _apiClient.delete('${AppConstants.roomsEndpoint}$id/');
  }

  /// Update room status
  Future<Room> updateRoomStatus(int roomId, RoomStatusUpdateRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.roomsEndpoint}$roomId/update-status/',
      data: request.toJson(),
    );
    return Room.fromJson(response.data!);
  }

  /// Check room availability for a date range
  Future<RoomAvailabilityResponse> checkAvailability(
    RoomAvailabilityRequest request,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.roomsEndpoint}check-availability/',
      data: {
        'check_in': request.checkIn.toIso8601String().split('T')[0],
        'check_out': request.checkOut.toIso8601String().split('T')[0],
        if (request.roomTypeId != null) 'room_type': request.roomTypeId,
      },
    );
    return RoomAvailabilityResponse.fromJson(response.data!);
  }

  // ==================== Convenience Methods ====================

  /// Get rooms grouped by floor
  Future<Map<int, List<Room>>> getRoomsGroupedByFloor() async {
    final rooms = await getRooms(isActive: true);
    final grouped = <int, List<Room>>{};

    for (final room in rooms) {
      grouped.putIfAbsent(room.floor, () => []).add(room);
    }

    // Sort each floor's rooms by number
    for (final floor in grouped.keys) {
      grouped[floor]!.sort((a, b) => a.number.compareTo(b.number));
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Get available rooms for a date range
  Future<List<Room>> getAvailableRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    int? roomTypeId,
  }) async {
    final response = await checkAvailability(
      RoomAvailabilityRequest(
        checkIn: checkIn,
        checkOut: checkOut,
        roomTypeId: roomTypeId,
      ),
    );
    return response.availableRooms;
  }

  /// Get room status counts for dashboard
  Future<Map<RoomStatus, int>> getRoomStatusCounts() async {
    final rooms = await getRooms(isActive: true);
    final counts = <RoomStatus, int>{};

    for (final status in RoomStatus.values) {
      counts[status] = rooms.where((r) => r.status == status).length;
    }

    return counts;
  }
}
