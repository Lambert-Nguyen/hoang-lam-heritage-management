import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/group_booking.dart';
import '../repositories/group_booking_repository.dart';

part 'group_booking_provider.freezed.dart';

/// Provider for GroupBookingRepository
final groupBookingRepositoryProvider = Provider<GroupBookingRepository>((ref) {
  return GroupBookingRepository();
});

// ============================================================
// Group Booking Providers
// ============================================================

/// Provider for all group bookings
final groupBookingsProvider = FutureProvider<List<GroupBooking>>((ref) async {
  final repository = ref.watch(groupBookingRepositoryProvider);
  return repository.getGroupBookings();
});

/// Provider for upcoming group bookings (next 7 days)
final upcomingGroupBookingsProvider = FutureProvider<List<GroupBooking>>((
  ref,
) async {
  final repository = ref.watch(groupBookingRepositoryProvider);
  return repository.getUpcomingGroupBookings();
});

/// Provider for today's check-ins
final todayGroupCheckInsProvider = FutureProvider<List<GroupBooking>>((
  ref,
) async {
  final repository = ref.watch(groupBookingRepositoryProvider);
  return repository.getTodayCheckIns();
});

/// Provider for today's check-outs
final todayGroupCheckOutsProvider = FutureProvider<List<GroupBooking>>((
  ref,
) async {
  final repository = ref.watch(groupBookingRepositoryProvider);
  return repository.getTodayCheckOuts();
});

/// Provider for active group bookings (confirmed or checked-in)
final activeGroupBookingsProvider = FutureProvider<List<GroupBooking>>((
  ref,
) async {
  final repository = ref.watch(groupBookingRepositoryProvider);
  final allBookings = await repository.getGroupBookings();
  return allBookings
      .where(
        (b) =>
            b.status == GroupBookingStatus.confirmed ||
            b.status == GroupBookingStatus.checkedIn,
      )
      .toList();
});

/// Provider for a specific group booking by ID
final groupBookingByIdProvider = FutureProvider.family<GroupBooking, int>((
  ref,
  id,
) async {
  final repository = ref.watch(groupBookingRepositoryProvider);
  return repository.getGroupBooking(id);
});

/// Provider for filtered group bookings
final filteredGroupBookingsProvider =
    FutureProvider.family<List<GroupBooking>, GroupBookingFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(groupBookingRepositoryProvider);
      return repository.getGroupBookings(
        status: filter.status,
        checkInFrom: filter.checkInFrom,
        checkInTo: filter.checkInTo,
        checkOutFrom: filter.checkOutFrom,
        checkOutTo: filter.checkOutTo,
        search: filter.search,
        roomId: filter.roomId,
      );
    });

/// Filter model for group bookings
@freezed
sealed class GroupBookingFilter with _$GroupBookingFilter {
  const factory GroupBookingFilter({
    GroupBookingStatus? status,
    DateTime? checkInFrom,
    DateTime? checkInTo,
    DateTime? checkOutFrom,
    DateTime? checkOutTo,
    String? search,
    int? roomId,
  }) = _GroupBookingFilter;
}

// ============================================================
// State Management for Operations
// ============================================================

/// State for group booking operations
@freezed
sealed class GroupBookingState with _$GroupBookingState {
  const factory GroupBookingState({
    @Default(false) bool isLoading,
    String? errorMessage,
    GroupBooking? selectedBooking,
    @Default([]) List<GroupBooking> bookings,
  }) = _GroupBookingState;
}

/// StateNotifier for managing group booking operations
class GroupBookingNotifier extends StateNotifier<GroupBookingState> {
  final GroupBookingRepository _repository;
  final Ref _ref;

  GroupBookingNotifier(this._repository, this._ref)
    : super(const GroupBookingState());

  /// Load all group bookings
  Future<void> loadBookings({
    GroupBookingStatus? status,
    String? search,
    DateTime? checkInFrom,
    DateTime? checkInTo,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final bookings = await _repository.getGroupBookings(
        status: status,
        search: search,
        checkInFrom: checkInFrom,
        checkInTo: checkInTo,
      );
      state = state.copyWith(isLoading: false, bookings: bookings);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Create a new group booking
  Future<GroupBooking?> createBooking(GroupBookingCreate booking) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newBooking = await _repository.createGroupBooking(booking);
      await loadBookings();
      _ref.invalidate(groupBookingsProvider);
      _ref.invalidate(upcomingGroupBookingsProvider);
      return newBooking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Update a group booking
  Future<GroupBooking?> updateBooking(int id, GroupBookingUpdate update) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedBooking = await _repository.updateGroupBooking(id, update);
      await loadBookings();
      _ref.invalidate(groupBookingByIdProvider(id));
      _ref.invalidate(groupBookingsProvider);
      return updatedBooking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Confirm a group booking
  Future<GroupBooking?> confirmBooking(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final confirmedBooking = await _repository.confirmGroupBooking(id);
      await loadBookings();
      _ref.invalidate(groupBookingByIdProvider(id));
      _ref.invalidate(groupBookingsProvider);
      _ref.invalidate(upcomingGroupBookingsProvider);
      return confirmedBooking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Check in a group booking
  Future<GroupBooking?> checkInBooking(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final checkedInBooking = await _repository.checkInGroupBooking(id);
      await loadBookings();
      _ref.invalidate(groupBookingByIdProvider(id));
      _ref.invalidate(groupBookingsProvider);
      _ref.invalidate(todayGroupCheckInsProvider);
      _ref.invalidate(activeGroupBookingsProvider);
      return checkedInBooking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Check out a group booking
  Future<GroupBooking?> checkOutBooking(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final checkedOutBooking = await _repository.checkOutGroupBooking(id);
      await loadBookings();
      _ref.invalidate(groupBookingByIdProvider(id));
      _ref.invalidate(groupBookingsProvider);
      _ref.invalidate(todayGroupCheckOutsProvider);
      _ref.invalidate(activeGroupBookingsProvider);
      return checkedOutBooking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Cancel a group booking
  Future<GroupBooking?> cancelBooking(int id, {String? reason}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cancelledBooking = await _repository.cancelGroupBooking(
        id,
        reason: reason,
      );
      await loadBookings();
      _ref.invalidate(groupBookingByIdProvider(id));
      _ref.invalidate(groupBookingsProvider);
      _ref.invalidate(upcomingGroupBookingsProvider);
      _ref.invalidate(activeGroupBookingsProvider);
      return cancelledBooking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Assign rooms to a group booking
  Future<GroupBooking?> assignRooms(int id, List<int> roomIds) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedBooking = await _repository.assignRooms(id, roomIds);
      await loadBookings();
      _ref.invalidate(groupBookingByIdProvider(id));
      _ref.invalidate(groupBookingsProvider);
      return updatedBooking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Delete a group booking
  Future<bool> deleteBooking(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteGroupBooking(id);
      await loadBookings();
      _ref.invalidate(groupBookingsProvider);
      _ref.invalidate(upcomingGroupBookingsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Select a booking
  void selectBooking(GroupBooking? booking) {
    state = state.copyWith(selectedBooking: booking);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for GroupBookingNotifier
final groupBookingNotifierProvider =
    StateNotifierProvider<GroupBookingNotifier, GroupBookingState>((ref) {
      final repository = ref.watch(groupBookingRepositoryProvider);
      return GroupBookingNotifier(repository, ref);
    });
