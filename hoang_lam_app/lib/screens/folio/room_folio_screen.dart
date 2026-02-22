import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

import '../../models/finance.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/app_colors.dart';

/// Room folio screen - displays all charges for a booking
class RoomFolioScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const RoomFolioScreen({required this.bookingId, super.key});

  @override
  ConsumerState<RoomFolioScreen> createState() => _RoomFolioScreenState();
}

class _RoomFolioScreenState extends ConsumerState<RoomFolioScreen> {
  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Load folio data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(folioNotifierProvider.notifier).loadFolio(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final folioState = ref.watch(folioNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Folio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Toggle voided items
          IconButton(
            icon: Icon(
              folioState.includeVoided
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: () {
              ref.read(folioNotifierProvider.notifier).toggleIncludeVoided();
            },
            tooltip:
                folioState.includeVoided
                    ? l10n.hideCancelledItems
                    : l10n.showCancelledItems,
          ),
          // Add charge button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddChargeDialog(context),
            tooltip: l10n.addCharge,
          ),
        ],
      ),
      body: _buildBody(context, folioState),
    );
  }

  Widget _buildBody(BuildContext context, FolioState folioState) {
    if (folioState.isLoading && folioState.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (folioState.error != null && folioState.summary == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              folioState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(folioNotifierProvider.notifier)
                    .loadFolio(widget.bookingId);
              },
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    final summary = folioState.summary;
    if (summary == null) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(folioNotifierProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loading indicator overlay
            if (folioState.isLoading) const LinearProgressIndicator(),

            // Error banner
            if (folioState.error != null && folioState.summary != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        folioState.error!,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(folioNotifierProvider.notifier).clearError();
                      },
                    ),
                  ],
                ),
              ),

            // Folio Summary Card
            FolioSummaryWidget(
              summary: summary,
              currencyFormat: currencyFormat,
            ),

            const SizedBox(height: 16),

            // Type filter chips
            _buildTypeFilterChips(folioState),

            const SizedBox(height: 16),

            // Folio Items List
            FolioItemListWidget(
              items: _getFilteredItems(folioState),
              currencyFormat: currencyFormat,
              onVoid: (item) => _showVoidDialog(context, item),
              includeVoided: folioState.includeVoided,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChips(FolioState folioState) {
    final itemsByType = folioState.itemsByType;
    if (itemsByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All filter
          FilterChip(
            label: Text(AppLocalizations.of(context)!.all),
            selected: folioState.filterType == null,
            onSelected: (_) {
              ref.read(folioNotifierProvider.notifier).setFilterType(null);
            },
          ),
          const SizedBox(width: 8),
          // Type filters
          ...itemsByType.keys.map((type) {
            final count = itemsByType[type]!.length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  type.icon,
                  size: 16,
                  color:
                      folioState.filterType == type ? Colors.white : type.color,
                ),
                label: Text('${type.localizedName(context.l10n)} ($count)'),
                selected: folioState.filterType == type,
                selectedColor: type.color,
                onSelected: (_) {
                  ref
                      .read(folioNotifierProvider.notifier)
                      .setFilterType(
                        folioState.filterType == type ? null : type,
                      );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  List<FolioItem> _getFilteredItems(FolioState folioState) {
    final items =
        folioState.includeVoided ? folioState.items : folioState.activeItems;

    if (folioState.filterType == null) {
      return items;
    }

    return items
        .where((item) => item.itemType == folioState.filterType)
        .toList();
  }

  void _showAddChargeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AddChargeDialog(
            bookingId: widget.bookingId,
            onChargeAdded: () {
              ref.read(folioNotifierProvider.notifier).refresh();
            },
          ),
    );
  }

  void _showVoidDialog(BuildContext context, FolioItem item) {
    final reasonController = TextEditingController();
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.voidCharge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.confirmVoidCharge} "${item.description}"?'),
                const SizedBox(height: 16),
                Text(
                  '${l10n.chargeAmount}: ${currencyFormat.format(item.totalPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: '${l10n.enterVoidReason} *',
                    hintText: l10n.pleaseEnterVoidReason,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.voidReasonRequired),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();

                  final success = await ref
                      .read(folioNotifierProvider.notifier)
                      .voidItem(item.id, reasonController.text.trim());

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? l10n.chargeVoidedSuccess
                              : l10n.cannotVoidCharge,
                        ),
                        backgroundColor:
                            success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
                child: Text(l10n.confirmVoid),
              ),
            ],
          ),
    ).then((_) => reasonController.dispose());
  }
}
