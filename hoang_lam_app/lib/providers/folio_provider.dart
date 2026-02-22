import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/finance.dart';
import '../repositories/finance_repository.dart';
import 'providers.dart';

part 'folio_provider.freezed.dart';

// ==================== Folio Providers (Phase 3.6) ====================

/// Provider for booking folio summary by booking ID
final bookingFolioProvider = FutureProvider.autoDispose
    .family<BookingFolioSummary, int>((ref, bookingId) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getBookingFolio(bookingId);
    });

/// Provider for folio items by booking ID
final folioItemsByBookingProvider = FutureProvider.autoDispose
    .family<List<FolioItem>, int>((ref, bookingId) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getFolioItems(bookingId: bookingId);
    });

/// Provider for folio items by type
final folioItemsByTypeProvider = FutureProvider.autoDispose
    .family<List<FolioItem>, FolioItemTypeFilter>((ref, filter) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getFolioItems(
        bookingId: filter.bookingId,
        itemType: filter.itemType,
        includeVoided: filter.includeVoided,
      );
    });

/// Filter class for folio items by type
@freezed
sealed class FolioItemTypeFilter with _$FolioItemTypeFilter {
  const factory FolioItemTypeFilter({
    required int bookingId,
    @Default(null) FolioItemType? itemType,
    @Default(false) bool includeVoided,
  }) = _FolioItemTypeFilter;
}

// ==================== Folio State Management ====================

/// State for folio screen
@freezed
sealed class FolioState with _$FolioState {
  const FolioState._();

  const factory FolioState({
    @Default(null) int? bookingId,
    @Default(null) BookingFolioSummary? summary,
    @Default([]) List<FolioItem> items,
    @Default(false) bool isLoading,
    @Default(null) String? error,
    @Default(false) bool includeVoided,
    @Default(null) FolioItemType? filterType,
  }) = _FolioState;

  /// Get active (non-voided) items
  List<FolioItem> get activeItems =>
      items.where((item) => !item.isVoided).toList();

  /// Get items grouped by type
  Map<FolioItemType, List<FolioItem>> get itemsByType {
    final itemsToGroup = includeVoided ? items : activeItems;
    final grouped = <FolioItemType, List<FolioItem>>{};
    for (final item in itemsToGroup) {
      grouped.putIfAbsent(item.itemType, () => []).add(item);
    }
    return grouped;
  }

  /// Get total for a specific type
  double totalForType(FolioItemType type) {
    final typeItems = itemsByType[type] ?? [];
    return typeItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}

/// State notifier for folio management
class FolioNotifier extends StateNotifier<FolioState> {
  final FinanceRepository _repository;
  final Ref _ref;

  FolioNotifier(this._repository, this._ref) : super(const FolioState());

  /// Load folio for a booking
  Future<void> loadFolio(int bookingId) async {
    state = state.copyWith(bookingId: bookingId, isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _repository.getBookingFolio(bookingId),
        _repository.getFolioItems(
          bookingId: bookingId,
          includeVoided: state.includeVoided,
        ),
      ]);

      state = state.copyWith(
        summary: results[0] as BookingFolioSummary,
        items: results[1] as List<FolioItem>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _ref
            .read(l10nProvider)
            .errorFolioLoad
            .replaceAll('{error}', e.toString()),
      );
    }
  }

  /// Refresh folio data
  Future<void> refresh() async {
    if (state.bookingId == null) return;
    await loadFolio(state.bookingId!);
  }

  /// Toggle include voided items
  void toggleIncludeVoided() {
    state = state.copyWith(includeVoided: !state.includeVoided);
    if (state.bookingId != null) {
      loadFolio(state.bookingId!);
    }
  }

  /// Set filter by type
  void setFilterType(FolioItemType? type) {
    state = state.copyWith(filterType: type);
  }

  /// Add a new charge to the folio
  Future<bool> addCharge(FolioItemCreateRequest request) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.createFolioItem(request);

      // Refresh folio data
      await refresh();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _ref
            .read(l10nProvider)
            .errorChargeAdd
            .replaceAll('{error}', e.toString()),
      );
      return false;
    }
  }

  /// Void a folio item
  Future<bool> voidItem(int itemId, String reason) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.voidFolioItem(itemId, reason);

      // Refresh folio data
      await refresh();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _ref
            .read(l10nProvider)
            .errorChargeVoid
            .replaceAll('{error}', e.toString()),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for FolioNotifier
final folioNotifierProvider =
    StateNotifierProvider.autoDispose<FolioNotifier, FolioState>((ref) {
      final repository = ref.watch(financeRepositoryProvider);
      return FolioNotifier(repository, ref);
    });
