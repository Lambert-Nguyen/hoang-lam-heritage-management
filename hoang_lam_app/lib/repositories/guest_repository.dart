import 'package:dio/dio.dart';

import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/hive_storage.dart';
import '../models/guest.dart';

/// Repository for guest management operations
class GuestRepository {
  final ApiClient _apiClient;

  GuestRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== Guest CRUD ====================

  /// Get all guests with optional filters
  Future<List<Guest>> getGuests({
    String? search,
    bool? isVip,
    String? nationality,
    String? ordering,
  }) async {
    final queryParams = <String, dynamic>{};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isVip != null) {
      queryParams['is_vip'] = isVip.toString();
    }
    if (nationality != null && nationality.isNotEmpty) {
      queryParams['nationality'] = nationality;
    }
    if (ordering != null && ordering.isNotEmpty) {
      queryParams['ordering'] = ordering;
    }

    try {
      final response = await _apiClient.get<dynamic>(
        AppConstants.guestsEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Ensure response.data exists
      if (response.data == null) {
        return [];
      }

      List<Guest> guests;

      // Handle both paginated and non-paginated responses
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        if (dataMap.containsKey('results')) {
          final listResponse = GuestListResponse.fromJson(dataMap);
          guests = listResponse.results;
        } else {
          guests = [];
        }
      } else if (response.data is List) {
        final list = response.data as List<dynamic>;
        guests =
            list
                .map((json) => Guest.fromJson(json as Map<String, dynamic>))
                .toList();
      } else {
        guests = [];
      }

      // Cache results on success (only for unfiltered default queries)
      if (queryParams.isEmpty ||
          (queryParams.length == 1 && queryParams.containsKey('ordering'))) {
        await _cacheGuestList(guests);
      }
      await _cacheGuestsIndividually(guests);

      return guests;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        return _getCachedGuestList();
      }
      rethrow;
    }
  }

  /// Get a single guest by ID
  Future<Guest> getGuest(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConstants.guestsEndpoint}$id/',
      );
      if (response.data == null) {
        throw Exception('Guest not found');
      }
      final guest = Guest.fromJson(response.data!);
      await _cacheGuest(guest);
      return guest;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        return _getCachedGuest(id);
      }
      rethrow;
    }
  }

  /// Create a new guest
  Future<Guest> createGuest(Guest guest) async {
    final data = _prepareGuestData(guest);
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.guestsEndpoint,
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to create guest');
    }
    return Guest.fromJson(response.data!);
  }

  /// Update an existing guest
  Future<Guest> updateGuest(Guest guest) async {
    final data = _prepareGuestData(guest);
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${AppConstants.guestsEndpoint}${guest.id}/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to update guest');
    }
    return Guest.fromJson(response.data!);
  }

  /// Partial update (PATCH) an existing guest
  Future<Guest> patchGuest(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.guestsEndpoint}$id/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to patch guest');
    }
    return Guest.fromJson(response.data!);
  }

  /// Delete a guest
  Future<void> deleteGuest(int id) async {
    await _apiClient.delete('${AppConstants.guestsEndpoint}$id/');
  }

  // ==================== Guest Search ====================

  /// Search guests by query (name, phone, or ID number)
  Future<List<Guest>> searchGuests({
    required String query,
    String searchBy = 'all',
  }) async {
    final response = await _apiClient.post<dynamic>(
      '${AppConstants.guestsEndpoint}search/',
      data: {'query': query, 'search_by': searchBy},
    );

    if (response.data == null) {
      return [];
    }

    // Direct list response (backend returns array directly)
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => Guest.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    // Handle response format wrapped in object
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = GuestListResponse.fromJson(dataMap);
        return listResponse.results;
      } else if (dataMap.containsKey('guests')) {
        final list = dataMap['guests'] as List<dynamic>;
        return list
            .map((json) => Guest.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  // ==================== Guest History ====================

  /// Get guest history (bookings)
  Future<GuestHistoryResponse> getGuestHistory(int guestId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.guestsEndpoint}$guestId/history/',
    );
    if (response.data == null) {
      throw Exception('Failed to get guest history');
    }
    return GuestHistoryResponse.fromJson(response.data!);
  }

  // ==================== Convenience Methods ====================

  /// Find guest by phone number
  Future<Guest?> findByPhone(String phone) async {
    try {
      final guests = await searchGuests(query: phone, searchBy: 'phone');
      return guests.isNotEmpty ? guests.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Find guest by ID number (CCCD/Passport)
  Future<Guest?> findByIdNumber(String idNumber) async {
    try {
      final guests = await searchGuests(query: idNumber, searchBy: 'id_number');
      return guests.isNotEmpty ? guests.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Get VIP guests
  Future<List<Guest>> getVipGuests() async {
    return getGuests(isVip: true, ordering: '-total_stays');
  }

  /// Get returning guests
  Future<List<Guest>> getReturningGuests() async {
    final guests = await getGuests(ordering: '-total_stays');
    return guests.where((g) => g.isReturningGuest).toList();
  }

  /// Get recent guests (by creation date)
  Future<List<Guest>> getRecentGuests({int limit = 10}) async {
    final guests = await getGuests(ordering: '-created_at');
    return guests.take(limit).toList();
  }

  /// Get guests by nationality
  Future<List<Guest>> getGuestsByNationality(String nationality) async {
    return getGuests(nationality: nationality, ordering: '-created_at');
  }

  /// Toggle VIP status
  Future<Guest> toggleVipStatus(int guestId) async {
    final guest = await getGuest(guestId);
    return patchGuest(guestId, {'is_vip': !guest.isVip});
  }

  // ==================== Private Helpers ====================

  /// Prepare guest data for API submission
  Map<String, dynamic> _prepareGuestData(Guest guest) {
    final data = <String, dynamic>{
      'full_name': guest.fullName,
      'phone': guest.phone,
      'email': guest.email,
      'id_type': guest.idType.name,
      'nationality': guest.nationality,
      'address': guest.address,
      'city': guest.city,
      'country': guest.country,
      'is_vip': guest.isVip,
      'notes': guest.notes,
    };

    // Only include optional fields if they have values
    if (guest.idNumber != null && guest.idNumber!.isNotEmpty) {
      data['id_number'] = guest.idNumber;
    }
    if (guest.idIssueDate != null) {
      data['id_issue_date'] =
          guest.idIssueDate!.toIso8601String().split('T')[0];
    }
    if (guest.idIssuePlace.isNotEmpty) {
      data['id_issue_place'] = guest.idIssuePlace;
    }
    if (guest.dateOfBirth != null) {
      data['date_of_birth'] =
          guest.dateOfBirth!.toIso8601String().split('T')[0];
    }
    if (guest.gender != null) {
      data['gender'] = guest.gender!.name;
    }
    if (guest.preferences.isNotEmpty) {
      data['preferences'] = guest.preferences;
    }

    return data;
  }

  // ==================== Cache Helpers ====================

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }

  Future<void> _cacheGuest(Guest guest) async {
    final box = await HiveStorage.guestsBox;
    await box.put('guest_${guest.id}', guest.toJson());
  }

  Future<void> _cacheGuestsIndividually(List<Guest> guests) async {
    final box = await HiveStorage.guestsBox;
    for (final guest in guests) {
      await box.put('guest_${guest.id}', guest.toJson());
    }
  }

  Future<void> _cacheGuestList(List<Guest> guests) async {
    final box = await HiveStorage.guestsBox;
    final ids = guests.map((g) => g.id).toList();
    await box.put('_list_default', ids);
  }

  Future<List<Guest>> _getCachedGuestList() async {
    final box = await HiveStorage.guestsBox;
    final ids = box.get('_list_default');
    if (ids == null || ids is! List) return [];

    final guests = <Guest>[];
    for (final id in ids) {
      final json = box.get('guest_$id');
      if (json != null && json is Map) {
        try {
          guests.add(Guest.fromJson(Map<String, dynamic>.from(json)));
        } catch (_) {
          // Skip corrupted cache entries
        }
      }
    }
    return guests;
  }

  Future<Guest> _getCachedGuest(int id) async {
    final box = await HiveStorage.guestsBox;
    final json = box.get('guest_$id');
    if (json != null && json is Map) {
      return Guest.fromJson(Map<String, dynamic>.from(json));
    }
    throw Exception('Guest not found in cache');
  }
}
