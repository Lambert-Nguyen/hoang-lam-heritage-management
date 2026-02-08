import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Report screen with analytics and charts
/// Phase 4 - Reports & Analytics Frontend
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(reportScreenStateProvider);
    final notifier = ref.read(reportScreenStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context, state, notifier),
            tooltip: l10n.selectDate,
          ),
          PopupMenuButton<ExportFormat>(
            icon: const Icon(Icons.download),
            tooltip: 'Xuất báo cáo',
            onSelected: (format) => _exportReport(context, ref, format),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ExportFormat.xlsx,
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: AppSpacing.sm),
                    Text('Excel (XLSX)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ExportFormat.csv,
                child: Row(
                  children: [
                    Icon(Icons.text_snippet),
                    SizedBox(width: AppSpacing.sm),
                    Text('CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range display
          _buildDateRangeHeader(context, state, notifier),

          // Quick date range buttons
          _buildQuickDateButtons(context, notifier),

          // Report type selector
          _buildReportTypeSelector(context, state, notifier),

          // Report content
          Expanded(
            child: _buildReportContent(context, ref, state),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader(
    BuildContext context,
    ReportScreenState state,
    ReportScreenNotifier notifier,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      color: AppColors.primary,
      padding: AppSpacing.paddingAll,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, color: AppColors.onPrimary, size: 18),
          AppSpacing.gapHorizontalSm,
          Text(
            '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButtons(
    BuildContext context,
    ReportScreenNotifier notifier,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _QuickDateButton(
            label: '7 ngày',
            onPressed: () {
              final now = DateTime.now();
              notifier.setDateRange(
                now.subtract(const Duration(days: 7)),
                now,
              );
            },
          ),
          _QuickDateButton(
            label: '30 ngày',
            onPressed: notifier.setLast30Days,
          ),
          _QuickDateButton(
            label: 'Tháng này',
            onPressed: notifier.setThisMonth,
          ),
          _QuickDateButton(
            label: 'Tháng trước',
            onPressed: notifier.setLastMonth,
          ),
          _QuickDateButton(
            label: '90 ngày',
            onPressed: notifier.setLast90Days,
          ),
          _QuickDateButton(
            label: 'Năm nay',
            onPressed: notifier.setThisYear,
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector(
    BuildContext context,
    ReportScreenState state,
    ReportScreenNotifier notifier,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: ReportType.values.map((type) {
          final isSelected = state.selectedReportType == type;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                  ),
                  AppSpacing.gapHorizontalXs,
                  Text(type.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => notifier.setReportType(type),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    WidgetRef ref,
    ReportScreenState state,
  ) {
    switch (state.selectedReportType) {
      case ReportType.occupancy:
        return _OccupancyReportContent();
      case ReportType.revenue:
        return _RevenueReportContent();
      case ReportType.expenses:
        return _ExpenseReportContent();
      case ReportType.kpi:
        return _KPIReportContent();
      case ReportType.channels:
        return _ChannelReportContent();
      case ReportType.demographics:
        return _DemographicsReportContent();
    }
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    ReportScreenState state,
    ReportScreenNotifier notifier,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state.startDate,
        end: state.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      notifier.setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _exportReport(
    BuildContext context,
    WidgetRef ref,
    ExportFormat format,
  ) async {
    final notifier = ref.read(reportScreenStateProvider.notifier);
    final result = await notifier.exportReport(format);

    if (context.mounted) {
      if (result != null) {
        try {
          final dir = await getTemporaryDirectory();
          final extension = format == ExportFormat.xlsx ? 'xlsx' : 'csv';
          final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
          final fileName = 'report_$timestamp.$extension';
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(result);

          await SharePlus.instance.share(
            ShareParams(files: [XFile(file.path)]),
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi lưu file: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else {
        final state = ref.read(reportScreenStateProvider);
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ==================== Quick Date Button ====================

class _QuickDateButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickDateButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ActionChip(
        label: Text(label),
        onPressed: onPressed,
        backgroundColor: AppColors.surfaceVariant,
      ),
    );
  }
}

// ==================== Occupancy Report Content ====================

class _OccupancyReportContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentOccupancyReportProvider);

    return reportAsync.when(
      data: (reports) => _buildOccupancyList(context, reports),
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        message: 'Lỗi tải báo cáo: $error',
        onRetry: () => ref.invalidate(currentOccupancyReportProvider),
      ),
    );
  }

  Widget _buildOccupancyList(BuildContext context, List<OccupancyReport> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu trong khoảng thời gian này'),
      );
    }

    // Calculate summary
    final avgOccupancy = reports.fold<double>(0, (sum, r) => sum + r.occupancyRate) / reports.length;
    final totalRevenue = reports.fold<double>(0, (sum, r) => sum + r.revenue);

    return CustomScrollView(
      slivers: [
        // Summary card
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.paddingAll,
            child: AppCard(
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Công suất trung bình',
                    value: '${avgOccupancy.toStringAsFixed(1)}%',
                    icon: Icons.hotel,
                    color: avgOccupancy >= 70 ? AppColors.success : AppColors.warning,
                  ),
                  const Divider(),
                  _SummaryRow(
                    label: 'Tổng doanh thu',
                    value: CurrencyFormatter.formatVND(totalRevenue),
                    icon: Icons.attach_money,
                    color: AppColors.income,
                  ),
                ],
              ),
            ),
          ),
        ),

        // List of reports
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final report = reports[index];
              return _OccupancyReportTile(report: report);
            },
            childCount: reports.length,
          ),
        ),
      ],
    );
  }
}

class _OccupancyReportTile extends StatelessWidget {
  final OccupancyReport report;

  const _OccupancyReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: report.occupancyRate >= 70
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.warning.withValues(alpha: 0.2),
        child: Text(
          '${report.occupancyRate.toInt()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: report.occupancyRate >= 70 ? AppColors.success : AppColors.warning,
          ),
        ),
      ),
      title: Text(report.date ?? report.period ?? 'N/A'),
      subtitle: Text(
        '${report.occupiedRooms}/${report.totalRooms} phòng • ${CurrencyFormatter.formatVND(report.revenue)}',
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

// ==================== Revenue Report Content ====================

class _RevenueReportContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentRevenueReportProvider);

    return reportAsync.when(
      data: (reports) => _buildRevenueList(context, reports),
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        message: 'Lỗi tải báo cáo: $error',
        onRetry: () => ref.invalidate(currentRevenueReportProvider),
      ),
    );
  }

  Widget _buildRevenueList(BuildContext context, List<RevenueReport> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu trong khoảng thời gian này'),
      );
    }

    // Calculate totals
    final totalRevenue = reports.fold<double>(0, (sum, r) => sum + r.totalRevenue);
    final totalExpenses = reports.fold<double>(0, (sum, r) => sum + r.totalExpenses);
    final netProfit = totalRevenue - totalExpenses;

    return CustomScrollView(
      slivers: [
        // Summary cards
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.paddingAll,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Doanh thu',
                        value: CurrencyFormatter.formatVND(totalRevenue),
                        icon: Icons.arrow_downward,
                        color: AppColors.income,
                      ),
                    ),
                    AppSpacing.gapHorizontalMd,
                    Expanded(
                      child: _MetricCard(
                        label: 'Chi phí',
                        value: CurrencyFormatter.formatVND(totalExpenses),
                        icon: Icons.arrow_upward,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapVerticalMd,
                _MetricCard(
                  label: 'Lợi nhuận',
                  value: CurrencyFormatter.formatVND(netProfit),
                  icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: netProfit >= 0 ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
        ),

        // List of reports
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final report = reports[index];
              return _RevenueReportTile(report: report);
            },
            childCount: reports.length,
          ),
        ),
      ],
    );
  }
}

class _RevenueReportTile extends StatelessWidget {
  final RevenueReport report;

  const _RevenueReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: report.netProfit >= 0
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.error.withValues(alpha: 0.2),
        child: Icon(
          report.netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
          color: report.netProfit >= 0 ? AppColors.success : AppColors.error,
        ),
      ),
      title: Text(report.date ?? report.period ?? 'N/A'),
      subtitle: Text(
        'DT: ${CurrencyFormatter.formatCompact(report.totalRevenue)} • LN: ${CurrencyFormatter.formatCompact(report.netProfit)}',
      ),
      trailing: Text(
        '${report.profitMargin.toStringAsFixed(1)}%',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: report.profitMargin >= 0 ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

// ==================== KPI Report Content ====================

class _KPIReportContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentKPIReportProvider);

    return reportAsync.when(
      data: (report) => _buildKPIContent(context, report),
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        message: 'Lỗi tải báo cáo: $error',
        onRetry: () => ref.invalidate(currentKPIReportProvider),
      ),
    );
  }

  Widget _buildKPIContent(BuildContext context, KPIReport report) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main KPIs
          Text(
            'Chỉ số chính',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          Row(
            children: [
              Expanded(
                child: _KPICard(
                  label: 'RevPAR',
                  value: CurrencyFormatter.formatVND(report.revpar),
                  change: report.revparChange,
                  tooltip: 'Revenue Per Available Room',
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: _KPICard(
                  label: 'ADR',
                  value: CurrencyFormatter.formatVND(report.adr),
                  change: report.adrChange,
                  tooltip: 'Average Daily Rate',
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Row(
            children: [
              Expanded(
                child: _KPICard(
                  label: 'Công suất',
                  value: '${report.occupancyRate.toStringAsFixed(1)}%',
                  change: report.occupancyChange,
                  tooltip: 'Occupancy Rate',
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: _KPICard(
                  label: 'Lợi nhuận',
                  value: CurrencyFormatter.formatCompact(report.netProfit),
                  change: report.revenueChange,
                  tooltip: 'Net Profit',
                ),
              ),
            ],
          ),

          AppSpacing.gapVerticalLg,

          // Detailed stats
          Text(
            'Chi tiết',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Tổng đêm phòng khả dụng',
                  value: '${report.totalRoomNightsAvailable}',
                ),
                const Divider(),
                _DetailRow(
                  label: 'Tổng đêm phòng bán',
                  value: '${report.totalRoomNightsSold}',
                ),
                const Divider(),
                _DetailRow(
                  label: 'Doanh thu phòng',
                  value: CurrencyFormatter.formatVND(report.totalRoomRevenue),
                ),
                const Divider(),
                _DetailRow(
                  label: 'Tổng doanh thu',
                  value: CurrencyFormatter.formatVND(report.totalRevenue),
                ),
                const Divider(),
                _DetailRow(
                  label: 'Tổng chi phí',
                  value: CurrencyFormatter.formatVND(report.totalExpenses),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final double? change;
  final String tooltip;

  const _KPICard({
    required this.label,
    required this.value,
    this.change,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            AppSpacing.gapVerticalXs,
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (change != null) ...[
              AppSpacing.gapVerticalXs,
              Row(
                children: [
                  Icon(
                    change! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: change! >= 0 ? AppColors.success : AppColors.error,
                  ),
                  Text(
                    '${change!.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: change! >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== Expense Report Content ====================

class _ExpenseReportContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentExpenseReportProvider);

    return reportAsync.when(
      data: (reports) => _buildExpenseList(context, reports),
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        message: 'Lỗi tải báo cáo: $error',
        onRetry: () => ref.invalidate(currentExpenseReportProvider),
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, List<ExpenseReport> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('Không có chi phí trong khoảng thời gian này'),
      );
    }

    final total = reports.fold<double>(0, (sum, r) => sum + r.totalAmount);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.paddingAll,
            child: _MetricCard(
              label: 'Tổng chi phí',
              value: CurrencyFormatter.formatVND(total),
              icon: Icons.money_off,
              color: AppColors.expense,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final report = reports[index];
              return _ExpenseReportTile(report: report);
            },
            childCount: reports.length,
          ),
        ),
      ],
    );
  }
}

class _ExpenseReportTile extends StatelessWidget {
  final ExpenseReport report;

  const _ExpenseReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: report.colorValue.withValues(alpha: 0.2),
        child: Icon(report.iconData, color: report.colorValue),
      ),
      title: Text(report.categoryName),
      subtitle: Text('${report.transactionCount} giao dịch'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.formatCompact(report.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${report.percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// ==================== Channel Report Content ====================

class _ChannelReportContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentChannelPerformanceProvider);

    return reportAsync.when(
      data: (channels) => _buildChannelList(context, channels),
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        message: 'Lỗi tải báo cáo: $error',
        onRetry: () => ref.invalidate(currentChannelPerformanceProvider),
      ),
    );
  }

  Widget _buildChannelList(BuildContext context, List<ChannelPerformance> channels) {
    if (channels.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu trong khoảng thời gian này'),
      );
    }

    final totalRevenue = channels.fold<double>(0, (sum, c) => sum + c.totalRevenue);
    final totalBookings = channels.fold<int>(0, (sum, c) => sum + c.bookingCount);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.paddingAll,
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Tổng doanh thu',
                    value: CurrencyFormatter.formatVND(totalRevenue),
                    icon: Icons.attach_money,
                    color: AppColors.income,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: _MetricCard(
                    label: 'Tổng đặt phòng',
                    value: '$totalBookings',
                    icon: Icons.book_online,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final channel = channels[index];
              return _ChannelPerformanceTile(channel: channel);
            },
            childCount: channels.length,
          ),
        ),
      ],
    );
  }
}

class _ChannelPerformanceTile extends StatelessWidget {
  final ChannelPerformance channel;

  const _ChannelPerformanceTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: channel.isHighPerforming
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.surfaceVariant,
        child: Icon(
          Icons.source,
          color: channel.isHighPerforming ? AppColors.success : AppColors.textSecondary,
        ),
      ),
      title: Text(channel.sourceDisplay),
      subtitle: Text(
        '${channel.bookingCount} đặt phòng • ${channel.totalNights} đêm',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.formatCompact(channel.totalRevenue),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${channel.percentageOfRevenue.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: channel.isHighPerforming ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Demographics Report Content ====================

class _DemographicsReportContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentGuestDemographicsProvider);

    return reportAsync.when(
      data: (demographics) => _buildDemographicsList(context, demographics),
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        message: 'Lỗi tải báo cáo: $error',
        onRetry: () => ref.invalidate(currentGuestDemographicsProvider),
      ),
    );
  }

  Widget _buildDemographicsList(BuildContext context, List<GuestDemographics> demographics) {
    if (demographics.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu trong khoảng thời gian này'),
      );
    }

    final totalGuests = demographics.fold<int>(0, (sum, d) => sum + d.guestCount);
    final totalRevenue = demographics.fold<double>(0, (sum, d) => sum + d.totalRevenue);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.paddingAll,
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Tổng khách',
                    value: '$totalGuests',
                    icon: Icons.people,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: _MetricCard(
                    label: 'Tổng doanh thu',
                    value: CurrencyFormatter.formatVND(totalRevenue),
                    icon: Icons.attach_money,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final demo = demographics[index];
              return _DemographicsTile(demographics: demo);
            },
            childCount: demographics.length,
          ),
        ),
      ],
    );
  }
}

class _DemographicsTile extends StatelessWidget {
  final GuestDemographics demographics;

  const _DemographicsTile({required this.demographics});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          demographics.nationality.substring(0, 2).toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      title: Text(demographics.nationality),
      subtitle: Text(
        '${demographics.guestCount} khách • ${demographics.bookingCount} đặt phòng • TB ${demographics.averageStay.toStringAsFixed(1)} đêm',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.formatCompact(demographics.totalRevenue),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${demographics.percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// ==================== Helper Widgets ====================

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, color: color),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.gapHorizontalSm,
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
