import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';
part 'report.g.dart';

/// Report grouping period
enum ReportGroupBy {
  @JsonValue('day')
  day,
  @JsonValue('week')
  week,
  @JsonValue('month')
  month,
}

/// Extension for ReportGroupBy display properties
extension ReportGroupByExtension on ReportGroupBy {
  String get displayName {
    switch (this) {
      case ReportGroupBy.day:
        return 'Ngày';
      case ReportGroupBy.week:
        return 'Tuần';
      case ReportGroupBy.month:
        return 'Tháng';
    }
  }

  String get displayNameEn {
    switch (this) {
      case ReportGroupBy.day:
        return 'Day';
      case ReportGroupBy.week:
        return 'Week';
      case ReportGroupBy.month:
        return 'Month';
    }
  }

  /// Convert to API value
  String get toApiValue => name;
}

/// Export format types
enum ExportFormat {
  @JsonValue('xlsx')
  xlsx,
  @JsonValue('csv')
  csv,
}

/// Extension for ExportFormat display properties
extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.xlsx:
        return 'Excel (XLSX)';
      case ExportFormat.csv:
        return 'CSV';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.xlsx:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ExportFormat.csv:
        return 'text/csv';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.xlsx:
        return 'xlsx';
      case ExportFormat.csv:
        return 'csv';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportFormat.xlsx:
        return Icons.table_chart;
      case ExportFormat.csv:
        return Icons.text_snippet;
    }
  }

  /// Convert to API value
  String get toApiValue => name;
}

/// Report type for export
enum ReportType {
  @JsonValue('occupancy')
  occupancy,
  @JsonValue('revenue')
  revenue,
  @JsonValue('expenses')
  expenses,
  @JsonValue('kpi')
  kpi,
  @JsonValue('channels')
  channels,
  @JsonValue('demographics')
  demographics,
}

/// Extension for ReportType display properties
extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.occupancy:
        return 'Công suất phòng';
      case ReportType.revenue:
        return 'Doanh thu';
      case ReportType.expenses:
        return 'Chi phí';
      case ReportType.kpi:
        return 'KPI';
      case ReportType.channels:
        return 'Kênh bán';
      case ReportType.demographics:
        return 'Khách hàng';
    }
  }

  String get displayNameEn {
    switch (this) {
      case ReportType.occupancy:
        return 'Occupancy';
      case ReportType.revenue:
        return 'Revenue';
      case ReportType.expenses:
        return 'Expenses';
      case ReportType.kpi:
        return 'KPI';
      case ReportType.channels:
        return 'Channels';
      case ReportType.demographics:
        return 'Demographics';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.occupancy:
        return Icons.hotel;
      case ReportType.revenue:
        return Icons.attach_money;
      case ReportType.expenses:
        return Icons.money_off;
      case ReportType.kpi:
        return Icons.trending_up;
      case ReportType.channels:
        return Icons.source;
      case ReportType.demographics:
        return Icons.people;
    }
  }

  /// Convert to API value
  String get toApiValue => name;
}

/// Comparison type for comparative reports
enum ComparisonType {
  @JsonValue('previous_period')
  previousPeriod,
  @JsonValue('previous_year')
  previousYear,
  @JsonValue('custom')
  custom,
}

/// Extension for ComparisonType
extension ComparisonTypeExtension on ComparisonType {
  String get displayName {
    switch (this) {
      case ComparisonType.previousPeriod:
        return 'Kỳ trước';
      case ComparisonType.previousYear:
        return 'Năm trước';
      case ComparisonType.custom:
        return 'Tùy chỉnh';
    }
  }

  String get toApiValue {
    switch (this) {
      case ComparisonType.previousPeriod:
        return 'previous_period';
      case ComparisonType.previousYear:
        return 'previous_year';
      case ComparisonType.custom:
        return 'custom';
    }
  }
}

/// Demographics group by options
enum DemographicsGroupBy {
  @JsonValue('nationality')
  nationality,
  @JsonValue('source')
  source,
  @JsonValue('room_type')
  roomType,
}

/// Extension for DemographicsGroupBy
extension DemographicsGroupByExtension on DemographicsGroupBy {
  String get displayName {
    switch (this) {
      case DemographicsGroupBy.nationality:
        return 'Quốc tịch';
      case DemographicsGroupBy.source:
        return 'Nguồn đặt';
      case DemographicsGroupBy.roomType:
        return 'Loại phòng';
    }
  }

  String get toApiValue {
    switch (this) {
      case DemographicsGroupBy.nationality:
        return 'nationality';
      case DemographicsGroupBy.source:
        return 'source';
      case DemographicsGroupBy.roomType:
        return 'room_type';
    }
  }
}

// ==================== OCCUPANCY REPORT ====================

/// Occupancy report data model
@freezed
sealed class OccupancyReport with _$OccupancyReport {
  const factory OccupancyReport({
    String? date,
    String? period, // For week/month grouping
    @JsonKey(name: 'total_rooms') required int totalRooms,
    @JsonKey(name: 'occupied_rooms') required int occupiedRooms,
    @JsonKey(name: 'available_rooms') required int availableRooms,
    @JsonKey(name: 'occupancy_rate') required double occupancyRate,
    required double revenue,
  }) = _OccupancyReport;

  factory OccupancyReport.fromJson(Map<String, dynamic> json) =>
      _$OccupancyReportFromJson(json);
}

/// Occupancy report request parameters
@freezed
sealed class OccupancyReportRequest with _$OccupancyReportRequest {
  const OccupancyReportRequest._();

  const factory OccupancyReportRequest({
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'group_by') @Default(ReportGroupBy.day) ReportGroupBy groupBy,
    @JsonKey(name: 'room_type') int? roomType,
  }) = _OccupancyReportRequest;

  factory OccupancyReportRequest.fromJson(Map<String, dynamic> json) =>
      _$OccupancyReportRequestFromJson(json);

  Map<String, String> toQueryParams() => {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'group_by': groupBy.toApiValue,
        if (roomType != null) 'room_type': roomType.toString(),
      };
}

// ==================== REVENUE REPORT ====================

/// Revenue report data model
@freezed
sealed class RevenueReport with _$RevenueReport {
  const factory RevenueReport({
    String? date,
    String? period, // For week/month grouping
    @JsonKey(name: 'room_revenue') required double roomRevenue,
    @JsonKey(name: 'additional_revenue') required double additionalRevenue,
    @JsonKey(name: 'minibar_revenue') required double minibarRevenue,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'total_expenses') required double totalExpenses,
    @JsonKey(name: 'net_profit') required double netProfit,
    @JsonKey(name: 'profit_margin') required double profitMargin,
  }) = _RevenueReport;

  factory RevenueReport.fromJson(Map<String, dynamic> json) =>
      _$RevenueReportFromJson(json);
}

/// Revenue report request parameters
@freezed
sealed class RevenueReportRequest with _$RevenueReportRequest {
  const RevenueReportRequest._();

  const factory RevenueReportRequest({
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'group_by') @Default(ReportGroupBy.day) ReportGroupBy groupBy,
    int? category,
  }) = _RevenueReportRequest;

  factory RevenueReportRequest.fromJson(Map<String, dynamic> json) =>
      _$RevenueReportRequestFromJson(json);

  Map<String, String> toQueryParams() => {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'group_by': groupBy.toApiValue,
        if (category != null) 'category': category.toString(),
      };
}

// ==================== KPI REPORT ====================

/// KPI report data model (RevPAR, ADR, etc.)
@freezed
sealed class KPIReport with _$KPIReport {
  const KPIReport._();

  const factory KPIReport({
    @JsonKey(name: 'period_start') required String periodStart,
    @JsonKey(name: 'period_end') required String periodEnd,

    // Key metrics
    required double revpar,
    required double adr,
    @JsonKey(name: 'occupancy_rate') required double occupancyRate,

    // Totals
    @JsonKey(name: 'total_room_nights_available')
    required int totalRoomNightsAvailable,
    @JsonKey(name: 'total_room_nights_sold') required int totalRoomNightsSold,
    @JsonKey(name: 'total_room_revenue') required double totalRoomRevenue,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'total_expenses') required double totalExpenses,
    @JsonKey(name: 'net_profit') required double netProfit,

    // Comparisons
    @JsonKey(name: 'revpar_change') double? revparChange,
    @JsonKey(name: 'adr_change') double? adrChange,
    @JsonKey(name: 'occupancy_change') double? occupancyChange,
    @JsonKey(name: 'revenue_change') double? revenueChange,
  }) = _KPIReport;

  factory KPIReport.fromJson(Map<String, dynamic> json) =>
      _$KPIReportFromJson(json);

  /// Check if metrics improved compared to previous period
  bool get revparImproved => (revparChange ?? 0) > 0;
  bool get adrImproved => (adrChange ?? 0) > 0;
  bool get occupancyImproved => (occupancyChange ?? 0) > 0;
  bool get revenueImproved => (revenueChange ?? 0) > 0;
}

/// KPI report request parameters
@freezed
sealed class KPIReportRequest with _$KPIReportRequest {
  const KPIReportRequest._();

  const factory KPIReportRequest({
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'compare_previous') @Default(true) bool comparePrevious,
  }) = _KPIReportRequest;

  factory KPIReportRequest.fromJson(Map<String, dynamic> json) =>
      _$KPIReportRequestFromJson(json);

  Map<String, String> toQueryParams() => {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'compare_previous': comparePrevious.toString(),
      };
}

// ==================== EXPENSE REPORT ====================

/// Expense report data by category
@freezed
sealed class ExpenseReport with _$ExpenseReport {
  const ExpenseReport._();

  const factory ExpenseReport({
    @JsonKey(name: 'category_id') required int categoryId,
    @JsonKey(name: 'category_name') required String categoryName,
    @JsonKey(name: 'category_icon') required String categoryIcon,
    @JsonKey(name: 'category_color') required String categoryColor,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'transaction_count') required int transactionCount,
    required double percentage,
  }) = _ExpenseReport;

  factory ExpenseReport.fromJson(Map<String, dynamic> json) =>
      _$ExpenseReportFromJson(json);

  /// Get Color from hex string
  Color get colorValue {
    try {
      final hexColor = categoryColor.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Get IconData from icon string name
  IconData get iconData {
    return _iconMap[categoryIcon] ?? Icons.category;
  }
}

/// Expense report request parameters
@freezed
sealed class ExpenseReportRequest with _$ExpenseReportRequest {
  const ExpenseReportRequest._();

  const factory ExpenseReportRequest({
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
  }) = _ExpenseReportRequest;

  factory ExpenseReportRequest.fromJson(Map<String, dynamic> json) =>
      _$ExpenseReportRequestFromJson(json);

  Map<String, String> toQueryParams() => {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      };
}

// ==================== CHANNEL PERFORMANCE ====================

/// Channel (booking source) performance data
@freezed
sealed class ChannelPerformance with _$ChannelPerformance {
  const ChannelPerformance._();

  const factory ChannelPerformance({
    required String source,
    @JsonKey(name: 'source_display') required String sourceDisplay,
    @JsonKey(name: 'booking_count') required int bookingCount,
    @JsonKey(name: 'total_nights') required int totalNights,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'average_rate') required double averageRate,
    @JsonKey(name: 'cancellation_count') required int cancellationCount,
    @JsonKey(name: 'cancellation_rate') required double cancellationRate,
    @JsonKey(name: 'percentage_of_revenue') required double percentageOfRevenue,
  }) = _ChannelPerformance;

  factory ChannelPerformance.fromJson(Map<String, dynamic> json) =>
      _$ChannelPerformanceFromJson(json);

  /// Check if this is a high-performing channel
  bool get isHighPerforming => percentageOfRevenue >= 20;

  /// Check if cancellation rate is high
  bool get hasHighCancellation => cancellationRate > 15;
}

/// Channel performance request parameters
@freezed
sealed class ChannelPerformanceRequest with _$ChannelPerformanceRequest {
  const ChannelPerformanceRequest._();

  const factory ChannelPerformanceRequest({
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
  }) = _ChannelPerformanceRequest;

  factory ChannelPerformanceRequest.fromJson(Map<String, dynamic> json) =>
      _$ChannelPerformanceRequestFromJson(json);

  Map<String, String> toQueryParams() => {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      };
}

// ==================== GUEST DEMOGRAPHICS ====================

/// Guest demographics data
@freezed
sealed class GuestDemographics with _$GuestDemographics {
  const factory GuestDemographics({
    required String nationality,
    @JsonKey(name: 'guest_count') required int guestCount,
    @JsonKey(name: 'booking_count') required int bookingCount,
    @JsonKey(name: 'total_nights') required int totalNights,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    required double percentage,
    @JsonKey(name: 'average_stay') required double averageStay,
  }) = _GuestDemographics;

  factory GuestDemographics.fromJson(Map<String, dynamic> json) =>
      _$GuestDemographicsFromJson(json);
}

/// Guest demographics request parameters
@freezed
sealed class GuestDemographicsRequest with _$GuestDemographicsRequest {
  const GuestDemographicsRequest._();

  const factory GuestDemographicsRequest({
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'group_by')
    @Default(DemographicsGroupBy.nationality)
    DemographicsGroupBy groupBy,
  }) = _GuestDemographicsRequest;

  factory GuestDemographicsRequest.fromJson(Map<String, dynamic> json) =>
      _$GuestDemographicsRequestFromJson(json);

  Map<String, String> toQueryParams() => {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'group_by': groupBy.toApiValue,
      };
}

// ==================== COMPARATIVE REPORT ====================

/// Comparative report data (period over period)
@freezed
sealed class ComparativeReport with _$ComparativeReport {
  const ComparativeReport._();

  const factory ComparativeReport({
    required String metric,
    @JsonKey(name: 'current_period_value') required double currentPeriodValue,
    @JsonKey(name: 'previous_period_value') double? previousPeriodValue,
    @JsonKey(name: 'change_amount') double? changeAmount,
    @JsonKey(name: 'change_percentage') double? changePercentage,
  }) = _ComparativeReport;

  factory ComparativeReport.fromJson(Map<String, dynamic> json) =>
      _$ComparativeReportFromJson(json);

  /// Check if metric improved
  bool get improved => (changePercentage ?? 0) > 0;

  /// Get display name for metric
  String get metricDisplayName {
    switch (metric.toLowerCase()) {
      case 'revenue':
        return 'Doanh thu';
      case 'occupancy':
        return 'Công suất';
      case 'adr':
        return 'ADR';
      case 'revpar':
        return 'RevPAR';
      case 'bookings':
        return 'Số đặt phòng';
      case 'guests':
        return 'Số khách';
      default:
        return metric;
    }
  }
}

/// Comparative report request parameters
@freezed
sealed class ComparativeReportRequest with _$ComparativeReportRequest {
  const ComparativeReportRequest._();

  const factory ComparativeReportRequest({
    @JsonKey(name: 'current_start') required DateTime currentStart,
    @JsonKey(name: 'current_end') required DateTime currentEnd,
    @JsonKey(name: 'previous_start') DateTime? previousStart,
    @JsonKey(name: 'previous_end') DateTime? previousEnd,
    @JsonKey(name: 'comparison_type')
    @Default(ComparisonType.previousPeriod)
    ComparisonType comparisonType,
  }) = _ComparativeReportRequest;

  factory ComparativeReportRequest.fromJson(Map<String, dynamic> json) =>
      _$ComparativeReportRequestFromJson(json);

  Map<String, String> toQueryParams() => {
        'current_start': _formatDate(currentStart),
        'current_end': _formatDate(currentEnd),
        if (previousStart != null) 'previous_start': _formatDate(previousStart!),
        if (previousEnd != null) 'previous_end': _formatDate(previousEnd!),
        'comparison_type': comparisonType.toApiValue,
      };
}

// ==================== EXPORT REQUEST ====================

/// Export report request parameters
@freezed
sealed class ExportReportRequest with _$ExportReportRequest {
  const ExportReportRequest._();

  const factory ExportReportRequest({
    @JsonKey(name: 'report_type') required ReportType reportType,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @Default(ExportFormat.xlsx) ExportFormat format,
  }) = _ExportReportRequest;

  factory ExportReportRequest.fromJson(Map<String, dynamic> json) =>
      _$ExportReportRequestFromJson(json);

  Map<String, String> toQueryParams() => {
        'report_type': reportType.toApiValue,
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'format': format.toApiValue,
      };

  /// Generate suggested filename
  String get suggestedFilename {
    final dateRange =
        '${_formatDate(startDate)}_to_${_formatDate(endDate)}';
    return '${reportType.toApiValue}_report_$dateRange.${format.fileExtension}';
  }
}

// ==================== REPORT SUMMARY ====================

/// Combined report summary for dashboard widgets
@freezed
sealed class ReportSummary with _$ReportSummary {
  const factory ReportSummary({
    @JsonKey(name: 'period_start') required String periodStart,
    @JsonKey(name: 'period_end') required String periodEnd,

    // Quick stats
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'total_expenses') required double totalExpenses,
    @JsonKey(name: 'net_profit') required double netProfit,
    @JsonKey(name: 'average_occupancy') required double averageOccupancy,
    required double revpar,
    required double adr,

    // Counts
    @JsonKey(name: 'total_bookings') required int totalBookings,
    @JsonKey(name: 'total_guests') required int totalGuests,
    @JsonKey(name: 'total_nights_sold') required int totalNightsSold,

    // Change indicators
    @JsonKey(name: 'revenue_change') double? revenueChange,
    @JsonKey(name: 'occupancy_change') double? occupancyChange,
  }) = _ReportSummary;

  factory ReportSummary.fromJson(Map<String, dynamic> json) =>
      _$ReportSummaryFromJson(json);
}

// ==================== HELPER FUNCTIONS ====================

/// Format date for API requests
String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Icon map for expense categories
const Map<String, IconData> _iconMap = {
  'hotel': Icons.hotel,
  'payments': Icons.payments,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'wifi': Icons.wifi,
  'cleaning_services': Icons.cleaning_services,
  'restaurant': Icons.restaurant,
  'shopping_cart': Icons.shopping_cart,
  'local_shipping': Icons.local_shipping,
  'build': Icons.build,
  'security': Icons.security,
  'calculate': Icons.calculate,
  'account_balance': Icons.account_balance,
  'business': Icons.business,
  'attach_money': Icons.attach_money,
  'money_off': Icons.money_off,
  'category': Icons.category,
  'more_horiz': Icons.more_horiz,
};
