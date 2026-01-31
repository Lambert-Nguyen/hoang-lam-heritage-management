import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';
import 'finance_form_screen.dart';

/// Finance screen with transactions and reports
/// Phase 2.3 - Financial Management Frontend
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  EntryType? _filterType;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final monthlySummaryAsync = ref.watch(currentMonthSummaryProvider);
    final entriesAsync = ref.watch(filteredEntriesProvider(_filterType));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.finance),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Lọc',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _navigateToReports,
            tooltip: 'Báo cáo',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Monthly summary
            _buildMonthlySummary(context, l10n, monthlySummaryAsync),

            // Filter tabs
            _buildFilterTabs(context, l10n),

            // Transaction list
            Expanded(
              child: _buildTransactionList(context, entriesAsync),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'expense',
            onPressed: () => _navigateToForm(EntryType.expense),
            backgroundColor: AppColors.expense,
            child: const Icon(Icons.remove, color: Colors.white),
          ),
          AppSpacing.gapVerticalSm,
          FloatingActionButton.extended(
            heroTag: 'income',
            onPressed: () => _navigateToForm(EntryType.income),
            backgroundColor: AppColors.income,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Thu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    // Invalidate all finance providers to refresh
    ref.invalidate(currentMonthSummaryProvider);
    ref.invalidate(financialEntriesProvider);
    ref.invalidate(financialCategoriesProvider);
    // Wait a bit for the UI to update
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _navigateToForm(EntryType type) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FinanceFormScreen(entryType: type),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToReports() {
    // TODO: Navigate to reports screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo sẽ được triển khai sau')),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        currentFilter: _filterType,
        onFilterChanged: (type) {
          setState(() => _filterType = type);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildMonthlySummary(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<MonthlyFinancialSummary> summaryAsync,
  ) {
    return Container(
      color: AppColors.primary,
      padding: AppSpacing.paddingAll,
      child: summaryAsync.when(
        data: (summary) => _buildSummaryContent(l10n, summary),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(color: AppColors.onPrimary),
          ),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Lỗi tải dữ liệu: $error',
            style: const TextStyle(color: AppColors.onPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(AppLocalizations l10n, MonthlyFinancialSummary summary) {
    final profitMargin = summary.totalIncome > 0
        ? (summary.netBalance / summary.totalIncome * 100)
        : 0.0;
    final profitRatio = summary.totalIncome > 0
        ? (summary.netBalance / summary.totalIncome).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Text(
          _getMonthYearText(summary.month, summary.year),
          style: const TextStyle(
            color: AppColors.onPrimary,
            fontSize: 14,
          ),
        ),
        AppSpacing.gapVerticalMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryItem(
              label: l10n.income,
              value: summary.totalIncome,
              isIncome: true,
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.onPrimary.withValues(alpha: 0.3),
            ),
            _buildSummaryItem(
              label: l10n.expense,
              value: summary.totalExpense,
              isIncome: false,
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.onPrimary.withValues(alpha: 0.3),
            ),
            _buildSummaryItem(
              label: l10n.profit,
              value: summary.netBalance,
              isProfit: true,
            ),
          ],
        ),
        AppSpacing.gapVerticalMd,
        // Profit margin bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: LinearProgressIndicator(
            value: profitRatio,
            backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
            minHeight: 8,
          ),
        ),
        AppSpacing.gapVerticalXs,
        Text(
          '${profitMargin.toStringAsFixed(0)}% lợi nhuận',
          style: TextStyle(
            color: AppColors.onPrimary.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getMonthYearText(int month, int year) {
    return 'Tháng $month, $year';
  }

  Widget _buildSummaryItem({
    required String label,
    required num value,
    bool isIncome = false,
    bool isProfit = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.onPrimary.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        AppSpacing.gapVerticalXs,
        Text(
          '${isIncome ? '+' : isProfit ? '' : '-'}${CurrencyFormatter.formatCompact(value)}',
          style: const TextStyle(
            color: AppColors.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          _buildFilterTab(null, 'Tất cả'),
          _buildFilterTab(EntryType.income, l10n.income),
          _buildFilterTab(EntryType.expense, l10n.expense),
        ],
      ),
    );
  }

  Widget _buildFilterTab(EntryType? type, String label) {
    final isSelected = _filterType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filterType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    AsyncValue<List<FinancialEntry>> entriesAsync,
  ) {
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                AppSpacing.gapVerticalMd,
                const Text(
                  'Chưa có giao dịch',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // Group entries by date
        final groups = _groupEntriesByDate(entries);

        return ListView.builder(
          padding: AppSpacing.paddingScreen,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final key = groups.keys.elementAt(index);
            final items = groups[key]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapVerticalSm,
                ...items.map((item) => _buildTransactionCard(context, item)),
                AppSpacing.gapVerticalMd,
              ],
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorDisplay(
        message: 'Lỗi tải dữ liệu giao dịch: $error',
        onRetry: _refreshData,
      ),
    );
  }

  Map<String, List<FinancialEntry>> _groupEntriesByDate(List<FinancialEntry> entries) {
    final groups = <String, List<FinancialEntry>>{};
    for (final entry in entries) {
      final key = _getDateKey(entry.entryDate);
      groups.putIfAbsent(key, () => []).add(entry);
    }
    return groups;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hôm nay';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildTransactionCard(BuildContext context, FinancialEntry entry) {
    final isIncome = entry.entryType == EntryType.income;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () => _showEntryDetail(entry),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.income : AppColors.expense)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.categoryIcon ?? (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
              color: isIncome ? AppColors.income : AppColors.expense,
              size: 20,
            ),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.categoryName ?? 'Không phân loại',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${entry.description.isNotEmpty ? entry.description : "Không có mô tả"} • ${entry.paymentMethod.displayName}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.formatCompact(entry.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  void _showEntryDetail(FinancialEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EntryDetailSheet(
        entry: entry,
        onEdit: () {
          Navigator.pop(context);
          _editEntry(entry);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteEntry(entry);
        },
      ),
    );
  }

  void _editEntry(FinancialEntry entry) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FinanceFormScreen(
          entryType: entry.entryType,
          entry: entry,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _deleteEntry(FinancialEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa giao dịch "${entry.categoryName ?? "này"}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(financeNotifierProvider.notifier).deleteEntry(entry.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa giao dịch')),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa giao dịch: $e')),
          );
        }
      }
    }
  }
}

/// Filter bottom sheet
class _FilterBottomSheet extends StatelessWidget {
  final EntryType? currentFilter;
  final Function(EntryType?) onFilterChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingAll,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lọc theo loại',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapVerticalMd,
          _buildOption(context, null, 'Tất cả', Icons.list),
          _buildOption(context, EntryType.income, 'Thu', Icons.arrow_downward),
          _buildOption(context, EntryType.expense, 'Chi', Icons.arrow_upward),
          AppSpacing.gapVerticalMd,
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, EntryType? type, String label, IconData icon) {
    final isSelected = currentFilter == type;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () => onFilterChanged(type),
    );
  }
}

/// Entry detail bottom sheet
class _EntryDetailSheet extends StatelessWidget {
  final FinancialEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryDetailSheet({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.entryType == EntryType.income;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: AppSpacing.paddingAll,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.categoryIcon ?? (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                  color: isIncome ? AppColors.income : AppColors.expense,
                  size: 24,
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.categoryName ?? 'Không phân loại',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isIncome ? 'Thu' : 'Chi',
                      style: TextStyle(
                        color: isIncome ? AppColors.income : AppColors.expense,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(entry.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalLg,

          // Details
          _buildDetailRow('Mô tả', entry.description.isNotEmpty ? entry.description : '-'),
          _buildDetailRow('Ngày', dateFormat.format(entry.entryDate)),
          _buildDetailRow('Phương thức', entry.paymentMethod.displayName),
          if (entry.reference.isNotEmpty)
            _buildDetailRow('Mã tham chiếu', entry.reference),
          if (entry.notes.isNotEmpty)
            _buildDetailRow('Ghi chú', entry.notes),

          AppSpacing.gapVerticalLg,

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Sửa'),
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  label: const Text('Xóa', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
