import '../core/network/api_client.dart';
import '../core/config/app_constants.dart';
import '../models/dashboard.dart';

/// Repository for dashboard data
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get dashboard summary
  Future<DashboardSummary> getDashboardSummary() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      AppConstants.dashboardEndpoint,
    );
    return DashboardSummary.fromJson(response.data!);
  }
}
