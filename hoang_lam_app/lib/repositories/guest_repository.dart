import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/guest.dart';

/// Repository for guest management operations
class GuestRepository {
  final ApiClient _apiClient;

  GuestRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

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

    final response = await _apiClient.get<dynamic>(
      AppConstants.guestsEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    // Ensure response.data exists
    if (response.data == null) {
      return [];
    }

    // Handle both paginated and non-paginated responses
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = GuestListResponse.fromJson(dataMap);
        return listResponse.results;
      }
    }

    // Non-paginated response (list directly)
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => Guest.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get a single guest by ID
  Future<Guest> getGuest(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.guestsEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Guest not found');
    }
    return Guest.fromJson(response.data!);
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
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.guestsEndpoint}search/',
      data: {
        'query': query,
        'search_by': searchBy,
      },
    );

    if (response.data == null) {
      return [];
    }

    // Handle response format
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

    // Direct list response
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => Guest.fromJson(json as Map<String, dynamic>))
          .toList();
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
      data['id_issue_date'] = guest.idIssueDate!.toIso8601String().split('T')[0];
    }
    if (guest.idIssuePlace.isNotEmpty) {
      data['id_issue_place'] = guest.idIssuePlace;
    }
    if (guest.dateOfBirth != null) {
      data['date_of_birth'] = guest.dateOfBirth!.toIso8601String().split('T')[0];
    }
    if (guest.gender != null) {
      data['gender'] = guest.gender!.name;
    }
    if (guest.preferences.isNotEmpty) {
      data['preferences'] = guest.preferences;
    }

    return data;
  }
}
