import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/report.dart';
import '../repositories/report_repository.dart';

part 'report_provider.freezed.dart';

/// Provider for ReportRepository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

// ==================== Date Range Helper ====================

/// Report date range for filtering
@freezed
sealed class ReportDateRange with _$ReportDateRange {
  const factory ReportDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) = _ReportDateRange;
}

// ==================== Occupancy Report Providers ====================

/// Provider for occupancy report
final occupancyReportProvider = FutureProvider.autoDispose
    .family<List<OccupancyReport>, OccupancyReportRequest>(
  (ref, request) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getOccupancyReport(request);
  },
);

/// Provider for occupancy report with simplified date range
final occupancyReportByDateProvider = FutureProvider.autoDispose.family<
    List<OccupancyReport>, ({DateTime start, DateTime end, ReportGroupBy? groupBy})>(
  (ref, params) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getOccupancyReport(
      OccupancyReportRequest(
        startDate: params.start,
        endDate: params.end,
        groupBy: params.groupBy ?? ReportGroupBy.day,
      ),
    );
  },
);

// ==================== Revenue Report Providers ====================

/// Provider for revenue report
final revenueReportProvider = FutureProvider.autoDispose
    .family<List<RevenueReport>, RevenueReportRequest>(
  (ref, request) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getRevenueReport(request);
  },
);

/// Provider for revenue report with simplified date range
final revenueReportByDateProvider = FutureProvider.autoDispose.family<
    List<RevenueReport>, ({DateTime start, DateTime end, ReportGroupBy? groupBy})>(
  (ref, params) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getRevenueReport(
      RevenueReportRequest(
        startDate: params.start,
        endDate: params.end,
        groupBy: params.groupBy ?? ReportGroupBy.day,
      ),
    );
  },
);

// ==================== KPI Report Providers ====================

/// Provider for KPI report
final kpiReportProvider = FutureProvider.autoDispose
    .family<KPIReport, KPIReportRequest>(
  (ref, request) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getKPIReport(request);
  },
);

/// Provider for KPI report with simplified date range
final kpiReportByDateProvider = FutureProvider.autoDispose.family<
    KPIReport, ({DateTime start, DateTime end, bool? comparePrevious})>(
  (ref, params) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getKPIReport(
      KPIReportRequest(
        startDate: params.start,
        endDate: params.end,
        comparePrevious: params.comparePrevious ?? true,
      ),
    );
  },
);

// ==================== Expense Report Providers ====================

/// Provider for expense report
final expenseReportProvider = FutureProvider.autoDispose
    .family<List<ExpenseReport>, ExpenseReportRequest>(
  (ref, request) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getExpenseReport(request);
  },
);

/// Provider for expense report with simplified date range
final expenseReportByDateProvider = FutureProvider.autoDispose
    .family<List<ExpenseReport>, ReportDateRange>(
  (ref, range) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getExpenseReport(
      ExpenseReportRequest(
        startDate: range.startDate,
        endDate: range.endDate,
      ),
    );
  },
);

// ==================== Channel Performance Providers ====================

/// Provider for channel performance
final channelPerformanceProvider = FutureProvider.autoDispose
    .family<List<ChannelPerformance>, ChannelPerformanceRequest>(
  (ref, request) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getChannelPerformance(request);
  },
);

/// Provider for channel performance with simplified date range
final channelPerformanceByDateProvider = FutureProvider.autoDispose
    .family<List<ChannelPerformance>, ReportDateRange>(
  (ref, range) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getChannelPerformance(
      ChannelPerformanceRequest(
        startDate: range.startDate,
        endDate: range.endDate,
      ),
    );
  },
);

/// Provider for top channels
final topChannelsProvider = FutureProvider.autoDispose.family<
    List<ChannelPerformance>, ({DateTime start, DateTime end, int? limit})>(
  (ref, params) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getTopChannels(
      params.start,
      params.end,
      limit: params.limit ?? 5,
    );
  },
);

// ==================== Guest Demographics Providers ====================

/// Provider for guest demographics
final guestDemographicsProvider = FutureProvider.autoDispose
    .family<List<GuestDemographics>, GuestDemographicsRequest>(
  (ref, request) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getGuestDemographics(request);
  },
);

/// Provider for demographics with simplified date range
final guestDemographicsByDateProvider = FutureProvider.autoDispose.family<
    List<GuestDemographics>,
    ({DateTime start, DateTime end, DemographicsGroupBy? groupBy})>(
  (ref, params) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getGuestDemographics(
      GuestDemographicsRequest(
        startDate: params.start,
        endDate: params.end,
        groupBy: params.groupBy ?? DemographicsGroupBy.nationality,
      ),
    );
  },
);

/// Provider for top nationalities
final topNationalitiesProvider = FutureProvider.autoDispose.family<
    List<GuestDemographics>, ({DateTime start, DateTime end, int? limit})>(
  (ref, params) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getTopNationalities(
      params.start,
      params.end,
      limit: params.limit ?? 10,
    );
  },
);

// ==================== Comparative Report Providers ====================

/// Provider for comparative report
final comparativeReportProvider = FutureProvider.autoDispose
    .family<List<ComparativeReport>, ComparativeReportRequest>(
  (ref, request) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getComparativeReport(request);
  },
);

// ==================== Export Report Providers ====================

/// Provider for report export
final exportReportProvider = FutureProvider.autoDispose
    .family<Uint8List, ExportReportRequest>(
  (ref, request) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.exportReport(request);
  },
);

// ==================== Convenience Providers ====================

/// Provider for average occupancy (quick stat)
final averageOccupancyProvider = FutureProvider.autoDispose
    .family<double, ReportDateRange>(
  (ref, range) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getAverageOccupancy(range.startDate, range.endDate);
  },
);

/// Provider for total revenue (quick stat)
final totalRevenueProvider = FutureProvider.autoDispose
    .family<double, ReportDateRange>(
  (ref, range) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getTotalRevenue(range.startDate, range.endDate);
  },
);

/// Provider for total expenses (quick stat)
final totalExpensesProvider = FutureProvider.autoDispose
    .family<double, ReportDateRange>(
  (ref, range) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getTotalExpenses(range.startDate, range.endDate);
  },
);

// ==================== Report Screen State ====================

/// State for report screen
@freezed
sealed class ReportScreenState with _$ReportScreenState {
  const factory ReportScreenState({
    @Default(ReportType.occupancy) ReportType selectedReportType,
    @Default(ReportGroupBy.day) ReportGroupBy groupBy,
    required DateTime startDate,
    required DateTime endDate,
    @Default(false) bool isLoading,
    @Default(false) bool isExporting,
    String? error,
  }) = _ReportScreenState;
}

/// State notifier for report screen
class ReportScreenNotifier extends StateNotifier<ReportScreenState> {
  final ReportRepository _repository;

  ReportScreenNotifier(this._repository)
      : super(ReportScreenState(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ));

  void setReportType(ReportType type) {
    state = state.copyWith(selectedReportType: type);
  }

  void setGroupBy(ReportGroupBy groupBy) {
    state = state.copyWith(groupBy: groupBy);
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
    );
  }

  void setThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    state = state.copyWith(
      startDate: startOfWeek,
      endDate: now,
    );
  }

  void setThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    state = state.copyWith(
      startDate: startOfMonth,
      endDate: now,
    );
  }

  void setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    state = state.copyWith(
      startDate: lastMonth,
      endDate: endOfLastMonth,
    );
  }

  void setThisYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    state = state.copyWith(
      startDate: startOfYear,
      endDate: now,
    );
  }

  void setLast30Days() {
    final now = DateTime.now();
    state = state.copyWith(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );
  }

  void setLast90Days() {
    final now = DateTime.now();
    state = state.copyWith(
      startDate: now.subtract(const Duration(days: 90)),
      endDate: now,
    );
  }

  Future<Uint8List?> exportReport(ExportFormat format) async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      final request = ExportReportRequest(
        reportType: state.selectedReportType,
        startDate: state.startDate,
        endDate: state.endDate,
        format: format,
      );
      final result = await _repository.exportReport(request);
      state = state.copyWith(isExporting: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Lỗi xuất báo cáo: $e',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for report screen state
final reportScreenStateProvider =
    StateNotifierProvider.autoDispose<ReportScreenNotifier, ReportScreenState>(
  (ref) {
    final repository = ref.watch(reportRepositoryProvider);
    return ReportScreenNotifier(repository);
  },
);

// ==================== Current Report Data Providers ====================

/// Provider for current occupancy report based on screen state
final currentOccupancyReportProvider =
    FutureProvider.autoDispose<List<OccupancyReport>>((ref) async {
  final state = ref.watch(reportScreenStateProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getOccupancyReport(
    OccupancyReportRequest(
      startDate: state.startDate,
      endDate: state.endDate,
      groupBy: state.groupBy,
    ),
  );
});

/// Provider for current revenue report based on screen state
final currentRevenueReportProvider =
    FutureProvider.autoDispose<List<RevenueReport>>((ref) async {
  final state = ref.watch(reportScreenStateProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getRevenueReport(
    RevenueReportRequest(
      startDate: state.startDate,
      endDate: state.endDate,
      groupBy: state.groupBy,
    ),
  );
});

/// Provider for current KPI report based on screen state
final currentKPIReportProvider =
    FutureProvider.autoDispose<KPIReport>((ref) async {
  final state = ref.watch(reportScreenStateProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getKPIReport(
    KPIReportRequest(
      startDate: state.startDate,
      endDate: state.endDate,
      comparePrevious: true,
    ),
  );
});

/// Provider for current expense report based on screen state
final currentExpenseReportProvider =
    FutureProvider.autoDispose<List<ExpenseReport>>((ref) async {
  final state = ref.watch(reportScreenStateProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getExpenseReport(
    ExpenseReportRequest(
      startDate: state.startDate,
      endDate: state.endDate,
    ),
  );
});

/// Provider for current channel performance based on screen state
final currentChannelPerformanceProvider =
    FutureProvider.autoDispose<List<ChannelPerformance>>((ref) async {
  final state = ref.watch(reportScreenStateProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getChannelPerformance(
    ChannelPerformanceRequest(
      startDate: state.startDate,
      endDate: state.endDate,
    ),
  );
});

/// Provider for current guest demographics based on screen state
final currentGuestDemographicsProvider =
    FutureProvider.autoDispose<List<GuestDemographics>>((ref) async {
  final state = ref.watch(reportScreenStateProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getGuestDemographics(
    GuestDemographicsRequest(
      startDate: state.startDate,
      endDate: state.endDate,
    ),
  );
});
