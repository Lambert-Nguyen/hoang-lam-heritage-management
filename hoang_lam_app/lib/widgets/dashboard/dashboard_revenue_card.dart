import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dashboard.dart';
import '../common/app_card.dart';

/// Dashboard revenue card showing today's financial summary
class DashboardRevenueCard extends StatelessWidget {
  final TodaySummary todaySummary;
  final double? todayRevenue;
  final double? todayExpense;

  const DashboardRevenueCard({
    super.key,
    required this.todaySummary,
    this.todayRevenue,
    this.todayExpense,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final revenue = todayRevenue ?? 0.0;
    final expense = todayExpense ?? 0.0;
    final net = revenue - expense;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppColors.income,
                size: AppSpacing.iconMd,
              ),
              AppSpacing.gapHorizontalSm,
              Text(
                l10n.todayRevenue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.formatVND(revenue),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.income,
                      ),
                    ),
                    AppSpacing.gapVerticalXs,
                    if (expense > 0)
                      Text(
                        '${l10n.expense}: ${CurrencyFormatter.formatVND(expense)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.expense,
                        ),
                      ),
                  ],
                ),
              ),
              if (net != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: (net > 0 ? AppColors.income : AppColors.expense)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    '${net > 0 ? '+' : ''}${CurrencyFormatter.formatCompact(net)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: net > 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
