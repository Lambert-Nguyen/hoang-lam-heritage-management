import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/minibar.dart';

/// List tile widget for minibar item in inventory management
class MinibarItemListTile extends StatelessWidget {
  final MinibarItem item;
  final VoidCallback? onTap;
  final VoidCallback? onToggleActive;

  const MinibarItemListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: item.isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.textSecondary.withValues(alpha: 0.1),
        child: Icon(
          Icons.local_bar,
          color: item.isActive ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          decoration: item.isActive ? null : TextDecoration.lineThrough,
          color: item.isActive ? null : AppColors.textSecondary,
        ),
      ),
      subtitle: item.category.isNotEmpty ? Text(item.category) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(item.price),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${context.l10n.costAmount}: ${currencyFormat.format(item.cost)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          AppSpacing.gapHorizontalSm,
          IconButton(
            icon: Icon(
              item.isActive ? Icons.toggle_on : Icons.toggle_off,
              color: item.isActive
                  ? AppColors.success
                  : AppColors.textSecondary,
              size: 32,
            ),
            onPressed: onToggleActive,
            tooltip: item.isActive
                ? context.l10n.discontinued
                : context.l10n.activateLabel,
          ),
        ],
      ),
    );
  }
}
