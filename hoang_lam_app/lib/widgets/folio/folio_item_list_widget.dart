import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';

/// Widget to display a list of folio items grouped by type
class FolioItemListWidget extends StatelessWidget {
  final List<FolioItem> items;
  final NumberFormat currencyFormat;
  final void Function(FolioItem item)? onVoid;
  final bool includeVoided;

  const FolioItemListWidget({
    required this.items,
    required this.currencyFormat,
    this.onVoid,
    this.includeVoided = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.noCharges,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group items by type
    final groupedItems = <FolioItemType, List<FolioItem>>{};
    for (final item in items) {
      groupedItems.putIfAbsent(item.itemType, () => []).add(item);
    }

    // Sort groups by type order
    final sortedTypes = groupedItems.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedTypes.map((type) {
        final typeItems = groupedItems[type]!;
        final typeTotal = typeItems.fold<double>(
          0,
          (sum, item) => sum + (item.isVoided ? 0 : item.totalPrice),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      type.icon,
                      color: type.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type.localizedName(context.l10n),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: type.color,
                        ),
                      ),
                    ),
                    Text(
                      '${typeItems.length} ${context.l10n.itemsCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(typeTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: type.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Items list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: typeItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = typeItems[index];
                  return _buildItemTile(context, item);
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemTile(BuildContext context, FolioItem item) {
    final isVoided = item.isVoided;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Opacity(
      opacity: isVoided ? 0.5 : 1.0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isVoided
              ? AppColors.surfaceVariant
              : item.itemType.color.withValues(alpha: 0.2),
          child: Icon(
            item.itemType.icon,
            color: isVoided ? Colors.grey : item.itemType.color,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.description,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  decoration: isVoided ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isVoided)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.l10n.voided,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red[700],
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${item.quantity} x ${currencyFormat.format(item.unitPrice)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(item.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (item.voidReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${context.l10n.reason}: ${item.voidReason}',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.red[400],
                  ),
                ),
              ),
            if (item.createdByName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${context.l10n.byLabel}: ${item.createdByName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(item.totalPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isVoided ? Colors.grey : AppColors.primary,
                    decoration: isVoided ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isVoided && item.isPaid)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.paidAbbreviation,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (!isVoided && onVoid != null)
              IconButton(
                icon: Icon(Icons.block, color: Colors.red[400], size: 20),
                tooltip: context.l10n.cancelCharge,
                onPressed: () => onVoid!(item),
                padding: const EdgeInsets.only(left: 8),
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        onLongPress: !isVoided && onVoid != null
            ? () => onVoid!(item)
            : null,
      ),
    );
  }
}
