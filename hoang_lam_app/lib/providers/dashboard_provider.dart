import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard.dart';
import '../repositories/dashboard_repository.dart';

/// Provider for dashboard repository
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// Provider for dashboard summary
final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboardSummary();
});

/// Provider for refreshing dashboard data
final refreshDashboardProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(dashboardSummaryProvider);
  };
});
