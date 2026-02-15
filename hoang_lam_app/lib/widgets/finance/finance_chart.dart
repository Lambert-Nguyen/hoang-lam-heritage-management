import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';

/// Weekly income/expense bar chart for finance dashboard
/// Design Plan: Section 6 - Financial Report Screen
class FinanceChart extends ConsumerWidget {
  final List<DailyTotals> dailyTotals;

  const FinanceChart({
    super.key,
    required this.dailyTotals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dailyTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by week and calculate weekly totals
    final weeklyData = _calculateWeeklyData();

    if (weeklyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: AppColors.primary,
                size: AppSpacing.iconMd,
              ),
              AppSpacing.gapHorizontalSm,
              Text(
                context.l10n.incomeExpenseChart,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(weeklyData),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        AppColors.surface.withValues(alpha: 0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${isIncome ? context.l10n.incomeLabel : context.l10n.expenseShort}: ${_formatCurrency(rod.toY)}',
                        TextStyle(
                          color: isIncome ? AppColors.income : AppColors.expense,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= weeklyData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            weeklyData[value.toInt()].label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCompactCurrency(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxY(weeklyData) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: _buildBarGroups(weeklyData),
              ),
            ),
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context.l10n.incomeLabel, AppColors.income),
              AppSpacing.gapHorizontalLg,
              _buildLegendItem(context.l10n.expenseShort, AppColors.expense),
            ],
          ),
        ),
        AppSpacing.gapVerticalMd,
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        AppSpacing.gapHorizontalXs,
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<_WeeklyData> _calculateWeeklyData() {
    if (dailyTotals.isEmpty) return [];

    // Sort by date
    final sorted = List<DailyTotals>.from(dailyTotals)
      ..sort((a, b) => a.day.compareTo(b.day));

    // Group by week
    final Map<int, _WeeklyData> weekMap = {};

    for (final summary in sorted) {
      final date = DateTime.tryParse(summary.day);
      if (date == null) continue;
      
      final weekNum = _getWeekOfMonth(date);
      if (!weekMap.containsKey(weekNum)) {
        weekMap[weekNum] = _WeeklyData(
          label: 'T$weekNum',
          income: 0,
          expense: 0,
        );
      }
      weekMap[weekNum] = _WeeklyData(
        label: weekMap[weekNum]!.label,
        income: weekMap[weekNum]!.income + summary.income,
        expense: weekMap[weekNum]!.expense + summary.expense,
      );
    }

    // Return up to 5 weeks
    return weekMap.values.take(5).toList();
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final dayOfMonth = date.day;
    return ((dayOfMonth + firstDayOfMonth.weekday - 1) / 7).ceil();
  }

  double _getMaxY(List<_WeeklyData> data) {
    double max = 0;
    for (final week in data) {
      if (week.income > max) max = week.income.toDouble();
      if (week.expense > max) max = week.expense.toDouble();
    }
    return max > 0 ? max * 1.2 : 1000000; // Add 20% padding
  }

  List<BarChartGroupData> _buildBarGroups(List<_WeeklyData> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final week = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: week.income.toDouble(),
            color: AppColors.income,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: week.expense.toDouble(),
            color: AppColors.expense,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,###', 'vi');
    return '${formatter.format(value)}đ';
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _WeeklyData {
  final String label;
  final num income;
  final num expense;

  _WeeklyData({
    required this.label,
    required this.income,
    required this.expense,
  });
}
