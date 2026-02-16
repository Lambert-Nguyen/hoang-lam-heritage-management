import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lost_found.dart';
import '../../providers/lost_found_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen for listing lost & found items
class LostFoundListScreen extends ConsumerStatefulWidget {
  const LostFoundListScreen({super.key});

  @override
  ConsumerState<LostFoundListScreen> createState() =>
      _LostFoundListScreenState();
}

class _LostFoundListScreenState extends ConsumerState<LostFoundListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  LostFoundCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(lostFoundItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lostAndFound),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.pending),
            Tab(text: l10n.completed),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _showStatisticsSheet(),
            tooltip: l10n.statistics,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(),
            tooltip: l10n.filter,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingAll,
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_categoryFilter != null)
            Padding(
              padding: AppSpacing.paddingHorizontal,
              child: Row(
                children: [
                  Chip(
                    label: Text(_categoryFilter!.localizedName(context.l10n)),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _categoryFilter = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList(itemsAsync, null),
                _buildItemsList(itemsAsync, false),
                _buildItemsList(itemsAsync, true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/lost-found/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemsList(AsyncValue<List<LostFoundItem>> itemsAsync, bool? claimed) {
    return itemsAsync.when(
      data: (items) {
        final filtered = _filterItems(items, claimed);
        if (filtered.isEmpty) {
          return _buildEmptyState(claimed);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(lostFoundItemsProvider),
          child: ListView.builder(
            padding: AppSpacing.paddingHorizontal,
            itemCount: filtered.length,
            itemBuilder: (context, index) => _LostFoundItemCard(
              item: filtered[index],
              onTap: () => context.push('/lost-found/${filtered[index].id}'),
            ),
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        message: '${AppLocalizations.of(context)!.error}: $error',
        onRetry: () => ref.invalidate(lostFoundItemsProvider),
      ),
    );
  }

  List<LostFoundItem> _filterItems(List<LostFoundItem> items, bool? claimed) {
    return items.where((item) {
      if (claimed != null) {
        final isClaimed = item.status == LostFoundStatus.claimed;
        if (isClaimed != claimed) {
          return false;
        }
      }
      if (_categoryFilter != null && item.category != _categoryFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !item.itemName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildEmptyState(bool? claimed) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(
            claimed == true ? AppLocalizations.of(context)!.noClaimedItems : claimed == false ? AppLocalizations.of(context)!.noUnclaimedItems : AppLocalizations.of(context)!.noLostFoundItems,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.filterByCategoryLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilterChip(label: Text(AppLocalizations.of(context)!.all), selected: _categoryFilter == null, onSelected: (_) {
                  setState(() => _categoryFilter = null);
                  Navigator.pop(context);
                }),
                ...LostFoundCategory.values.map((c) => FilterChip(
                  label: Text(c.localizedName(context.l10n)),
                  selected: _categoryFilter == c,
                  onSelected: (_) {
                    setState(() => _categoryFilter = c);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showStatisticsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _StatisticsSheet(),
    );
  }
}

class _LostFoundItemCard extends StatelessWidget {
  final LostFoundItem item;
  final VoidCallback onTap;
  const _LostFoundItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: item.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(item.category.icon, color: item.category.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.itemName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(color: item.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                          child: Text(item.status.localizedName(context.l10n), style: TextStyle(color: item.status.color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (item.foundLocation.isNotEmpty) Text(item.foundLocation, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Text(_formatDate(item.foundDate), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String d) {
    try {
      final date = DateTime.parse(d);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return d;
    }
  }
}

class _StatisticsSheet extends ConsumerWidget {
  const _StatisticsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(lostFoundStatisticsProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
      builder: (context, scrollController) => Container(
        padding: AppSpacing.paddingAll,
        child: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.statistics, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: _StatCard(title: context.l10n.total, value: stats.totalItems.toString(), icon: Icons.inventory_2, color: AppColors.primary)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _StatCard(title: context.l10n.unclaimedValue, value: '${stats.unclaimedValue.toStringAsFixed(0)}₫', icon: Icons.attach_money, color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(context.l10n.byStatusLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ...stats.byStatus.entries.map((e) => _StatRow(label: e.key, value: e.value.toString())),
              ],
            ),
          ),
          loading: () => const LoadingIndicator(),
          error: (e, _) => Center(child: Text('${context.l10n.error}: $e')),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }
}
