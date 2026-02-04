import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/lost_found.dart';
import '../repositories/lost_found_repository.dart';

part 'lost_found_provider.freezed.dart';

/// Provider for LostFoundRepository
final lostFoundRepositoryProvider = Provider<LostFoundRepository>((ref) {
  return LostFoundRepository();
});

// ============================================================
// Lost & Found Item Providers
// ============================================================

/// Provider for all lost & found items
final lostFoundItemsProvider =
    FutureProvider<List<LostFoundItem>>((ref) async {
  final repository = ref.watch(lostFoundRepositoryProvider);
  return repository.getItems();
});

/// Provider for unclaimed items (found or stored)
final unclaimedItemsProvider =
    FutureProvider<List<LostFoundItem>>((ref) async {
  final repository = ref.watch(lostFoundRepositoryProvider);
  final items = await repository.getItems();
  return items
      .where((item) =>
          item.status == LostFoundStatus.found ||
          item.status == LostFoundStatus.stored)
      .toList();
});

/// Provider for recently found items (last 7 days)
final recentItemsProvider = FutureProvider<List<LostFoundItem>>((ref) async {
  final repository = ref.watch(lostFoundRepositoryProvider);
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  return repository.getItems(fromDate: sevenDaysAgo);
});

/// Provider for a specific item by ID
final lostFoundItemByIdProvider =
    FutureProvider.family<LostFoundItem, int>((ref, id) async {
  final repository = ref.watch(lostFoundRepositoryProvider);
  return repository.getItem(id);
});

/// Provider for filtered lost & found items
final filteredLostFoundItemsProvider =
    FutureProvider.family<List<LostFoundItem>, LostFoundFilter>(
        (ref, filter) async {
  final repository = ref.watch(lostFoundRepositoryProvider);
  return repository.getItems(
    status: filter.status,
    category: filter.category,
    roomId: filter.roomId,
    guestId: filter.guestId,
    search: filter.search,
    fromDate: filter.fromDate,
    toDate: filter.toDate,
  );
});

/// Provider for lost & found statistics
final lostFoundStatisticsProvider =
    FutureProvider<LostFoundStatistics>((ref) async {
  final repository = ref.watch(lostFoundRepositoryProvider);
  return repository.getStatistics();
});

/// Filter model for lost & found items
@freezed
sealed class LostFoundFilter with _$LostFoundFilter {
  const factory LostFoundFilter({
    LostFoundStatus? status,
    LostFoundCategory? category,
    int? roomId,
    int? guestId,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) = _LostFoundFilter;
}

// ============================================================
// State Management for Operations
// ============================================================

/// State for lost & found operations
@freezed
sealed class LostFoundState with _$LostFoundState {
  const factory LostFoundState({
    @Default(false) bool isLoading,
    String? errorMessage,
    LostFoundItem? selectedItem,
    @Default([]) List<LostFoundItem> items,
    LostFoundStatistics? statistics,
  }) = _LostFoundState;
}

/// StateNotifier for managing lost & found operations
class LostFoundNotifier extends StateNotifier<LostFoundState> {
  final LostFoundRepository _repository;
  final Ref _ref;

  LostFoundNotifier(this._repository, this._ref)
      : super(const LostFoundState());

  /// Load all items
  Future<void> loadItems({
    LostFoundStatus? status,
    LostFoundCategory? category,
    String? search,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getItems(
        status: status,
        category: category,
        search: search,
      );
      state = state.copyWith(
        isLoading: false,
        items: items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load statistics
  Future<void> loadStatistics() async {
    try {
      final statistics = await _repository.getStatistics();
      state = state.copyWith(statistics: statistics);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Create a new item
  Future<LostFoundItem?> createItem(LostFoundItemCreate item) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newItem = await _repository.createItem(item);
      await loadItems();
      _ref.invalidate(lostFoundItemsProvider);
      _ref.invalidate(lostFoundStatisticsProvider);
      return newItem;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Update an item
  Future<LostFoundItem?> updateItem(int id, LostFoundItemUpdate update) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedItem = await _repository.updateItem(id, update);
      await loadItems();
      _ref.invalidate(lostFoundItemByIdProvider(id));
      _ref.invalidate(lostFoundItemsProvider);
      return updatedItem;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Store an item
  Future<LostFoundItem?> storeItem(int id, {String? storageLocation}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final storedItem = await _repository.storeItem(
        id,
        storageLocation: storageLocation,
      );
      await loadItems();
      _ref.invalidate(lostFoundItemByIdProvider(id));
      _ref.invalidate(lostFoundItemsProvider);
      _ref.invalidate(lostFoundStatisticsProvider);
      return storedItem;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Claim an item
  Future<LostFoundItem?> claimItem(
    int id, {
    int? claimedByStaff,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final claimedItem = await _repository.claimItem(
        id,
        claimedByStaff: claimedByStaff,
        notes: notes,
      );
      await loadItems();
      _ref.invalidate(lostFoundItemByIdProvider(id));
      _ref.invalidate(lostFoundItemsProvider);
      _ref.invalidate(lostFoundStatisticsProvider);
      return claimedItem;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Dispose of an item
  Future<LostFoundItem?> disposeItem(
    int id, {
    required String reason,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final disposedItem = await _repository.disposeItem(
        id,
        reason: reason,
        notes: notes,
      );
      await loadItems();
      _ref.invalidate(lostFoundItemByIdProvider(id));
      _ref.invalidate(lostFoundItemsProvider);
      _ref.invalidate(lostFoundStatisticsProvider);
      return disposedItem;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Delete an item
  Future<bool> deleteItem(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteItem(id);
      await loadItems();
      _ref.invalidate(lostFoundItemsProvider);
      _ref.invalidate(lostFoundStatisticsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Select an item
  void selectItem(LostFoundItem? item) {
    state = state.copyWith(selectedItem: item);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for LostFoundNotifier
final lostFoundNotifierProvider =
    StateNotifierProvider<LostFoundNotifier, LostFoundState>((ref) {
  final repository = ref.watch(lostFoundRepositoryProvider);
  return LostFoundNotifier(repository, ref);
});
