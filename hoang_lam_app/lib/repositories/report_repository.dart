import 'dart:typed_data';

import '../core/network/api_client.dart';
import '../core/config/app_constants.dart';
import '../models/report.dart';

/// Repository for report data and analytics
class ReportRepository {
  final ApiClient _apiClient;

  ReportRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==================== OCCUPANCY REPORT ====================

  /// Get occupancy report with daily/weekly/monthly breakdown
  Future<List<OccupancyReport>> getOccupancyReport(
    OccupancyReportRequest request,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${AppConstants.reportsEndpoint}occupancy/',
      queryParameters: request.toQueryParams(),
    );
    return (response.data ?? [])
        .map((json) => OccupancyReport.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== REVENUE REPORT ====================

  /// Get revenue report with breakdown by source
  Future<List<RevenueReport>> getRevenueReport(
    RevenueReportRequest request,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${AppConstants.reportsEndpoint}revenue/',
      queryParameters: request.toQueryParams(),
    );
    return (response.data ?? [])
        .map((json) => RevenueReport.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== KPI REPORT ====================

  /// Get KPI metrics (RevPAR, ADR, Occupancy)
  Future<KPIReport> getKPIReport(KPIReportRequest request) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.reportsEndpoint}kpi/',
      queryParameters: request.toQueryParams(),
    );
    return KPIReport.fromJson(response.data!);
  }

  // ==================== EXPENSE REPORT ====================

  /// Get expense report by category
  Future<List<ExpenseReport>> getExpenseReport(
    ExpenseReportRequest request,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${AppConstants.reportsEndpoint}expenses/',
      queryParameters: request.toQueryParams(),
    );
    return (response.data ?? [])
        .map((json) => ExpenseReport.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== CHANNEL PERFORMANCE ====================

  /// Get channel (booking source) performance metrics
  Future<List<ChannelPerformance>> getChannelPerformance(
    ChannelPerformanceRequest request,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${AppConstants.reportsEndpoint}channels/',
      queryParameters: request.toQueryParams(),
    );
    return (response.data ?? [])
        .map(
            (json) => ChannelPerformance.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== GUEST DEMOGRAPHICS ====================

  /// Get guest demographics (nationality, source, room type)
  Future<List<GuestDemographics>> getGuestDemographics(
    GuestDemographicsRequest request,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${AppConstants.reportsEndpoint}demographics/',
      queryParameters: request.toQueryParams(),
    );
    return (response.data ?? [])
        .map(
            (json) => GuestDemographics.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== COMPARATIVE REPORT ====================

  /// Get period-over-period comparison report
  Future<List<ComparativeReport>> getComparativeReport(
    ComparativeReportRequest request,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${AppConstants.reportsEndpoint}comparative/',
      queryParameters: request.toQueryParams(),
    );
    return (response.data ?? [])
        .map(
            (json) => ComparativeReport.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== EXPORT REPORT ====================

  /// Export report to Excel/CSV format
  /// Returns the file bytes for download
  Future<Uint8List> exportReport(ExportReportRequest request) async {
    final response = await _apiClient.getBytes(
      '${AppConstants.reportsEndpoint}export/',
      queryParameters: request.toQueryParams(),
    );
    return Uint8List.fromList(response.data!);
  }

  // ==================== CONVENIENCE METHODS ====================

  /// Get quick occupancy stats for a date range
  Future<double> getAverageOccupancy(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final reports = await getOccupancyReport(
      OccupancyReportRequest(
        startDate: startDate,
        endDate: endDate,
        groupBy: ReportGroupBy.day,
      ),
    );
    if (reports.isEmpty) return 0;
    final totalOccupancy =
        reports.fold<double>(0, (sum, r) => sum + r.occupancyRate);
    return totalOccupancy / reports.length;
  }

  /// Get total revenue for a date range
  Future<double> getTotalRevenue(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final reports = await getRevenueReport(
      RevenueReportRequest(
        startDate: startDate,
        endDate: endDate,
        groupBy: ReportGroupBy.day,
      ),
    );
    return reports.fold<double>(0, (sum, r) => sum + r.totalRevenue);
  }

  /// Get total expenses for a date range
  Future<double> getTotalExpenses(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final reports = await getExpenseReport(
      ExpenseReportRequest(
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return reports.fold<double>(0, (sum, r) => sum + r.totalAmount);
  }

  /// Get top booking channels by revenue
  Future<List<ChannelPerformance>> getTopChannels(
    DateTime startDate,
    DateTime endDate, {
    int limit = 5,
  }) async {
    final channels = await getChannelPerformance(
      ChannelPerformanceRequest(
        startDate: startDate,
        endDate: endDate,
      ),
    );
    // Sort by revenue and take top N
    channels.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return channels.take(limit).toList();
  }

  /// Get top nationalities by guest count
  Future<List<GuestDemographics>> getTopNationalities(
    DateTime startDate,
    DateTime endDate, {
    int limit = 10,
  }) async {
    final demographics = await getGuestDemographics(
      GuestDemographicsRequest(
        startDate: startDate,
        endDate: endDate,
        groupBy: DemographicsGroupBy.nationality,
      ),
    );
    // Sort by guest count and take top N
    demographics.sort((a, b) => b.guestCount.compareTo(a.guestCount));
    return demographics.take(limit).toList();
  }
}
