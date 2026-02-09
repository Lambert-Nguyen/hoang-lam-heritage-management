import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/booking.dart';
import '../repositories/booking_repository.dart';

part 'booking_provider.freezed.dart';

/// Provider for BookingRepository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// Provider for all bookings
final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookings(ordering: '-check_in_date');
});

/// Provider for active bookings (confirmed or checked-in)
final activeBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getActiveBookings();
});

/// Provider for today's bookings
final todayBookingsProvider = FutureProvider<TodayBookingsResponse>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getTodayBookings();
});

/// Provider for upcoming check-ins
final upcomingCheckInsProvider = FutureProvider.family<List<Booking>, int>((ref, days) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getUpcomingCheckIns(days: days);
});

/// Provider for upcoming check-outs
final upcomingCheckOutsProvider = FutureProvider.family<List<Booking>, int>((ref, days) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getUpcomingCheckOuts(days: days);
});

/// Provider for a specific booking by ID
final bookingByIdProvider = FutureProvider.family<Booking, int>((ref, id) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBooking(id);
});

/// Provider for bookings by room
final bookingsByRoomProvider =
    FutureProvider.family<List<Booking>, BookingsByRoomParams>((ref, params) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByRoom(
    params.roomId,
    from: params.from,
    to: params.to,
  );
});

/// Provider for bookings by guest
final bookingsByGuestProvider =
    FutureProvider.family<List<Booking>, int>((ref, guestId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByGuest(guestId);
});

/// Provider for calendar bookings
final calendarBookingsProvider =
    FutureProvider.family<List<Booking>, DateRange>((ref, dateRange) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getCalendarBookings(
    startDate: dateRange.start,
    endDate: dateRange.end,
  );
});

/// Provider for filtered bookings
final filteredBookingsProvider =
    FutureProvider.family<List<Booking>, BookingFilter>((ref, filter) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookings(
    status: filter.status?.toApiValue,
    roomId: filter.roomId,
    guestId: filter.guestId,
    source: filter.source?.toApiValue,
    checkInFrom: filter.startDate,
    checkInTo: filter.endDate,
    ordering: filter.ordering,
  );
});

/// Parameters for getting bookings by room
@freezed
sealed class BookingsByRoomParams with _$BookingsByRoomParams {
  const factory BookingsByRoomParams({
    required int roomId,
    DateTime? from,
    DateTime? to,
  }) = _BookingsByRoomParams;
}

/// State notifier for booking management operations
class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final BookingRepository _repository;
  BookingFilter? _currentFilter;

  BookingNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  /// Load bookings with current filter
  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    try {
      final bookings = await _repository.getBookings(
        status: _currentFilter?.status?.toApiValue,
        roomId: _currentFilter?.roomId,
        guestId: _currentFilter?.guestId,
        source: _currentFilter?.source?.toApiValue,
        checkInFrom: _currentFilter?.startDate,
        checkInTo: _currentFilter?.endDate,
        ordering: _currentFilter?.ordering ?? '-check_in_date',
      );
      state = AsyncValue.data(bookings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Apply filter
  Future<void> applyFilter(BookingFilter filter) async {
    _currentFilter = filter;
    await loadBookings();
  }

  /// Clear filter
  Future<void> clearFilter() async {
    _currentFilter = null;
    await loadBookings();
  }

  /// Create a new booking
  Future<Booking> createBooking(BookingCreate booking) async {
    try {
      final newBooking = await _repository.createBooking(booking);
      // Reload bookings after creation
      await loadBookings();
      return newBooking;
    } catch (error) {
      rethrow;
    }
  }

  /// Update an existing booking
  Future<Booking> updateBooking(int id, BookingUpdate booking) async {
    try {
      final updatedBooking = await _repository.updateBooking(id, booking);
      // Reload bookings after update
      await loadBookings();
      return updatedBooking;
    } catch (error) {
      rethrow;
    }
  }

  /// Update booking status
  Future<Booking> updateBookingStatus(
    int id,
    BookingStatus status, {
    String? notes,
  }) async {
    try {
      final updatedBooking = await _repository.updateBookingStatus(
        id,
        status,
        notes: notes,
      );
      // Reload bookings after status update
      await loadBookings();
      return updatedBooking;
    } catch (error) {
      rethrow;
    }
  }

  /// Check-in a booking
  Future<Booking> checkIn(int id, {String? notes}) async {
    try {
      final booking = await _repository.checkIn(id, actualCheckInNotes: notes);
      // Reload bookings after check-in
      await loadBookings();
      return booking;
    } catch (error) {
      rethrow;
    }
  }

  /// Check-out a booking
  Future<Booking> checkOut(int id, {String? notes, double? finalAmount}) async {
    try {
      final booking = await _repository.checkOut(
        id,
        actualCheckOutNotes: notes,
        finalAmount: finalAmount,
      );
      // Reload bookings after check-out
      await loadBookings();
      return booking;
    } catch (error) {
      rethrow;
    }
  }

  /// Record early check-in fee
  Future<Booking> recordEarlyCheckIn(
    int id, {
    required double hours,
    required int fee,
    String? notes,
    bool createFolioItem = true,
  }) async {
    try {
      final booking = await _repository.recordEarlyCheckIn(
        id,
        hours: hours,
        fee: fee,
        notes: notes,
        createFolioItem: createFolioItem,
      );
      await loadBookings();
      return booking;
    } catch (error) {
      rethrow;
    }
  }

  /// Record late check-out fee
  Future<Booking> recordLateCheckOut(
    int id, {
    required double hours,
    required int fee,
    String? notes,
    bool createFolioItem = true,
  }) async {
    try {
      final booking = await _repository.recordLateCheckOut(
        id,
        hours: hours,
        fee: fee,
        notes: notes,
        createFolioItem: createFolioItem,
      );
      await loadBookings();
      return booking;
    } catch (error) {
      rethrow;
    }
  }

  /// Cancel a booking
  Future<Booking> cancelBooking(int id, {String? reason}) async {
    try {
      final booking = await _repository.cancelBooking(
        id,
        cancellationReason: reason,
      );
      // Reload bookings after cancellation
      await loadBookings();
      return booking;
    } catch (error) {
      rethrow;
    }
  }

  /// Mark as no-show
  Future<Booking> markAsNoShow(int id, {String? notes}) async {
    try {
      final booking = await _repository.markAsNoShow(id, notes: notes);
      // Reload bookings after update
      await loadBookings();
      return booking;
    } catch (error) {
      rethrow;
    }
  }

  /// Delete a booking
  Future<void> deleteBooking(int id) async {
    try {
      await _repository.deleteBooking(id);
      // Reload bookings after deletion
      await loadBookings();
    } catch (error) {
      rethrow;
    }
  }

  /// Refresh bookings
  Future<void> refresh() => loadBookings();
}

/// Provider for BookingNotifier
final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repository);
});

/// Provider for getting booking statistics
final bookingStatsProvider = Provider<BookingStats>((ref) {
  final bookingsAsync = ref.watch(bookingNotifierProvider);

  return bookingsAsync.when(
    data: (bookings) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return BookingStats(
        totalBookings: bookings.length,
        activeBookings: bookings
            .where((b) =>
                b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.checkedIn)
            .length,
        todayCheckIns: bookings
            .where((b) {
              final checkInDate = DateTime(
                b.checkInDate.year,
                b.checkInDate.month,
                b.checkInDate.day,
              );
              return checkInDate.isAtSameMomentAs(today) &&
                  (b.status == BookingStatus.confirmed ||
                      b.status == BookingStatus.pending);
            })
            .length,
        todayCheckOuts: bookings
            .where((b) {
              final checkOutDate = DateTime(
                b.checkOutDate.year,
                b.checkOutDate.month,
                b.checkOutDate.day,
              );
              return checkOutDate.isAtSameMomentAs(today) &&
                  b.status == BookingStatus.checkedIn;
            })
            .length,
        pendingBookings: bookings
            .where((b) => b.status == BookingStatus.pending)
            .length,
        cancelledBookings: bookings
            .where((b) => b.status == BookingStatus.cancelled)
            .length,
      );
    },
    loading: () => const BookingStats(
      totalBookings: 0,
      activeBookings: 0,
      todayCheckIns: 0,
      todayCheckOuts: 0,
      pendingBookings: 0,
      cancelledBookings: 0,
    ),
    error: (_, __) => const BookingStats(
      totalBookings: 0,
      activeBookings: 0,
      todayCheckIns: 0,
      todayCheckOuts: 0,
      pendingBookings: 0,
      cancelledBookings: 0,
    ),
  );
});

/// Booking statistics model
@freezed
sealed class BookingStats with _$BookingStats {
  const factory BookingStats({
    required int totalBookings,
    required int activeBookings,
    required int todayCheckIns,
    required int todayCheckOuts,
    required int pendingBookings,
    required int cancelledBookings,
  }) = _BookingStats;
}
