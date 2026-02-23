import 'package:dio/dio.dart';

import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/hive_storage.dart';
import '../models/booking.dart';

/// Repository for booking management operations
class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== Booking CRUD ====================

  /// Get all bookings with optional filters
  Future<List<Booking>> getBookings({
    String? status,
    int? roomId,
    int? guestId,
    String? source,
    DateTime? checkInFrom,
    DateTime? checkInTo,
    DateTime? checkOutFrom,
    DateTime? checkOutTo,
    String? ordering,
  }) async {
    final queryParams = <String, dynamic>{};

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (roomId != null) {
      queryParams['room'] = roomId.toString();
    }
    if (guestId != null) {
      queryParams['guest'] = guestId.toString();
    }
    if (source != null && source.isNotEmpty) {
      queryParams['source'] = source;
    }
    if (checkInFrom != null) {
      queryParams['check_in_date_from'] = checkInFrom.toIso8601String().split(
        'T',
      )[0];
    }
    if (checkInTo != null) {
      queryParams['check_in_date_to'] = checkInTo.toIso8601String().split(
        'T',
      )[0];
    }
    if (checkOutFrom != null) {
      queryParams['check_out_date_from'] = checkOutFrom.toIso8601String().split(
        'T',
      )[0];
    }
    if (checkOutTo != null) {
      queryParams['check_out_date_to'] = checkOutTo.toIso8601String().split(
        'T',
      )[0];
    }
    if (ordering != null && ordering.isNotEmpty) {
      queryParams['ordering'] = ordering;
    }

    try {
      final response = await _apiClient.get<dynamic>(
        AppConstants.bookingsEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Ensure response.data exists
      if (response.data == null) {
        return [];
      }

      List<Booking> bookings;

      // Handle both paginated and non-paginated responses
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        if (dataMap.containsKey('results')) {
          final listResponse = BookingListResponse.fromJson(dataMap);
          bookings = listResponse.results;
        } else {
          bookings = [];
        }
      } else if (response.data is List) {
        final list = response.data as List<dynamic>;
        bookings = list
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        bookings = [];
      }

      // Cache results on success (only for unfiltered default queries)
      if (queryParams.isEmpty ||
          (queryParams.length == 1 && queryParams.containsKey('ordering'))) {
        await _cacheBookingList(bookings);
      }
      await _cacheBookingsIndividually(bookings);

      return bookings;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        return _getCachedBookingList();
      }
      rethrow;
    }
  }

  /// Get a single booking by ID
  Future<Booking> getBooking(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConstants.bookingsEndpoint}$id/',
      );
      if (response.data == null) {
        throw Exception('Booking not found');
      }
      final booking = Booking.fromJson(response.data!);
      await _cacheBooking(booking);
      return booking;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        return _getCachedBooking(id);
      }
      rethrow;
    }
  }

  /// Create a new booking
  Future<Booking> createBooking(BookingCreate booking) async {
    final data = booking.toJson();
    // Backend expects YYYY-MM-DD for DateField, not ISO 8601 with time
    data['check_in_date'] = booking.checkInDate.toIso8601String().split('T')[0];
    data['check_out_date'] = booking.checkOutDate.toIso8601String().split(
      'T',
    )[0];
    // Backend requires total_amount
    data['total_amount'] = booking.totalAmount;
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.bookingsEndpoint,
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to create booking');
    }
    return Booking.fromJson(response.data!);
  }

  /// Update an existing booking
  Future<Booking> updateBooking(int id, BookingUpdate booking) async {
    final data = booking.toJson();
    // Backend expects YYYY-MM-DD for DateField, not ISO 8601 with time
    if (booking.checkInDate != null) {
      data['check_in_date'] = booking.checkInDate!.toIso8601String().split(
        'T',
      )[0];
    }
    if (booking.checkOutDate != null) {
      data['check_out_date'] = booking.checkOutDate!.toIso8601String().split(
        'T',
      )[0];
    }
    // Recalculate total_amount if nightly_rate and dates are present
    if (booking.nightlyRate != null &&
        booking.checkInDate != null &&
        booking.checkOutDate != null) {
      final nights = booking.checkOutDate!
          .difference(booking.checkInDate!)
          .inDays;
      data['total_amount'] = booking.nightlyRate! * nights;
    }
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${AppConstants.bookingsEndpoint}$id/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to update booking');
    }
    return Booking.fromJson(response.data!);
  }

  /// Partial update of a booking
  Future<Booking> patchBooking(int id, Map<String, dynamic> updates) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.bookingsEndpoint}$id/',
      data: updates,
    );
    if (response.data == null) {
      throw Exception('Failed to patch booking');
    }
    return Booking.fromJson(response.data!);
  }

  /// Delete a booking
  Future<void> deleteBooking(int id) async {
    await _apiClient.delete('${AppConstants.bookingsEndpoint}$id/');
  }

  // ==================== Booking Status ====================

  /// Update booking status
  Future<Booking> updateBookingStatus(
    int id,
    BookingStatus status, {
    String? notes,
  }) async {
    final data = {
      'status': status.toApiValue,
      if (notes != null) 'notes': notes,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.bookingsEndpoint}$id/update-status/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to update booking status');
    }
    return Booking.fromJson(response.data!);
  }

  // ==================== Check-in/Check-out ====================

  /// Check-in a booking
  Future<Booking> checkIn(int id, {String? actualCheckInNotes}) async {
    final data = <String, dynamic>{};
    if (actualCheckInNotes != null) {
      data['actual_check_in_notes'] = actualCheckInNotes;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.bookingsEndpoint}$id/check-in/',
      data: data.isNotEmpty ? data : null,
    );
    if (response.data == null) {
      throw Exception('Failed to check in');
    }
    return Booking.fromJson(response.data!);
  }

  /// Check-out a booking
  Future<Booking> checkOut(
    int id, {
    String? actualCheckOutNotes,
    double? finalAmount,
  }) async {
    final data = <String, dynamic>{};
    if (actualCheckOutNotes != null) {
      data['actual_check_out_notes'] = actualCheckOutNotes;
    }
    if (finalAmount != null) {
      data['final_amount'] = finalAmount;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.bookingsEndpoint}$id/check-out/',
      data: data.isNotEmpty ? data : null,
    );
    if (response.data == null) {
      throw Exception('Failed to check out');
    }
    return Booking.fromJson(response.data!);
  }

  // ==================== Early/Late Fees ====================

  /// Record early check-in fee
  Future<Booking> recordEarlyCheckIn(
    int id, {
    required double hours,
    required int fee,
    String? notes,
    bool createFolioItem = true,
  }) async {
    final data = <String, dynamic>{
      'hours': hours,
      'fee': fee,
      'create_folio_item': createFolioItem,
    };
    if (notes != null && notes.isNotEmpty) {
      data['notes'] = notes;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.bookingsEndpoint}$id/record-early-checkin/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to record early check-in fee');
    }
    return Booking.fromJson(response.data!);
  }

  /// Record late check-out fee
  Future<Booking> recordLateCheckOut(
    int id, {
    required double hours,
    required int fee,
    String? notes,
    bool createFolioItem = true,
  }) async {
    final data = <String, dynamic>{
      'hours': hours,
      'fee': fee,
      'create_folio_item': createFolioItem,
    };
    if (notes != null && notes.isNotEmpty) {
      data['notes'] = notes;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.bookingsEndpoint}$id/record-late-checkout/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to record late check-out fee');
    }
    return Booking.fromJson(response.data!);
  }

  // ==================== Calendar & Today ====================

  /// Get bookings for calendar view
  Future<List<Booking>> getCalendarBookings({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final queryParams = {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    };

    final response = await _apiClient.get<List<dynamic>>(
      '${AppConstants.bookingsEndpoint}calendar/',
      queryParameters: queryParams,
    );

    if (response.data == null) {
      return [];
    }

    return response.data!
        .map((json) => Booking.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get today's bookings (check-ins and check-outs)
  Future<TodayBookingsResponse> getTodayBookings() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.bookingsEndpoint}today/',
    );
    if (response.data == null) {
      throw Exception('Failed to get today bookings');
    }
    return TodayBookingsResponse.fromJson(response.data!);
  }

  // ==================== Convenience Methods ====================

  /// Get all active bookings (confirmed or checked-in)
  Future<List<Booking>> getActiveBookings() async {
    return getBookings(ordering: '-check_in_date').then(
      (bookings) => bookings
          .where(
            (b) =>
                b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.checkedIn,
          )
          .toList(),
    );
  }

  /// Get upcoming check-ins
  Future<List<Booking>> getUpcomingCheckIns({int days = 7}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    return getBookings(
      status: 'confirmed',
      checkInFrom: now,
      checkInTo: future,
      ordering: 'check_in_date',
    );
  }

  /// Get upcoming check-outs
  Future<List<Booking>> getUpcomingCheckOuts({int days = 7}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    return getBookings(
      status: 'checked_in',
      checkOutFrom: now,
      checkOutTo: future,
      ordering: 'check_out_date',
    );
  }

  /// Get bookings by room for a date range
  Future<List<Booking>> getBookingsByRoom(
    int roomId, {
    DateTime? from,
    DateTime? to,
  }) async {
    return getBookings(
      roomId: roomId,
      checkInFrom: from,
      checkOutTo: to,
      ordering: '-check_in_date',
    );
  }

  /// Get bookings by guest
  Future<List<Booking>> getBookingsByGuest(
    int guestId, {
    String? ordering,
  }) async {
    return getBookings(
      guestId: guestId,
      ordering: ordering ?? '-check_in_date',
    );
  }

  /// Cancel a booking
  Future<Booking> cancelBooking(int id, {String? cancellationReason}) async {
    return updateBookingStatus(
      id,
      BookingStatus.cancelled,
      notes: cancellationReason,
    );
  }

  /// Mark as no-show
  Future<Booking> markAsNoShow(int id, {String? notes}) async {
    return updateBookingStatus(id, BookingStatus.noShow, notes: notes);
  }

  // ==================== Cache Helpers ====================

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }

  Future<void> _cacheBooking(Booking booking) async {
    final box = await HiveStorage.bookingsBox;
    await box.put('booking_${booking.id}', booking.toJson());
  }

  Future<void> _cacheBookingsIndividually(List<Booking> bookings) async {
    final box = await HiveStorage.bookingsBox;
    for (final booking in bookings) {
      await box.put('booking_${booking.id}', booking.toJson());
    }
  }

  Future<void> _cacheBookingList(List<Booking> bookings) async {
    final box = await HiveStorage.bookingsBox;
    final ids = bookings.map((b) => b.id).toList();
    await box.put('_list_default', ids);
  }

  Future<List<Booking>> _getCachedBookingList() async {
    final box = await HiveStorage.bookingsBox;
    final ids = box.get('_list_default');
    if (ids == null || ids is! List) return [];

    final bookings = <Booking>[];
    for (final id in ids) {
      final json = box.get('booking_$id');
      if (json != null && json is Map) {
        try {
          bookings.add(Booking.fromJson(Map<String, dynamic>.from(json)));
        } catch (_) {
          // Skip corrupted cache entries
        }
      }
    }
    return bookings;
  }

  Future<Booking> _getCachedBooking(int id) async {
    final box = await HiveStorage.bookingsBox;
    final json = box.get('booking_$id');
    if (json != null && json is Map) {
      return Booking.fromJson(Map<String, dynamic>.from(json));
    }
    throw Exception('Booking not found in cache');
  }
}
