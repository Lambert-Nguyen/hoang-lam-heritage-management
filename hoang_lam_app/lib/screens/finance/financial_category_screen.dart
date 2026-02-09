import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../providers/finance_provider.dart';

/// Screen for managing financial categories (income/expense)
class FinancialCategoryScreen extends ConsumerStatefulWidget {
  const FinancialCategoryScreen({super.key});

  @override
  ConsumerState<FinancialCategoryScreen> createState() =>
      _FinancialCategoryScreenState();
}

class _FinancialCategoryScreenState
    extends ConsumerState<FinancialCategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allCategories = ref.watch(financialCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financialCategories),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.arrow_downward, size: 18),
              text: l10n.income,
            ),
            Tab(
              icon: const Icon(Icons.arrow_upward, size: 18),
              text: l10n.expense,
            ),
          ],
        ),
      ),
      body: allCategories.when(
        data: (categories) {
          final incomeCategories = categories
              .where((c) => c.categoryType == EntryType.income)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final expenseCategories = categories
              .where((c) => c.categoryType == EntryType.expense)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return TabBarView(
            controller: _tabController,
            children: [
              _CategoryList(
                categories: incomeCategories,
                entryType: EntryType.income,
                emptyMessage: 'Chưa có danh mục thu',
              ),
              _CategoryList(
                categories: expenseCategories,
                entryType: EntryType.expense,
                emptyMessage: 'Chưa có danh mục chi',
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              AppSpacing.gapVerticalMd,
              Text('${l10n.error}: $error'),
              AppSpacing.gapVerticalMd,
              ElevatedButton(
                onPressed: () => ref.invalidate(financialCategoriesProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<FinancialCategory> categories;
  final EntryType entryType;
  final String emptyMessage;

  const _CategoryList({
    required this.categories,
    required this.entryType,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            AppSpacing.gapVerticalMd,
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Force refresh via parent
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryTile(category: category);
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final FinancialCategory category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final isIncome = category.categoryType == EntryType.income;
    final typeColor = isIncome ? AppColors.income : AppColors.expense;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: category.colorValue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          category.iconData,
          color: category.colorValue,
          size: 22,
        ),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: category.isActive ? null : AppColors.textSecondary,
          decoration: category.isActive ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isIncome ? 'Thu' : 'Chi',
              style: TextStyle(
                fontSize: 11,
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (category.entryCount != null && category.entryCount! > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${category.entryCount} giao dịch',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          if (!category.isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Ẩn',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (category.isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Mặc định',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: category.nameEn != null && category.nameEn!.isNotEmpty
          ? Text(
              category.nameEn!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
    );
  }
}
