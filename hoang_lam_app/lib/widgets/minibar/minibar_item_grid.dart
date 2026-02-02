import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/minibar.dart';
import 'minibar_item_card.dart';

/// Grid view of minibar items for POS selection
class MinibarItemGrid extends StatelessWidget {
  final List<MinibarItem> items;
  final void Function(MinibarItem item)? onItemTap;

  const MinibarItemGrid({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MinibarItemCard(
          item: item,
          onTap: () => onItemTap?.call(item),
        );
      },
    );
  }
}
