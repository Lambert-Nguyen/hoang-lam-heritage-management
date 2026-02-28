import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/minibar.dart';
import '../../models/booking.dart';
import '../../providers/minibar_provider.dart';
import '../../providers/booking_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/minibar/minibar_item_grid.dart';
import '../../widgets/minibar/minibar_cart_panel.dart';

/// POS screen for minibar sales
class MinibarPosScreen extends ConsumerStatefulWidget {
  const MinibarPosScreen({super.key});

  @override
  ConsumerState<MinibarPosScreen> createState() => _MinibarPosScreenState();
}

class _MinibarPosScreenState extends ConsumerState<MinibarPosScreen> {
  String? _selectedCategory;
  Booking? _selectedBooking;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cartState = ref.watch(minibarCartProvider);
    final categoriesAsync = ref.watch(minibarCategoriesProvider);
    final itemsAsync = ref.watch(activeItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minibar POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            onPressed: () => context.push(AppRoutes.minibarInventory),
            tooltip: l10n.inventoryManagement,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          final itemPanel = Column(
            children: [
              // Booking selector
              _buildBookingSelector(),
              const Divider(height: 1),

              // Category filter
              categoriesAsync.when(
                data: (categories) => _buildCategoryFilter(categories),
                loading: () => const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Divider(height: 1),

              // Search bar
              _buildSearchBar(),
              const Divider(height: 1),

              // Item grid
              Expanded(
                child: itemsAsync.when(
                  data: (items) => _buildItemGrid(items),
                  loading: () => const LoadingIndicator(),
                  error: (error, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.error,
                    subtitle: error.toString(),
                  ),
                ),
              ),
            ],
          );

          final cartPanel = MinibarCartPanel(
            cartState: cartState,
            booking: _selectedBooking,
            onCheckout: _handleCheckout,
            onClear: _handleClearCart,
            onRemoveItem: _handleRemoveItem,
            onUpdateQuantity: _handleUpdateQuantity,
          );

          if (isWide) {
            // Side-by-side layout for tablets and wide screens
            return Row(
              children: [
                Expanded(flex: 2, child: itemPanel),
                const VerticalDivider(width: 1),
                Expanded(flex: 1, child: cartPanel),
              ],
            );
          }

          // Stacked layout for narrow phone screens
          return Column(
            children: [
              Expanded(child: itemPanel),
              const Divider(height: 1),
              SizedBox(
                height: constraints.maxHeight * 0.35,
                child: cartPanel,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingSelector() {
    final activeBookingsAsync = ref.watch(activeBookingsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          const Icon(Icons.hotel, color: AppColors.primary),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: activeBookingsAsync.when(
              data: (bookings) {
                // Show all currently checked-in bookings (not just today's)
                final checkedInBookings = bookings
                    .where((b) => b.status == BookingStatus.checkedIn)
                    .toList();
                return DropdownButtonFormField<Booking>(
                  // ignore: deprecated_member_use
                  value: _selectedBooking,
                  hint: Text(AppLocalizations.of(context)!.selectBooking),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: checkedInBookings.map((booking) {
                    return DropdownMenuItem(
                      value: booking,
                      child: Text(
                        'P.${booking.roomNumber} - ${booking.guestName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (booking) {
                    setState(() => _selectedBooking = booking);
                    if (booking != null) {
                      ref
                          .read(minibarCartProvider.notifier)
                          .setBooking(booking.id);
                    }
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) =>
                  Text(AppLocalizations.of(context)!.bookingListLoadError),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          FilterChip(
            label: Text(AppLocalizations.of(context)!.all),
            selected: _selectedCategory == null,
            onSelected: (_) => setState(() => _selectedCategory = null),
          ),
          AppSpacing.gapHorizontalSm,
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.searchProductHint,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildItemGrid(List<MinibarItem> items) {
    final l10n = context.l10n;
    // Filter by category
    var filteredItems = items;
    if (_selectedCategory != null) {
      filteredItems = items
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredItems = filteredItems.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }

    if (filteredItems.isEmpty) {
      return EmptyState(
        icon: Icons.local_bar,
        title: l10n.noProducts,
        subtitle: l10n.noMatchingProducts,
      );
    }

    return MinibarItemGrid(items: filteredItems, onItemTap: _handleAddToCart);
  }

  void _handleAddToCart(MinibarItem item) {
    final l10n = context.l10n;
    if (_selectedBooking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectBookingFirst),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    ref.read(minibarCartProvider.notifier).addItem(item);
  }

  void _handleRemoveItem(int itemId) {
    ref.read(minibarCartProvider.notifier).removeItem(itemId);
  }

  void _handleUpdateQuantity(int itemId, int quantity) {
    ref.read(minibarCartProvider.notifier).updateQuantity(itemId, quantity);
  }

  Future<void> _handleClearCart() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCartTitle),
        content: Text(l10n.clearCartConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(minibarCartProvider.notifier).clearCart();
    }
  }

  Future<void> _handleCheckout() async {
    final l10n = context.l10n;
    final cartState = ref.read(minibarCartProvider);
    if (cartState.items.isEmpty || _selectedBooking == null) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmCheckout),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.roomLabel}: ${_selectedBooking!.roomNumber}'),
            Text('${l10n.guestNameLabel}: ${_selectedBooking!.guestName}'),
            const SizedBox(height: 8),
            Text(
              '${l10n.totalLabel}: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(cartState.totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Create sales using processCart
    try {
      final success = await ref
          .read(minibarCartProvider.notifier)
          .processCart();

      if (mounted) {
        if (success) {
          setState(() => _selectedBooking = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkoutSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          final errorMessage = ref.read(minibarCartProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.error}: ${errorMessage ?? l10n.unknownError}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
