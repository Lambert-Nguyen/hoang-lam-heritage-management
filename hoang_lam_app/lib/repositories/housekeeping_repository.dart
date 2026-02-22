import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/housekeeping.dart';

/// Repository for housekeeping task and maintenance request operations
class HousekeepingRepository {
  final ApiClient _apiClient;

  HousekeepingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== Housekeeping Tasks ====================

  /// Get all housekeeping tasks with optional filters
  Future<List<HousekeepingTask>> getTasks({
    int? roomId,
    HousekeepingTaskStatus? status,
    HousekeepingTaskType? taskType,
    int? assignedTo,
    DateTime? scheduledDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (roomId != null) {
      queryParams['room'] = roomId.toString();
    }
    if (status != null) {
      queryParams['status'] = status.apiValue;
    }
    if (taskType != null) {
      queryParams['task_type'] = taskType.apiValue;
    }
    if (assignedTo != null) {
      queryParams['assigned_to'] = assignedTo.toString();
    }
    if (scheduledDate != null) {
      queryParams['scheduled_date'] =
          '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.housekeepingTasksEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle paginated response
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = HousekeepingTaskListResponse.fromJson(dataMap);
        return listResponse.results;
      }
    }

    // Handle non-paginated response
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => HousekeepingTask.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get a single task by ID
  Future<HousekeepingTask> getTask(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.housekeepingTasksEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Task not found');
    }
    return HousekeepingTask.fromJson(response.data!);
  }

  /// Create a new task
  Future<HousekeepingTask> createTask(HousekeepingTaskCreate task) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.housekeepingTasksEndpoint,
      data: task.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to create task');
    }
    return HousekeepingTask.fromJson(response.data!);
  }

  /// Update an existing task
  Future<HousekeepingTask> updateTask(
    int id,
    HousekeepingTaskUpdate update,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.housekeepingTasksEndpoint}$id/',
      data: update.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to update task');
    }
    return HousekeepingTask.fromJson(response.data!);
  }

  /// Delete a task
  Future<void> deleteTask(int id) async {
    await _apiClient.delete('${AppConstants.housekeepingTasksEndpoint}$id/');
  }

  /// Assign a task to a staff member
  Future<HousekeepingTask> assignTask(int taskId, int userId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.housekeepingTasksEndpoint}$taskId/assign/',
      data: {'assigned_to': userId},
    );
    if (response.data == null) {
      throw Exception('Failed to assign task');
    }
    return HousekeepingTask.fromJson(response.data!);
  }

  /// Complete a task
  Future<HousekeepingTask> completeTask(int taskId, {String? notes}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.housekeepingTasksEndpoint}$taskId/complete/',
      data: notes != null ? {'notes': notes} : {},
    );
    if (response.data == null) {
      throw Exception('Failed to complete task');
    }
    return HousekeepingTask.fromJson(response.data!);
  }

  /// Verify a completed task
  Future<HousekeepingTask> verifyTask(int taskId, {String? notes}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.housekeepingTasksEndpoint}$taskId/verify/',
      data: notes != null ? {'notes': notes} : {},
    );
    if (response.data == null) {
      throw Exception('Failed to verify task');
    }
    return HousekeepingTask.fromJson(response.data!);
  }

  /// Get tasks scheduled for today
  Future<List<HousekeepingTask>> getTodayTasks() async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.housekeepingTasksEndpoint}today/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => HousekeepingTask.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get tasks assigned to current user
  Future<List<HousekeepingTask>> getMyTasks() async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.housekeepingTasksEndpoint}my_tasks/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => HousekeepingTask.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  // ==================== Maintenance Requests ====================

  /// Get all maintenance requests with optional filters
  Future<List<MaintenanceRequest>> getMaintenanceRequests({
    int? roomId,
    MaintenanceStatus? status,
    MaintenancePriority? priority,
    MaintenanceCategory? category,
    int? assignedTo,
  }) async {
    final queryParams = <String, dynamic>{};

    if (roomId != null) {
      queryParams['room'] = roomId.toString();
    }
    if (status != null) {
      queryParams['status'] = status.apiValue;
    }
    if (priority != null) {
      queryParams['priority'] = priority.apiValue;
    }
    if (category != null) {
      queryParams['category'] = category.apiValue;
    }
    if (assignedTo != null) {
      queryParams['assigned_to'] = assignedTo.toString();
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.maintenanceRequestsEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle paginated response
    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = MaintenanceRequestListResponse.fromJson(dataMap);
        return listResponse.results;
      }
    }

    // Handle non-paginated response
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get a single maintenance request by ID
  Future<MaintenanceRequest> getMaintenanceRequest(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.maintenanceRequestsEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Maintenance request not found');
    }
    return MaintenanceRequest.fromJson(response.data!);
  }

  /// Create a new maintenance request
  Future<MaintenanceRequest> createMaintenanceRequest(
    MaintenanceRequestCreate request,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.maintenanceRequestsEndpoint,
      data: request.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to create maintenance request');
    }
    return MaintenanceRequest.fromJson(response.data!);
  }

  /// Update an existing maintenance request
  Future<MaintenanceRequest> updateMaintenanceRequest(
    int id,
    MaintenanceRequestUpdate update,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.maintenanceRequestsEndpoint}$id/',
      data: update.toJson(),
    );
    if (response.data == null) {
      throw Exception('Failed to update maintenance request');
    }
    return MaintenanceRequest.fromJson(response.data!);
  }

  /// Delete a maintenance request
  Future<void> deleteMaintenanceRequest(int id) async {
    await _apiClient.delete('${AppConstants.maintenanceRequestsEndpoint}$id/');
  }

  /// Assign a maintenance request to a staff member
  Future<MaintenanceRequest> assignMaintenanceRequest(
    int requestId,
    int userId, {
    int? estimatedCost,
  }) async {
    final data = <String, dynamic>{'assigned_to': userId};
    if (estimatedCost != null) {
      data['estimated_cost'] = estimatedCost;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.maintenanceRequestsEndpoint}$requestId/assign/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to assign maintenance request');
    }
    return MaintenanceRequest.fromJson(response.data!);
  }

  /// Complete a maintenance request
  Future<MaintenanceRequest> completeMaintenanceRequest(
    int requestId, {
    int? actualCost,
    String? resolutionNotes,
  }) async {
    final data = <String, dynamic>{};
    if (actualCost != null) {
      data['actual_cost'] = actualCost;
    }
    if (resolutionNotes != null) {
      data['resolution_notes'] = resolutionNotes;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.maintenanceRequestsEndpoint}$requestId/complete/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to complete maintenance request');
    }
    return MaintenanceRequest.fromJson(response.data!);
  }

  /// Put a maintenance request on hold
  Future<MaintenanceRequest> holdMaintenanceRequest(
    int requestId, {
    String? reason,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.maintenanceRequestsEndpoint}$requestId/hold/',
      data: reason != null ? {'reason': reason} : {},
    );
    if (response.data == null) {
      throw Exception('Failed to hold maintenance request');
    }
    return MaintenanceRequest.fromJson(response.data!);
  }

  /// Resume a maintenance request from on hold
  Future<MaintenanceRequest> resumeMaintenanceRequest(int requestId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.maintenanceRequestsEndpoint}$requestId/resume/',
    );
    if (response.data == null) {
      throw Exception('Failed to resume maintenance request');
    }
    return MaintenanceRequest.fromJson(response.data!);
  }

  /// Cancel a maintenance request
  Future<MaintenanceRequest> cancelMaintenanceRequest(
    int requestId, {
    String? reason,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.maintenanceRequestsEndpoint}$requestId/cancel/',
      data: reason != null ? {'reason': reason} : {},
    );
    if (response.data == null) {
      throw Exception('Failed to cancel maintenance request');
    }
    return MaintenanceRequest.fromJson(response.data!);
  }

  /// Get urgent maintenance requests (high/urgent priority, not completed)
  Future<List<MaintenanceRequest>> getUrgentRequests() async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.maintenanceRequestsEndpoint}urgent/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get maintenance requests assigned to current user
  Future<List<MaintenanceRequest>> getMyMaintenanceRequests() async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.maintenanceRequestsEndpoint}my_requests/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }
}
