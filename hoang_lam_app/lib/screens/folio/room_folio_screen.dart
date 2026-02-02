import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/finance.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Room folio screen - displays all charges for a booking
class RoomFolioScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const RoomFolioScreen({
    required this.bookingId,
    super.key,
  });

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
    final folioState = ref.watch(folioNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Folio'),
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
            tooltip: folioState.includeVoided
                ? 'Ẩn mục đã hủy'
                : 'Hiện mục đã hủy',
          ),
          // Add charge button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddChargeDialog(context),
            tooltip: 'Thêm phí',
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              folioState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(folioNotifierProvider.notifier)
                    .loadFolio(widget.bookingId);
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final summary = folioState.summary;
    if (summary == null) {
      return const Center(
        child: Text('Không có dữ liệu folio'),
      );
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
            if (folioState.isLoading)
              const LinearProgressIndicator(),

            // Error banner
            if (folioState.error != null && folioState.summary != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        folioState.error!,
                        style: TextStyle(color: Colors.red[700]),
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
            label: const Text('Tất cả'),
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
                  color: folioState.filterType == type
                      ? Colors.white
                      : type.color,
                ),
                label: Text('${type.displayName} ($count)'),
                selected: folioState.filterType == type,
                selectedColor: type.color,
                onSelected: (_) {
                  ref.read(folioNotifierProvider.notifier).setFilterType(
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
    final items = folioState.includeVoided
        ? folioState.items
        : folioState.activeItems;

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
      builder: (context) => AddChargeDialog(
        bookingId: widget.bookingId,
        onChargeAdded: () {
          ref.read(folioNotifierProvider.notifier).refresh();
        },
      ),
    );
  }

  void _showVoidDialog(BuildContext context, FolioItem item) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy phí'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn hủy phí "${item.description}"?',
            ),
            const SizedBox(height: 16),
            Text(
              'Số tiền: ${currencyFormat.format(item.totalPrice)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy *',
                hintText: 'Nhập lý do hủy phí',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do hủy'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop();

              final success = await ref
                  .read(folioNotifierProvider.notifier)
                  .voidItem(item.id, reasonController.text.trim());

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã hủy phí thành công'
                          : 'Không thể hủy phí',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }
}
