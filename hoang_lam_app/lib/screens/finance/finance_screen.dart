import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_card.dart';

/// Finance screen with transactions and reports
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.finance),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              // TODO: Navigate to reports
            },
            tooltip: 'Báo cáo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Monthly summary
          _buildMonthlySummary(context, l10n),

          // Filter tabs
          _buildFilterTabs(context, l10n),

          // Transaction list
          Expanded(
            child: _buildTransactionList(context),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'expense',
            onPressed: () {
              // TODO: Add expense
            },
            backgroundColor: AppColors.expense,
            child: const Icon(Icons.remove),
          ),
          AppSpacing.gapVerticalSm,
          FloatingActionButton.extended(
            heroTag: 'income',
            onPressed: () {
              // TODO: Add income
            },
            backgroundColor: AppColors.income,
            icon: const Icon(Icons.add),
            label: const Text('Thu'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: AppColors.primary,
      padding: AppSpacing.paddingAll,
      child: Column(
        children: [
          Text(
            'Tháng 1, 2026',
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
                value: 45600000,
                isIncome: true,
              ),
              Container(
                height: 40,
                width: 1,
                color: AppColors.onPrimary.withValues(alpha: 0.3),
              ),
              _buildSummaryItem(
                label: l10n.expense,
                value: 12350000,
                isIncome: false,
              ),
              Container(
                height: 40,
                width: 1,
                color: AppColors.onPrimary.withValues(alpha: 0.3),
              ),
              _buildSummaryItem(
                label: l10n.profit,
                value: 33250000,
                isProfit: true,
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // Profit margin bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: 0.73,
              backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
              minHeight: 8,
            ),
          ),
          AppSpacing.gapVerticalXs,
          Text(
            '73% lợi nhuận',
            style: TextStyle(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
          _buildFilterTab('all', 'Tất cả'),
          _buildFilterTab('income', l10n.income),
          _buildFilterTab('expense', l10n.expense),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String type, String label) {
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

  Widget _buildTransactionList(BuildContext context) {
    // Sample data
    final transactions = [
      _TransactionItem(
        type: 'income',
        category: 'Tiền phòng',
        description: '103 Check-out',
        amount: 800000,
        time: DateTime.now().subtract(const Duration(hours: 2)),
        paymentMethod: 'Tiền mặt',
      ),
      _TransactionItem(
        type: 'expense',
        category: 'Vật tư phòng',
        description: 'Khăn tắm',
        amount: 150000,
        time: DateTime.now().subtract(const Duration(hours: 5)),
        paymentMethod: 'Tiền mặt',
      ),
      _TransactionItem(
        type: 'income',
        category: 'Tiền phòng',
        description: '201 Deposit',
        amount: 1200000,
        time: DateTime.now().subtract(const Duration(days: 1)),
        paymentMethod: 'Chuyển khoản',
      ),
      _TransactionItem(
        type: 'expense',
        category: 'Tiền điện',
        description: 'Tháng 12/2025',
        amount: 2500000,
        time: DateTime.now().subtract(const Duration(days: 2)),
        paymentMethod: 'Chuyển khoản',
      ),
    ];

    // Filter transactions
    final filtered = _filterType == 'all'
        ? transactions
        : transactions.where((t) => t.type == _filterType).toList();

    // Group by date
    final groups = <String, List<_TransactionItem>>{};
    for (final t in filtered) {
      final key = _getDateKey(t.time);
      groups.putIfAbsent(key, () => []).add(t);
    }

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
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hôm nay';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildTransactionCard(BuildContext context, _TransactionItem item) {
    final isIncome = item.type == 'income';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () {
        // TODO: Show transaction detail
      },
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
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
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
                  item.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${item.description} • ${item.paymentMethod}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.formatCompact(item.amount)}',
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
}

class _TransactionItem {
  final String type;
  final String category;
  final String description;
  final num amount;
  final DateTime time;
  final String paymentMethod;

  _TransactionItem({
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.time,
    required this.paymentMethod,
  });
}
