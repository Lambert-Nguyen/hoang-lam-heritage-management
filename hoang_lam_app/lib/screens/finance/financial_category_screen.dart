import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../providers/finance_provider.dart';
import '../../repositories/finance_repository.dart';

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

  void _refreshCategories() {
    ref.invalidate(financialCategoriesProvider);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final entryType = _tabController.index == 0
              ? EntryType.income
              : EntryType.expense;
          _showCategoryDialog(context, entryType: entryType);
        },
        child: const Icon(Icons.add),
      ),
      body: allCategories.when(
        data: (categories) {
          final incomeCategories =
              categories
                  .where((c) => c.categoryType == EntryType.income)
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final expenseCategories =
              categories
                  .where((c) => c.categoryType == EntryType.expense)
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return TabBarView(
            controller: _tabController,
            children: [
              _CategoryList(
                categories: incomeCategories,
                entryType: EntryType.income,
                emptyMessage: l10n.noIncomeCategories,
                onRefresh: _refreshCategories,
                onEdit: (cat) => _showCategoryDialog(context, category: cat),
                onToggleActive: (cat) => _toggleActive(cat),
                onDelete: (cat) => _confirmDelete(context, cat),
              ),
              _CategoryList(
                categories: expenseCategories,
                entryType: EntryType.expense,
                emptyMessage: l10n.noExpenseCategories,
                onRefresh: _refreshCategories,
                onEdit: (cat) => _showCategoryDialog(context, category: cat),
                onToggleActive: (cat) => _toggleActive(cat),
                onDelete: (cat) => _confirmDelete(context, cat),
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
                onPressed: _refreshCategories,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    FinancialCategory? category,
    EntryType? entryType,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _CategoryFormDialog(
        category: category,
        entryType: entryType ?? category?.categoryType ?? EntryType.income,
        repository: ref.read(financeRepositoryProvider),
      ),
    );
    if (result == true) {
      _refreshCategories();
    }
  }

  Future<void> _toggleActive(FinancialCategory category) async {
    try {
      await ref
          .read(financeRepositoryProvider)
          .toggleCategoryActive(category.id, isActive: !category.isActive);
      _refreshCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              category.isActive
                  ? '${context.l10n.categoryHidden} "${category.name}"'
                  : '${context.l10n.categoryShown} "${category.name}"',
            ),
            action: SnackBarAction(
              label: context.l10n.undo,
              onPressed: () async {
                await ref
                    .read(financeRepositoryProvider)
                    .toggleCategoryActive(
                      category.id,
                      isActive: category.isActive,
                    );
                _refreshCategories();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FinancialCategory category,
  ) async {
    final l10n = context.l10n;
    if (category.entryCount != null && category.entryCount! > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.cannotDeleteCategoryMsg
                .replaceAll('{name}', category.name)
                .replaceAll('{count}', '${category.entryCount}'),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text(
          l10n.confirmDeleteCategoryMsg.replaceAll('{name}', category.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(financeRepositoryProvider).deleteCategory(category.id);
        _refreshCategories();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.categoryDeletedMsg} "${category.name}"'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ============================================================
// Category List
// ============================================================

class _CategoryList extends StatelessWidget {
  final List<FinancialCategory> categories;
  final EntryType entryType;
  final String emptyMessage;
  final VoidCallback onRefresh;
  final ValueChanged<FinancialCategory> onEdit;
  final ValueChanged<FinancialCategory> onToggleActive;
  final ValueChanged<FinancialCategory> onDelete;

  const _CategoryList({
    required this.categories,
    required this.entryType,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
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

    // Separate active and inactive
    final active = categories.where((c) => c.isActive).toList();
    final inactive = categories.where((c) => !c.isActive).toList();
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: 80, // space for FAB
        ),
        children: [
          // Active categories
          if (active.isNotEmpty) ...[
            _buildSectionLabel(
              l10n.activeInUseCount.replaceAll('{count}', '${active.length}'),
              color: AppColors.success,
            ),
            ...active.map(
              (cat) => _CategoryTile(
                category: cat,
                onEdit: onEdit,
                onToggleActive: onToggleActive,
                onDelete: onDelete,
              ),
            ),
          ],

          // Inactive categories
          if (inactive.isNotEmpty) ...[
            _buildSectionLabel(
              l10n.hiddenCount.replaceAll('{count}', '${inactive.length}'),
              color: AppColors.textSecondary,
            ),
            ...inactive.map(
              (cat) => _CategoryTile(
                category: cat,
                onEdit: onEdit,
                onToggleActive: onToggleActive,
                onDelete: onDelete,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, {required Color color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================
// Category Tile with swipe actions
// ============================================================

class _CategoryTile extends StatelessWidget {
  final FinancialCategory category;
  final ValueChanged<FinancialCategory> onEdit;
  final ValueChanged<FinancialCategory> onToggleActive;
  final ValueChanged<FinancialCategory> onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = category.categoryType == EntryType.income;
    final typeColor = isIncome ? AppColors.income : AppColors.expense;

    return Dismissible(
      key: ValueKey(category.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left → toggle active
          onToggleActive(category);
          return false;
        } else {
          // Swipe right → delete
          onDelete(category);
          return false;
        }
      },
      background: Container(
        color: AppColors.error.withValues(alpha: 0.1),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      secondaryBackground: Container(
        color: (category.isActive ? AppColors.warning : AppColors.success)
            .withValues(alpha: 0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          category.isActive ? Icons.visibility_off : Icons.visibility,
          color: category.isActive ? AppColors.warning : AppColors.success,
        ),
      ),
      child: ListTile(
        onTap: () => onEdit(category),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.colorValue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            category.iconData,
            color: category.isActive
                ? category.colorValue
                : AppColors.textSecondary,
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
                isIncome ? l10n.incomeShort : l10n.expenseShort,
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
                '${category.entryCount} ${l10n.transactionsLabel}',
                style: const TextStyle(fontSize: 12),
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
                child: Text(
                  l10n.defaultBadge,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.nameEn != null && category.nameEn!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  category.nameEn!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Category Form Dialog (Create / Edit)
// ============================================================

/// Available icon options for categories
const _availableIcons = <String, IconData>{
  'hotel': Icons.hotel,
  'payments': Icons.payments,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'wifi': Icons.wifi,
  'cleaning_services': Icons.cleaning_services,
  'restaurant': Icons.restaurant,
  'shopping_cart': Icons.shopping_cart,
  'build': Icons.build,
  'people': Icons.people,
  'receipt_long': Icons.receipt_long,
  'local_parking': Icons.local_parking,
  'local_laundry_service': Icons.local_laundry_service,
  'room_service': Icons.room_service,
  'local_bar': Icons.local_bar,
  'spa': Icons.spa,
  'directions_car': Icons.directions_car,
  'monetization_on': Icons.monetization_on,
  'attach_money': Icons.attach_money,
  'category': Icons.category,
  'more_horiz': Icons.more_horiz,
};

/// Available colors for categories
const _availableColors = <String>[
  '#2E7D32', // Green
  '#C62828', // Red
  '#1565C0', // Blue
  '#EF6C00', // Orange
  '#6A1B9A', // Purple
  '#00838F', // Teal
  '#AD1457', // Pink
  '#4E342E', // Brown
  '#37474F', // Blue Grey
  '#9F8033', // Gold
  '#254634', // Heritage Green
  '#808080', // Grey
];

class _CategoryFormDialog extends StatefulWidget {
  final FinancialCategory? category;
  final EntryType entryType;
  final FinanceRepository repository;

  const _CategoryFormDialog({
    this.category,
    required this.entryType,
    required this.repository,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nameEnController;
  late String _selectedIcon;
  late String _selectedColor;
  late bool _isDefault;
  bool _saving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _nameEnController = TextEditingController(
      text: widget.category?.nameEn ?? '',
    );
    _selectedIcon = widget.category?.icon ?? 'category';
    _selectedColor = widget.category?.color ?? '#808080';
    _isDefault = widget.category?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = widget.entryType == EntryType.income;

    return AlertDialog(
      title: Text(
        _isEditing
            ? l10n.editCategory
            : isIncome
            ? l10n.addIncomeCategoryTitle
            : l10n.addExpenseCategoryTitle,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.categoryNameRequired,
                    hintText: l10n.categoryNameHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.pleaseEnterCategoryName;
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                AppSpacing.gapVerticalMd,

                // Name EN
                TextFormField(
                  controller: _nameEnController,
                  decoration: InputDecoration(
                    labelText: l10n.englishName,
                    hintText: l10n.exampleElectricityEn,
                    border: const OutlineInputBorder(),
                  ),
                ),
                AppSpacing.gapVerticalLg,

                // Icon picker
                Text(
                  l10n.iconLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                AppSpacing.gapVerticalSm,
                _buildIconPicker(),
                AppSpacing.gapVerticalLg,

                // Color picker
                Text(
                  l10n.colorLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                AppSpacing.gapVerticalSm,
                _buildColorPicker(),
                AppSpacing.gapVerticalMd,

                // Preview
                _buildPreview(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? l10n.save : l10n.create),
        ),
      ],
    );
  }

  Widget _buildIconPicker() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _availableIcons.entries.map((entry) {
        final isSelected = _selectedIcon == entry.key;
        return InkWell(
          onTap: () => setState(() => _selectedIcon = entry.key),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              entry.value,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableColors.map((hex) {
        final isSelected = _selectedColor == hex;
        final color = _hexToColor(hex);
        return InkWell(
          onTap: () => setState(() => _selectedColor = hex),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview() {
    final l10n = AppLocalizations.of(context)!;
    final previewColor = _hexToColor(_selectedColor);
    final previewIcon = _availableIcons[_selectedIcon] ?? Icons.category;
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : l10n.categoryNamePlaceholder;

    return Container(
      padding: AppSpacing.paddingAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: previewColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(previewIcon, color: previewColor, size: 22),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.previewLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final hexColor = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (_) {
      return AppColors.mutedAccent;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await widget.repository.updateCategory(
          widget.category!.id,
          name: _nameController.text.trim(),
          nameEn: _nameEnController.text.trim().isEmpty
              ? null
              : _nameEnController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          isDefault: _isDefault,
        );
      } else {
        await widget.repository.createCategory(
          name: _nameController.text.trim(),
          categoryType: widget.entryType,
          nameEn: _nameEnController.text.trim().isEmpty
              ? null
              : _nameEnController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          isDefault: _isDefault,
        );
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context, true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? l10n.categoryUpdatedMsg : l10n.categoryCreatedMsg,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
