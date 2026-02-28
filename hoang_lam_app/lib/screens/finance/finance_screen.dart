import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../providers/finance_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../core/utils/error_utils.dart';
import '../../widgets/finance/finance_chart.dart';

/// Finance screen with transactions and reports
/// Phase 2.3 - Financial Management Frontend
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  EntryType? _filterType;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final monthlySummaryAsync = ref.watch(currentMonthSummaryProvider);
    final filter = FinancialEntryFilter(
      entryType: _filterType,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
    final entriesAsync = ref.watch(filteredEntriesProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.finance),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _navigateToReports,
            tooltip: l10n.reports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Monthly summary
          _buildMonthlySummary(context, l10n, monthlySummaryAsync),

          // Weekly chart (GAP-012 fix)
          _buildChart(monthlySummaryAsync),

          // Filter tabs
          _buildFilterTabs(context, l10n),

          // Date range filter
          _buildDateRangeBar(l10n),

          // Transaction list takes remaining space
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: _buildTransactionList(context, entriesAsync),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.addEntry),
      ),
    );
  }

  Future<void> _refreshData() async {
    // Invalidate all finance providers to refresh
    ref.invalidate(currentMonthSummaryProvider);
    ref.invalidate(financialEntriesProvider);
    ref.invalidate(financialCategoriesProvider);
    // Wait for the providers to actually reload
    await Future.wait([
      ref.read(currentMonthSummaryProvider.future),
      ref.read(financialEntriesProvider.future),
    ]);
  }

  void _showAddEntrySheet(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.arrow_downward, color: AppColors.income),
              title: Text(l10n.addIncome),
              onTap: () {
                Navigator.pop(context);
                _navigateToForm(EntryType.income);
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_upward, color: AppColors.expense),
              title: Text(l10n.addExpense),
              onTap: () {
                Navigator.pop(context);
                _navigateToForm(EntryType.expense);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToForm(EntryType type) async {
    final result = await context.push<bool>(
      AppRoutes.financeForm,
      extra: {'entryType': type},
    );
    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToReports() {
    context.push(AppRoutes.reports);
  }

  Widget _buildChart(AsyncValue<MonthlyFinancialSummary> summaryAsync) {
    return summaryAsync.when(
      data: (summary) {
        if (summary.dailyTotals.isEmpty) {
          return const SizedBox.shrink();
        }
        return FinanceChart(dailyTotals: summary.dailyTotals);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
            getLocalizedErrorMessage(error, l10n),
            style: const TextStyle(color: AppColors.onPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(
    AppLocalizations l10n,
    MonthlyFinancialSummary summary,
  ) {
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
          style: const TextStyle(color: AppColors.onPrimary, fontSize: 14),
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
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.onPrimary,
            ),
            minHeight: 8,
          ),
        ),
        AppSpacing.gapVerticalXs,
        Text(
          '${profitMargin.toStringAsFixed(0)}% ${l10n.profit}',
          style: TextStyle(
            color: AppColors.onPrimary.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getMonthYearText(int month, int year) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(DateTime(year, month));
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
          '${isIncome
              ? '+'
              : isProfit
              ? ''
              : '-'}${CurrencyFormatter.formatCompact(value)}',
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
          _buildFilterTab(null, l10n.all),
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

  Widget _buildDateRangeBar(AppLocalizations l10n) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final hasFilter = _dateFrom != null || _dateTo != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasFilter
                        ? AppColors.primary
                        : AppColors.textHint.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  hasFilter
                      ? '${_dateFrom != null ? dateFormat.format(_dateFrom!) : '...'}'
                          ' – '
                          '${_dateTo != null ? dateFormat.format(_dateTo!) : '...'}'
                      : l10n.dateRange,
                  style: TextStyle(
                    color: hasFilter
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () => setState(() {
                _dateFrom = null;
                _dateTo = null;
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
    }
  }

  Widget _buildTransactionList(
    BuildContext context,
    AsyncValue<List<FinancialEntryListItem>> entriesAsync,
  ) {
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      AppSpacing.gapVerticalMd,
                      Text(
                        context.l10n.noData,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Group entries by date
        final groups = _groupEntriesByDate(entries);

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
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
        message: getLocalizedErrorMessage(error, context.l10n),
        onRetry: _refreshData,
      ),
    );
  }

  Map<String, List<FinancialEntryListItem>> _groupEntriesByDate(
    List<FinancialEntryListItem> entries,
  ) {
    final groups = <String, List<FinancialEntryListItem>>{};
    for (final entry in entries) {
      final key = _getDateKey(entry.date);
      groups.putIfAbsent(key, () => []).add(entry);
    }
    return groups;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final l10n = context.l10n;

    if (dateOnly == today) return l10n.today;
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return l10n.yesterday;
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildTransactionCard(
    BuildContext context,
    FinancialEntryListItem entry,
  ) {
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
              entry.iconData,
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
                  entry.categoryName ?? context.l10n.noData,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${entry.description.isNotEmpty ? entry.description : context.l10n.noData} • ${entry.paymentMethod.localizedName(context.l10n)}',
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

  Future<void> _showEntryDetail(FinancialEntryListItem listItem) async {
    // Fetch full entry details
    final entry = await ref.read(
      financialEntryByIdProvider(listItem.id).future,
    );
    if (!mounted) return;

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

  Future<void> _editEntry(FinancialEntry entry) async {
    final result = await context.push<bool>(
      AppRoutes.financeForm,
      extra: {'entryType': entry.entryType, 'entry': entry},
    );
    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _deleteEntry(FinancialEntry entry) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text('${l10n.areYouSure} "${entry.categoryName ?? ""}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(financeNotifierProvider.notifier).deleteEntry(entry.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getLocalizedErrorMessage(e, context.l10n))));
        }
      }
    }
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
                  entry.categoryIcon ??
                      (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
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
                      entry.categoryName ?? context.l10n.noData,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isIncome ? context.l10n.income : context.l10n.expense,
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
          _buildDetailRow(
            context.l10n.description,
            entry.description.isNotEmpty ? entry.description : '-',
          ),
          _buildDetailRow(
            context.l10n.dateLabel,
            dateFormat.format(entry.entryDate),
          ),
          _buildDetailRow(
            context.l10n.paymentMethod,
            entry.paymentMethod.localizedName(context.l10n),
          ),
          if (entry.reference.isNotEmpty)
            _buildDetailRow(context.l10n.referenceCode, entry.reference),
          if (entry.notes.isNotEmpty)
            _buildDetailRow(context.l10n.notes, entry.notes),

          AppSpacing.gapVerticalLg,

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: Builder(builder: (context) => Text(context.l10n.edit)),
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  label: Builder(
                    builder: (context) => Text(
                      context.l10n.delete,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
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
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
