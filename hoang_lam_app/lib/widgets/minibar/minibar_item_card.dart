import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/minibar.dart';

/// A card widget displaying a minibar item for POS selection
class MinibarItemCard extends StatelessWidget {
  final MinibarItem item;
  final VoidCallback? onTap;

  const MinibarItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isActive
              ? Colors.transparent
              : AppColors.error.withValues(alpha: 0.3),
          width: item.isActive ? 0 : 1,
        ),
      ),
      child: InkWell(
        onTap: item.isActive ? onTap : null,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon or image placeholder
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(item.category)
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(item.category),
                          size: 32,
                          color: _getCategoryColor(item.category),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalSm,

                  // Name
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.gapVerticalXs,

                  // Category
                  if (item.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(item.category)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getCategoryColor(item.category),
                        ),
                      ),
                    ),
                  AppSpacing.gapVerticalSm,

                  // Price
                  Text(
                    currencyFormat.format(item.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),

            // Inactive overlay
            if (!item.isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.discontinued,
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'nước ngọt':
      case 'nuoc ngot':
      case 'soft drink':
        return Icons.local_drink;
      case 'bia':
      case 'beer':
        return Icons.sports_bar;
      case 'rượu':
      case 'ruou':
      case 'wine':
      case 'alcohol':
        return Icons.wine_bar;
      case 'snack':
      case 'bánh':
      case 'banh':
        return Icons.bakery_dining;
      case 'chocolate':
      case 'kẹo':
      case 'keo':
        return Icons.cake;
      case 'nước suối':
      case 'nuoc suoi':
      case 'water':
        return Icons.water_drop;
      case 'cafe':
      case 'coffee':
      case 'cà phê':
        return Icons.coffee;
      case 'trà':
      case 'tra':
      case 'tea':
        return Icons.emoji_food_beverage;
      default:
        return Icons.local_bar;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'nước ngọt':
      case 'nuoc ngot':
      case 'soft drink':
        return Colors.blue;
      case 'bia':
      case 'beer':
        return Colors.amber;
      case 'rượu':
      case 'ruou':
      case 'wine':
      case 'alcohol':
        return Colors.purple;
      case 'snack':
      case 'bánh':
      case 'banh':
        return Colors.orange;
      case 'chocolate':
      case 'kẹo':
      case 'keo':
        return Colors.brown;
      case 'nước suối':
      case 'nuoc suoi':
      case 'water':
        return Colors.cyan;
      case 'cafe':
      case 'coffee':
      case 'cà phê':
        return Colors.brown;
      case 'trà':
      case 'tra':
      case 'tea':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }
}
