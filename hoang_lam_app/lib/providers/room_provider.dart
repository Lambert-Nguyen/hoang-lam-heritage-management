import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/room.dart';
import '../repositories/room_repository.dart';
import 'settings_provider.dart';

part 'room_provider.freezed.dart';

/// Provider for RoomRepository
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

/// Provider for all room types
final roomTypesProvider = FutureProvider<List<RoomType>>((ref) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomTypes(isActive: true);
});

/// Provider for active rooms (default for most screens)
final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRooms(isActive: true);
});

/// Provider for all rooms including inactive (for room management screen)
final allRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRooms();
});

/// Provider for rooms grouped by floor (for dashboard display)
final roomsByFloorProvider = FutureProvider<Map<int, List<Room>>>((ref) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomsGroupedByFloor();
});

/// Provider for room status counts (for dashboard stats)
final roomStatusCountsProvider = FutureProvider<Map<RoomStatus, int>>((
  ref,
) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomStatusCounts();
});

/// Provider for a specific room by ID
final roomByIdProvider = FutureProvider.family<Room, int>((ref, id) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoom(id);
});

/// Provider for a specific room type by ID
final roomTypeByIdProvider = FutureProvider.family<RoomType, int>((
  ref,
  id,
) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomType(id);
});

/// Provider for filtered rooms
final filteredRoomsProvider = FutureProvider.family<List<Room>, RoomFilter>((
  ref,
  filter,
) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRooms(
    status: filter.status,
    roomTypeId: filter.roomTypeId,
    floor: filter.floor,
    isActive: filter.isActive,
    search: filter.search,
  );
});

/// Provider for available rooms in a date range
final availableRoomsProvider =
    FutureProvider.family<List<Room>, AvailabilityFilter>((ref, filter) async {
      final repository = ref.watch(roomRepositoryProvider);
      return repository.getAvailableRooms(
        checkIn: filter.checkIn,
        checkOut: filter.checkOut,
        roomTypeId: filter.roomTypeId,
      );
    });

/// Room filter for querying rooms
@freezed
sealed class RoomFilter with _$RoomFilter {
  const factory RoomFilter({
    RoomStatus? status,
    int? roomTypeId,
    int? floor,
    bool? isActive,
    String? search,
  }) = _RoomFilter;
}

/// Availability filter for checking room availability
@freezed
sealed class AvailabilityFilter with _$AvailabilityFilter {
  const factory AvailabilityFilter({
    required DateTime checkIn,
    required DateTime checkOut,
    int? roomTypeId,
  }) = _AvailabilityFilter;
}

/// State for room management operations
@freezed
sealed class RoomState with _$RoomState {
  const factory RoomState.initial() = _Initial;
  const factory RoomState.loading() = _Loading;
  const factory RoomState.loaded({required List<Room> rooms}) = _Loaded;
  const factory RoomState.error({required String message}) = _Error;
}

/// State notifier for room management
class RoomNotifier extends StateNotifier<RoomState> {
  final RoomRepository _repository;
  final Ref _ref;

  RoomNotifier(this._repository, this._ref) : super(const RoomState.initial());

  /// Load all rooms
  Future<void> loadRooms({
    RoomStatus? status,
    int? roomTypeId,
    int? floor,
  }) async {
    state = const RoomState.loading();

    try {
      final rooms = await _repository.getRooms(
        status: status,
        roomTypeId: roomTypeId,
        floor: floor,
        isActive: true,
      );
      state = RoomState.loaded(rooms: rooms);
    } catch (e) {
      state = RoomState.error(message: _getErrorMessage(e));
    }
  }

  /// Update room status
  Future<bool> updateRoomStatus(
    int roomId,
    RoomStatus newStatus, {
    String? notes,
  }) async {
    try {
      await _repository.updateRoomStatus(
        roomId,
        RoomStatusUpdateRequest(status: newStatus, notes: notes),
      );

      // Refresh the room providers
      _ref.invalidate(roomsProvider);
      _ref.invalidate(allRoomsProvider);
      _ref.invalidate(roomsByFloorProvider);
      _ref.invalidate(roomStatusCountsProvider);
      _ref.invalidate(roomByIdProvider(roomId));

      return true;
    } catch (e) {
      state = RoomState.error(message: _getErrorMessage(e));
      return false;
    }
  }

  /// Create a new room
  Future<Room?> createRoom(Room room) async {
    try {
      final createdRoom = await _repository.createRoom(room);

      // Refresh providers
      _ref.invalidate(roomsProvider);
      _ref.invalidate(allRoomsProvider);
      _ref.invalidate(roomsByFloorProvider);
      _ref.invalidate(roomStatusCountsProvider);

      return createdRoom;
    } catch (e) {
      state = RoomState.error(message: _getErrorMessage(e));
      return null;
    }
  }

  /// Update an existing room
  Future<Room?> updateRoom(Room room) async {
    try {
      final updatedRoom = await _repository.updateRoom(room);

      // Refresh providers
      _ref.invalidate(roomsProvider);
      _ref.invalidate(allRoomsProvider);
      _ref.invalidate(roomsByFloorProvider);
      _ref.invalidate(roomByIdProvider(room.id));

      return updatedRoom;
    } catch (e) {
      state = RoomState.error(message: _getErrorMessage(e));
      return null;
    }
  }

  /// Delete a room
  Future<bool> deleteRoom(int roomId) async {
    try {
      await _repository.deleteRoom(roomId);

      // Refresh providers
      _ref.invalidate(roomsProvider);
      _ref.invalidate(allRoomsProvider);
      _ref.invalidate(roomsByFloorProvider);
      _ref.invalidate(roomStatusCountsProvider);

      return true;
    } catch (e) {
      state = RoomState.error(message: _getErrorMessage(e));
      return false;
    }
  }

  /// Get error message from exception
  String _getErrorMessage(dynamic error) {
    final l10n = _ref.read(l10nProvider);
    final message = error.toString().toLowerCase();
    if (message.contains('network') || message.contains('connection')) {
      return l10n.errorNoNetwork;
    }
    if (message.contains('đã tồn tại') || message.contains('duplicate')) {
      return l10n.errorRoomExists;
    }
    if (message.contains('không thể xóa') ||
        message.contains('cannot delete')) {
      return l10n.errorCannotDeleteRoom;
    }
    return l10n.errorGeneric;
  }
}

/// Provider for room state notifier
final roomStateProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  return RoomNotifier(repository, ref);
});

/// Provider for selected room (for detail view)
final selectedRoomProvider = StateProvider<Room?>((ref) => null);

/// Provider for selected room type filter
final selectedRoomTypeFilterProvider = StateProvider<RoomType?>((ref) => null);

/// Provider for selected status filter
final selectedStatusFilterProvider = StateProvider<RoomStatus?>((ref) => null);

/// Provider for selected floor filter
final selectedFloorFilterProvider = StateProvider<int?>((ref) => null);
