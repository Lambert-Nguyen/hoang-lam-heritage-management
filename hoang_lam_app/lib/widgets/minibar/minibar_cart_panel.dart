import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/minibar.dart';
import '../../models/booking.dart';
import '../../providers/minibar_provider.dart';

/// Panel showing the shopping cart for minibar POS
class MinibarCartPanel extends StatelessWidget {
  final MinibarCartState cartState;
  final Booking? booking;
  final VoidCallback? onCheckout;
  final VoidCallback? onClear;
  final void Function(int itemId)? onRemoveItem;
  final void Function(int itemId, int quantity)? onUpdateQuantity;

  const MinibarCartPanel({
    super.key,
    required this.cartState,
    this.booking,
    this.onCheckout,
    this.onClear,
    this.onRemoveItem,
    this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(color: AppColors.primary),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              AppSpacing.gapHorizontalSm,
              Expanded(
                child: Text(
                  '${context.l10n.cartTitle} (${cartState.totalItemCount})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (cartState.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white),
                  onPressed: onClear,
                  tooltip: context.l10n.clearAll,
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),

        // Booking info
        if (booking != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            color: AppColors.surfaceVariant,
            child: Row(
              children: [
                const Icon(Icons.hotel, size: 16, color: AppColors.primary),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: Text(
                    'P.${booking!.roomNumber} - ${booking!.guestName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Cart items
        Expanded(
          child: cartState.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.emptyCart,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: cartState.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cartItem = cartState.items[index];
                    return _buildCartItem(context, cartItem, currencyFormat);
                  },
                ),
        ),

        // Summary and checkout
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.deepAccent.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${context.l10n.total}:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    currencyFormat.format(cartState.totalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalMd,

              // Checkout button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: cartState.items.isNotEmpty && booking != null
                      ? onCheckout
                      : null,
                  icon: const Icon(Icons.point_of_sale),
                  label: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(context.l10n.checkoutBtn),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    MinibarCartItem cartItem,
    NumberFormat currencyFormat,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(cartItem.item.price),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: cartItem.quantity > 1
                    ? () => onUpdateQuantity?.call(
                        cartItem.item.id,
                        cartItem.quantity - 1,
                      )
                    : () => onRemoveItem?.call(cartItem.item.id),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                alignment: Alignment.center,
                child: Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: () => onUpdateQuantity?.call(
                  cartItem.item.id,
                  cartItem.quantity + 1,
                ),
              ),
            ],
          ),

          // Subtotal
          SizedBox(
            width: 80,
            child: Text(
              currencyFormat.format(cartItem.total),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
