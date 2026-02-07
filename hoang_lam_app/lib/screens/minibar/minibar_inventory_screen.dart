import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/minibar.dart';
import '../../providers/minibar_provider.dart';
import '../../widgets/common/offline_banner.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/minibar/minibar_item_list_tile.dart';
import 'minibar_item_form_screen.dart';

/// Inventory management screen for minibar items
class MinibarInventoryScreen extends ConsumerStatefulWidget {
  const MinibarInventoryScreen({super.key});

  @override
  ConsumerState<MinibarInventoryScreen> createState() =>
      _MinibarInventoryScreenState();
}

class _MinibarInventoryScreenState extends ConsumerState<MinibarInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.minibarManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.point_of_sale),
            onPressed: () => Navigator.pop(context),
            tooltip: 'POS',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.addProduct.replaceAll('Thêm ', '')),
            Tab(text: l10n.history),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemsTab(),
          _buildSalesHistoryTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _addNewItem,
              tooltip: AppLocalizations.of(context)!.addProduct,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildItemsTab() {
    final itemsAsync = ref.watch(minibarItemsProvider);
    final categoriesAsync = ref.watch(minibarCategoriesProvider);

    return Column(
      children: [
        // Category filter
        categoriesAsync.when(
          data: (categories) => _buildCategoryFilter(categories),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const Divider(height: 1),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchProducts,
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
        ),

        // Items list
        Expanded(
          child: itemsAsync.when(
            data: (items) => _buildItemsList(items),
            loading: () => const LoadingIndicator(),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Lỗi',
              subtitle: error.toString(),
            ),
          ),
        ),
      ],
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

  Widget _buildItemsList(List<MinibarItem> items) {
    // Filter by category
    var filteredItems = items;
    if (_selectedCategory != null) {
      filteredItems =
          items.where((item) => item.category == _selectedCategory).toList();
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
      return const EmptyState(
        icon: Icons.local_bar,
        title: 'Không có sản phẩm',
        subtitle: 'Chưa có sản phẩm nào trong danh mục này',
      );
    }

    // Group by category
    final groupedItems = <String, List<MinibarItem>>{};
    for (final item in filteredItems) {
      final category = item.category.isNotEmpty ? item.category : 'Khác';
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(minibarItemsProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: groupedItems.length,
        itemBuilder: (context, index) {
          final category = groupedItems.keys.elementAt(index);
          final categoryItems = groupedItems[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapHorizontalSm,
                    Text(
                      '(${categoryItems.length})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Items in category
              ...categoryItems.map(
                (item) => MinibarItemListTile(
                  item: item,
                  onTap: () => _editItem(item),
                  onToggleActive: () => _toggleItemActive(item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSalesHistoryTab() {
    final salesAsync = ref.watch(minibarSalesProvider);

    return salesAsync.when(
      data: (sales) {
        if (sales.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long,
            title: 'Chưa có bán hàng',
            subtitle: 'Lịch sử bán hàng sẽ hiển thị ở đây',
          );
        }

        // Group by date
        final groupedSales = <String, List<MinibarSale>>{};
        final dateFormat = DateFormat('dd/MM/yyyy');
        for (final sale in sales) {
          final dateKey = dateFormat.format(sale.date);
          groupedSales.putIfAbsent(dateKey, () => []).add(sale);
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(minibarSalesProvider.future),
          child: ListView.builder(
            itemCount: groupedSales.length,
            itemBuilder: (context, index) {
              final date = groupedSales.keys.elementAt(index);
              final dateSales = groupedSales[date]!;
              final totalAmount = dateSales.fold<double>(
                0,
                (sum, sale) => sum + sale.total,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    color: AppColors.surfaceVariant,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: '₫',
                            decimalDigits: 0,
                          ).format(totalAmount),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Sales list
                  ...dateSales.map(
                    (sale) => _buildSaleListTile(sale),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Lỗi',
        subtitle: error.toString(),
      ),
    );
  }

  Widget _buildSaleListTile(MinibarSale sale) {
    final timeFormat = DateFormat('HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: sale.isCharged
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        child: Icon(
          sale.isCharged ? Icons.check : Icons.pending,
          color: sale.isCharged ? AppColors.success : AppColors.warning,
        ),
      ),
      title: Text(sale.itemName ?? 'Sản phẩm'),
      subtitle: Text(
        'P.${sale.bookingRoomNumber ?? sale.booking} • ${timeFormat.format(sale.date)} • x${sale.quantity}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(sale.total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (sale.isCharged)
            const Text(
              'Đã charge',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.success,
              ),
            ),
        ],
      ),
      onTap: () => _showSaleDetails(sale),
    );
  }

  void _addNewItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MinibarItemFormScreen(),
      ),
    );
  }

  void _editItem(MinibarItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MinibarItemFormScreen(item: item),
      ),
    );
  }

  Future<void> _toggleItemActive(MinibarItem item) async {
    try {
      await ref.read(minibarProvider.notifier).toggleItemActive(item.id);
      ref.invalidate(minibarItemsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  void _showSaleDetails(MinibarSale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sale.itemName ?? 'Chi tiết bán hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phòng', sale.bookingRoomNumber ?? '-'),
            _buildDetailRow('Khách', sale.bookingGuestName ?? '-'),
            _buildDetailRow('Số lượng', '${sale.quantity}'),
            _buildDetailRow(
              'Đơn giá',
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: '₫',
                decimalDigits: 0,
              ).format(sale.unitPrice),
            ),
            _buildDetailRow(
              'Thành tiền',
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: '₫',
                decimalDigits: 0,
              ).format(sale.total),
            ),
            _buildDetailRow(
              'Trạng thái',
              sale.isCharged ? 'Đã charge' : 'Chưa charge',
            ),
            _buildDetailRow(
              'Thời gian',
              DateFormat('HH:mm dd/MM/yyyy').format(sale.date),
            ),
          ],
        ),
        actions: [
          if (!sale.isCharged)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _markSaleCharged(sale);
              },
              child: const Text('Đánh dấu đã charge'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _markSaleCharged(MinibarSale sale) async {
    try {
      await ref.read(minibarProvider.notifier).markSaleCharged(sale.id);
      ref.invalidate(minibarSalesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu charge thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
}
