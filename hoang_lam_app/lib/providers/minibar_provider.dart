import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/minibar.dart';
import '../repositories/minibar_repository.dart';
import 'settings_provider.dart';

part 'minibar_provider.freezed.dart';

/// Provider for MinibarRepository
final minibarRepositoryProvider = Provider<MinibarRepository>((ref) {
  return MinibarRepository();
});

// ============================================================
// Minibar Item Providers
// ============================================================

/// Provider for all minibar items
final minibarItemsProvider = FutureProvider<List<MinibarItem>>((ref) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getItems();
});

/// Provider for active minibar items
final activeItemsProvider = FutureProvider<List<MinibarItem>>((ref) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getActiveItems();
});

/// Provider for minibar categories
final minibarCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getCategories();
});

/// Provider for a specific minibar item by ID
final minibarItemByIdProvider = FutureProvider.family<MinibarItem, int>((
  ref,
  id,
) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getItem(id);
});

/// Provider for filtered minibar items
final filteredMinibarItemsProvider =
    FutureProvider.family<List<MinibarItem>, MinibarItemFilter?>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(minibarRepositoryProvider);
      return repository.getItems(
        isActive: filter?.isActive,
        category: filter?.category,
        search: filter?.search,
      );
    });

// ============================================================
// Minibar Sale Providers
// ============================================================

/// Provider for all minibar sales
final minibarSalesProvider = FutureProvider<List<MinibarSale>>((ref) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getSales();
});

/// Provider for minibar sales by booking ID
final salesByBookingProvider = FutureProvider.family<List<MinibarSale>, int>((
  ref,
  bookingId,
) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getSales(bookingId: bookingId);
});

/// Provider for uncharged minibar sales by booking ID
final unchargedSalesProvider = FutureProvider.family<List<MinibarSale>, int>((
  ref,
  bookingId,
) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getUnchargedSales(bookingId);
});

/// Provider for minibar sales summary by booking ID
final salesSummaryProvider = FutureProvider.family<MinibarSalesSummary, int>((
  ref,
  bookingId,
) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getSalesSummary(bookingId);
});

/// Provider for a specific minibar sale by ID
final minibarSaleByIdProvider = FutureProvider.family<MinibarSale, int>((
  ref,
  id,
) async {
  final repository = ref.watch(minibarRepositoryProvider);
  return repository.getSale(id);
});

/// Provider for filtered minibar sales
final filteredMinibarSalesProvider =
    FutureProvider.family<List<MinibarSale>, MinibarSaleFilter?>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(minibarRepositoryProvider);
      return repository.getSales(
        bookingId: filter?.booking,
        roomId: filter?.room,
        dateFrom: filter?.dateFrom,
        dateTo: filter?.dateTo,
        isCharged: filter?.isCharged,
      );
    });

// ============================================================
// POS Cart State
// ============================================================

/// State for minibar POS cart
@freezed
sealed class MinibarCartState with _$MinibarCartState {
  const MinibarCartState._();

  const factory MinibarCartState({
    @Default([]) List<MinibarCartItem> items,
    int? bookingId,
    @Default(false) bool isProcessing,
    String? errorMessage,
  }) = _MinibarCartState;

  /// Total amount in cart
  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  /// Total item count
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Format total for display
  String get formattedTotal => '${totalAmount.toStringAsFixed(0)} ₫';

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get hasItems => items.isNotEmpty;
}

/// StateNotifier for POS cart
class MinibarCartNotifier extends StateNotifier<MinibarCartState> {
  final MinibarRepository _repository;
  final Ref _ref;

  MinibarCartNotifier(this._repository, this._ref)
    : super(const MinibarCartState());

  /// Set booking for the cart
  void setBooking(int bookingId) {
    state = state.copyWith(bookingId: bookingId);
  }

  /// Add item to cart
  void addItem(MinibarItem item, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere(
      (cartItem) => cartItem.item.id == item.id,
    );

    if (existingIndex >= 0) {
      // Update quantity of existing item
      final updatedItems = [...state.items];
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      state = state.copyWith(
        items: [
          ...state.items,
          MinibarCartItem(item: item, quantity: quantity),
        ],
      );
    }
  }

  /// Remove item from cart
  void removeItem(int itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.item.id != itemId).toList(),
    );
  }

  /// Update item quantity
  void updateQuantity(int itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final updatedItems = state.items.map((cartItem) {
      if (cartItem.item.id == itemId) {
        return cartItem.copyWith(quantity: quantity);
      }
      return cartItem;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Increment item quantity
  void incrementQuantity(int itemId) {
    final item = state.items.firstWhere(
      (cartItem) => cartItem.item.id == itemId,
      orElse: () => throw Exception('Item not found in cart'),
    );
    updateQuantity(itemId, item.quantity + 1);
  }

  /// Decrement item quantity
  void decrementQuantity(int itemId) {
    final item = state.items.firstWhere(
      (cartItem) => cartItem.item.id == itemId,
      orElse: () => throw Exception('Item not found in cart'),
    );
    updateQuantity(itemId, item.quantity - 1);
  }

  /// Clear cart
  void clearCart() {
    state = const MinibarCartState();
  }

  /// Process cart and create sales
  Future<bool> processCart() async {
    if (state.bookingId == null) {
      state = state.copyWith(
        errorMessage: _ref.read(l10nProvider).errorNoBookingSelected,
      );
      return false;
    }

    if (state.items.isEmpty) {
      state = state.copyWith(
        errorMessage: _ref.read(l10nProvider).errorEmptyCart,
      );
      return false;
    }

    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final request = BulkCreateMinibarSaleRequest(
        booking: state.bookingId!,
        items: state.items
            .map(
              (item) => MinibarSaleItem(
                itemId: item.item.id,
                quantity: item.quantity,
              ),
            )
            .toList(),
        date: DateTime.now(),
      );

      await _repository.bulkCreateSales(request);

      // Capture bookingId before clearing state
      final currentBookingId = state.bookingId;

      // Clear cart
      state = const MinibarCartState();

      // Invalidate providers with the captured bookingId
      _invalidateProviders(currentBookingId);

      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.toString());
      return false;
    }
  }

  void _invalidateProviders([int? bookingId]) {
    _ref.invalidate(minibarSalesProvider);
    final id = bookingId ?? state.bookingId;
    if (id != null) {
      _ref.invalidate(salesByBookingProvider(id));
      _ref.invalidate(unchargedSalesProvider(id));
      _ref.invalidate(salesSummaryProvider(id));
    }
  }
}

/// Provider for POS cart
final minibarCartProvider =
    StateNotifierProvider<MinibarCartNotifier, MinibarCartState>((ref) {
      final repository = ref.watch(minibarRepositoryProvider);
      return MinibarCartNotifier(repository, ref);
    });

// ============================================================
// Minibar Operations State
// ============================================================

/// State for minibar operations
@freezed
sealed class MinibarState with _$MinibarState {
  const factory MinibarState({
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default([]) List<MinibarItem> items,
    @Default([]) List<MinibarSale> sales,
    MinibarItem? selectedItem,
    MinibarSale? selectedSale,
  }) = _MinibarState;
}

/// StateNotifier for managing minibar operations
class MinibarNotifier extends StateNotifier<MinibarState> {
  final MinibarRepository _repository;
  final Ref _ref;

  MinibarNotifier(this._repository, this._ref) : super(const MinibarState());

  // ==================== Item Operations ====================

  /// Load all items
  Future<void> loadItems({
    bool? isActive,
    String? category,
    String? search,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getItems(
        isActive: isActive,
        category: category,
        search: search,
      );
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Create a new item
  Future<MinibarItem?> createItem(CreateMinibarItemRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newItem = await _repository.createItem(request);
      state = state.copyWith(
        isLoading: false,
        items: [...state.items, newItem],
      );
      _invalidateItemProviders();
      return newItem;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Update an item
  Future<MinibarItem?> updateItem(
    int id,
    UpdateMinibarItemRequest request,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.updateItem(id, request);
      final updatedItems = state.items.map((item) {
        return item.id == id ? updated : item;
      }).toList();
      state = state.copyWith(isLoading: false, items: updatedItems);
      _invalidateItemProviders();
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Toggle item active status
  Future<MinibarItem?> toggleItemActive(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.toggleItemActive(id);
      final updatedItems = state.items.map((item) {
        return item.id == id ? updated : item;
      }).toList();
      state = state.copyWith(isLoading: false, items: updatedItems);
      _invalidateItemProviders();
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Delete an item
  Future<bool> deleteItem(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteItem(id);
      final updatedItems = state.items.where((item) => item.id != id).toList();
      state = state.copyWith(isLoading: false, items: updatedItems);
      _invalidateItemProviders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // ==================== Sale Operations ====================

  /// Load sales
  Future<void> loadSales({
    int? bookingId,
    int? roomId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isCharged,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final sales = await _repository.getSales(
        bookingId: bookingId,
        roomId: roomId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        isCharged: isCharged,
      );
      state = state.copyWith(isLoading: false, sales: sales);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Create a sale
  Future<MinibarSale?> createSale(CreateMinibarSaleRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newSale = await _repository.createSale(request);
      state = state.copyWith(
        isLoading: false,
        sales: [...state.sales, newSale],
      );
      _invalidateSaleProviders(request.booking);
      return newSale;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Mark a sale as charged
  Future<MinibarSale?> markSaleCharged(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.markSaleCharged(id);
      final updatedSales = state.sales.map((sale) {
        return sale.id == id ? updated : sale;
      }).toList();
      state = state.copyWith(isLoading: false, sales: updatedSales);
      _invalidateSaleProviders(updated.booking);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Unmark a sale as charged
  Future<MinibarSale?> unmarkSaleCharged(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.unmarkSaleCharged(id);
      final updatedSales = state.sales.map((sale) {
        return sale.id == id ? updated : sale;
      }).toList();
      state = state.copyWith(isLoading: false, sales: updatedSales);
      _invalidateSaleProviders(updated.booking);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Delete a sale
  Future<bool> deleteSale(int id, int bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteSale(id);
      final updatedSales = state.sales.where((sale) => sale.id != id).toList();
      state = state.copyWith(isLoading: false, sales: updatedSales);
      _invalidateSaleProviders(bookingId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Charge all sales for a booking
  Future<ChargeAllResponse?> chargeAllSales(int bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.chargeAllSales(bookingId);
      await loadSales(bookingId: bookingId);
      _invalidateSaleProviders(bookingId);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  void _invalidateItemProviders() {
    _ref.invalidate(minibarItemsProvider);
    _ref.invalidate(activeItemsProvider);
    _ref.invalidate(minibarCategoriesProvider);
  }

  void _invalidateSaleProviders(int bookingId) {
    _ref.invalidate(minibarSalesProvider);
    _ref.invalidate(salesByBookingProvider(bookingId));
    _ref.invalidate(unchargedSalesProvider(bookingId));
    _ref.invalidate(salesSummaryProvider(bookingId));
  }
}

/// Provider for minibar state management
final minibarProvider = StateNotifierProvider<MinibarNotifier, MinibarState>((
  ref,
) {
  final repository = ref.watch(minibarRepositoryProvider);
  return MinibarNotifier(repository, ref);
});
