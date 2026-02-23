import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/services/sync_manager.dart';
import '../models/guest.dart';
import '../models/offline_operation.dart';
import '../repositories/guest_repository.dart';
import 'settings_provider.dart';

part 'guest_provider.freezed.dart';

/// Provider for GuestRepository
final guestRepositoryProvider = Provider<GuestRepository>((ref) {
  return GuestRepository();
});

/// Provider for all guests
final guestsProvider = FutureProvider<List<Guest>>((ref) async {
  final repository = ref.watch(guestRepositoryProvider);
  return repository.getGuests(ordering: '-created_at');
});

/// Provider for VIP guests
final vipGuestsProvider = FutureProvider<List<Guest>>((ref) async {
  final repository = ref.watch(guestRepositoryProvider);
  return repository.getVipGuests();
});

/// Provider for returning guests
final returningGuestsProvider = FutureProvider<List<Guest>>((ref) async {
  final repository = ref.watch(guestRepositoryProvider);
  return repository.getReturningGuests();
});

/// Provider for recent guests
final recentGuestsProvider = FutureProvider<List<Guest>>((ref) async {
  final repository = ref.watch(guestRepositoryProvider);
  return repository.getRecentGuests(limit: 10);
});

/// Provider for a specific guest by ID
final guestByIdProvider = FutureProvider.family<Guest, int>((ref, id) async {
  final repository = ref.watch(guestRepositoryProvider);
  return repository.getGuest(id);
});

/// Provider for guest history by ID
final guestHistoryProvider = FutureProvider.family<GuestHistoryResponse, int>((
  ref,
  guestId,
) async {
  final repository = ref.watch(guestRepositoryProvider);
  return repository.getGuestHistory(guestId);
});

/// Provider for filtered guests
final filteredGuestsProvider = FutureProvider.family<List<Guest>, GuestFilter>((
  ref,
  filter,
) async {
  final repository = ref.watch(guestRepositoryProvider);
  return repository.getGuests(
    search: filter.search,
    isVip: filter.isVip,
    nationality: filter.nationality,
    ordering: filter.ordering,
  );
});

/// Provider for guest search
final guestSearchProvider =
    FutureProvider.family<List<Guest>, GuestSearchParams>((ref, params) async {
      final repository = ref.watch(guestRepositoryProvider);
      return repository.searchGuests(
        query: params.query,
        searchBy: params.searchBy,
      );
    });

/// Provider for guests by nationality
final guestsByNationalityProvider = FutureProvider.family<List<Guest>, String>((
  ref,
  nationality,
) async {
  final repository = ref.watch(guestRepositoryProvider);
  return repository.getGuestsByNationality(nationality);
});

/// Guest filter for querying guests
@freezed
sealed class GuestFilter with _$GuestFilter {
  const factory GuestFilter({
    String? search,
    bool? isVip,
    String? nationality,
    @Default('-created_at') String? ordering,
  }) = _GuestFilter;
}

/// Guest search parameters
@freezed
sealed class GuestSearchParams with _$GuestSearchParams {
  const factory GuestSearchParams({
    required String query,
    @Default('all') String searchBy,
  }) = _GuestSearchParams;
}

/// State for guest management operations
@freezed
sealed class GuestState with _$GuestState {
  const factory GuestState.initial() = _Initial;
  const factory GuestState.loading() = _Loading;
  const factory GuestState.loaded({required List<Guest> guests}) = _Loaded;
  const factory GuestState.success({required Guest guest, String? message}) =
      _Success;
  const factory GuestState.error({required String message}) = _Error;
}

/// State notifier for guest management
class GuestNotifier extends StateNotifier<GuestState> {
  final GuestRepository _repository;
  final Ref _ref;

  GuestNotifier(this._repository, this._ref)
    : super(const GuestState.initial());

  bool _isNetworkError(Object e) {
    return e is DioException &&
        (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown);
  }

  /// Load all guests
  Future<void> loadGuests({
    String? search,
    bool? isVip,
    String? nationality,
  }) async {
    state = const GuestState.loading();

    try {
      final guests = await _repository.getGuests(
        search: search,
        isVip: isVip,
        nationality: nationality,
        ordering: '-created_at',
      );
      state = GuestState.loaded(guests: guests);
    } catch (e) {
      state = GuestState.error(message: _getErrorMessage(e));
    }
  }

  /// Search guests
  Future<void> searchGuests(String query, {String searchBy = 'all'}) async {
    if (query.trim().length < 2) {
      state = GuestState.error(message: _ref.read(l10nProvider).searchMinChars);
      return;
    }

    state = const GuestState.loading();

    try {
      final guests = await _repository.searchGuests(
        query: query,
        searchBy: searchBy,
      );
      state = GuestState.loaded(guests: guests);
    } catch (e) {
      state = GuestState.error(message: _getErrorMessage(e));
    }
  }

  /// Create a new guest
  Future<Guest?> createGuest(Guest guest) async {
    state = const GuestState.loading();

    try {
      final createdGuest = await _repository.createGuest(guest);

      _invalidateGuestProviders();

      state = GuestState.success(
        guest: createdGuest,
        message: _ref.read(l10nProvider).guestAddedSuccess,
      );

      return createdGuest;
    } catch (e) {
      if (_isNetworkError(e)) {
        final syncManager = _ref.read(syncManagerProvider);
        await syncManager.queueOperation(
          entityType: EntityType.guest,
          operationType: OperationType.create,
          payload: guest.toJson(),
        );
        state = GuestState.success(
          guest: guest,
          message: _ref.read(l10nProvider).offlineOperationQueued,
        );
        return null;
      }
      state = GuestState.error(message: _getErrorMessage(e));
      return null;
    }
  }

  /// Update an existing guest
  Future<Guest?> updateGuest(Guest guest) async {
    state = const GuestState.loading();

    try {
      final updatedGuest = await _repository.updateGuest(guest);

      _invalidateGuestProviders();
      _ref.invalidate(guestByIdProvider(guest.id));
      _ref.invalidate(guestHistoryProvider(guest.id));

      state = GuestState.success(
        guest: updatedGuest,
        message: _ref.read(l10nProvider).guestUpdatedSuccess,
      );

      return updatedGuest;
    } catch (e) {
      if (_isNetworkError(e)) {
        final syncManager = _ref.read(syncManagerProvider);
        await syncManager.queueOperation(
          entityType: EntityType.guest,
          entityId: guest.id.toString(),
          operationType: OperationType.update,
          payload: guest.toJson(),
        );
        state = GuestState.success(
          guest: guest,
          message: _ref.read(l10nProvider).offlineOperationQueued,
        );
        return null;
      }
      state = GuestState.error(message: _getErrorMessage(e));
      return null;
    }
  }

  /// Delete a guest
  Future<bool> deleteGuest(int guestId) async {
    state = const GuestState.loading();

    try {
      await _repository.deleteGuest(guestId);

      _invalidateGuestProviders();

      state = const GuestState.initial();

      return true;
    } catch (e) {
      if (_isNetworkError(e)) {
        final syncManager = _ref.read(syncManagerProvider);
        await syncManager.queueOperation(
          entityType: EntityType.guest,
          entityId: guestId.toString(),
          operationType: OperationType.delete,
          payload: {},
        );
        state = GuestState.success(
          guest: const Guest(id: 0, fullName: '', phone: ''),
          message: _ref.read(l10nProvider).offlineOperationQueued,
        );
        return true;
      }
      state = GuestState.error(message: _getErrorMessage(e));
      return false;
    }
  }

  /// Toggle VIP status for a guest
  Future<Guest?> toggleVipStatus(int guestId) async {
    try {
      final updatedGuest = await _repository.toggleVipStatus(guestId);

      // Refresh providers
      _invalidateGuestProviders();
      _ref.invalidate(guestByIdProvider(guestId));

      // Update local guest list state if currently loaded
      state.whenOrNull(
        loaded: (guests) {
          final updatedList = guests.map((g) {
            return g.id == guestId ? updatedGuest : g;
          }).toList();
          state = GuestState.loaded(guests: updatedList);
        },
      );

      return updatedGuest;
    } catch (e) {
      state = GuestState.error(message: _getErrorMessage(e));
      return null;
    }
  }

  /// Find guest by phone number
  Future<Guest?> findByPhone(String phone) async {
    try {
      return await _repository.findByPhone(phone);
    } catch (e) {
      return null;
    }
  }

  /// Find guest by ID number
  Future<Guest?> findByIdNumber(String idNumber) async {
    try {
      return await _repository.findByIdNumber(idNumber);
    } catch (e) {
      return null;
    }
  }

  /// Invalidate all guest-related providers
  void _invalidateGuestProviders() {
    _ref.invalidate(guestsProvider);
    _ref.invalidate(vipGuestsProvider);
    _ref.invalidate(returningGuestsProvider);
    _ref.invalidate(recentGuestsProvider);
  }

  /// Get error message from exception
  String _getErrorMessage(dynamic error) {
    final l10n = _ref.read(l10nProvider);
    final message = error.toString().toLowerCase();
    if (message.contains('network') || message.contains('connection')) {
      return l10n.errorNoNetwork;
    }
    if (message.contains('phone') && message.contains('exists')) {
      return l10n.errorPhoneRegistered;
    }
    if (message.contains('id_number') && message.contains('exists')) {
      return l10n.errorIdRegistered;
    }
    if (message.contains('phone') && message.contains('digits')) {
      return l10n.errorPhoneDigits;
    }
    if (message.contains('không thể xóa') ||
        message.contains('cannot delete')) {
      return l10n.errorCannotDeleteGuest;
    }
    if (message.contains('not found') || message.contains('404')) {
      return l10n.errorGuestNotFound;
    }
    return l10n.errorGeneric;
  }
}

/// Provider for guest state notifier
final guestStateProvider = StateNotifierProvider<GuestNotifier, GuestState>((
  ref,
) {
  final repository = ref.watch(guestRepositoryProvider);
  return GuestNotifier(repository, ref);
});

/// Provider for selected guest (for detail view)
final selectedGuestProvider = StateProvider<Guest?>((ref) => null);

/// Provider for selected nationality filter
final selectedNationalityFilterProvider = StateProvider<String?>((ref) => null);

/// Provider for VIP filter state
final vipFilterProvider = StateProvider<bool?>((ref) => null);

/// Provider for search query
final guestSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search type
final guestSearchTypeProvider = StateProvider<String>((ref) => 'all');
