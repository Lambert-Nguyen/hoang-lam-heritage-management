import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/housekeeping.dart';
import '../repositories/housekeeping_repository.dart';

part 'housekeeping_provider.freezed.dart';

/// Provider for HousekeepingRepository
final housekeepingRepositoryProvider = Provider<HousekeepingRepository>((ref) {
  return HousekeepingRepository();
});

// ============================================================
// Housekeeping Task Providers
// ============================================================

/// Provider for all housekeeping tasks
final housekeepingTasksProvider =
    FutureProvider<List<HousekeepingTask>>((ref) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getTasks();
});

/// Provider for today's housekeeping tasks
final todayTasksProvider = FutureProvider<List<HousekeepingTask>>((ref) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getTodayTasks();
});

/// Provider for current user's assigned tasks
final myTasksProvider = FutureProvider<List<HousekeepingTask>>((ref) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getMyTasks();
});

/// Provider for a specific task by ID
final taskByIdProvider =
    FutureProvider.family<HousekeepingTask, int>((ref, id) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getTask(id);
});

/// Provider for filtered housekeeping tasks
final filteredTasksProvider =
    FutureProvider.family<List<HousekeepingTask>, HousekeepingTaskFilter>(
        (ref, filter) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getTasks(
    roomId: filter.roomId,
    status: filter.status,
    taskType: filter.taskType,
    assignedTo: filter.assignedTo,
    scheduledDate: filter.scheduledDate,
  );
});

/// Filter model for housekeeping tasks
@freezed
sealed class HousekeepingTaskFilter with _$HousekeepingTaskFilter {
  const factory HousekeepingTaskFilter({
    int? roomId,
    HousekeepingTaskStatus? status,
    HousekeepingTaskType? taskType,
    int? assignedTo,
    DateTime? scheduledDate,
  }) = _HousekeepingTaskFilter;
}

// ============================================================
// Maintenance Request Providers
// ============================================================

/// Provider for all maintenance requests
final maintenanceRequestsProvider =
    FutureProvider<List<MaintenanceRequest>>((ref) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getMaintenanceRequests();
});

/// Provider for urgent maintenance requests
final urgentRequestsProvider =
    FutureProvider<List<MaintenanceRequest>>((ref) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getUrgentRequests();
});

/// Provider for current user's assigned maintenance requests
final myMaintenanceRequestsProvider =
    FutureProvider<List<MaintenanceRequest>>((ref) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getMyMaintenanceRequests();
});

/// Provider for a specific maintenance request by ID
final maintenanceRequestByIdProvider =
    FutureProvider.family<MaintenanceRequest, int>((ref, id) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getMaintenanceRequest(id);
});

/// Provider for filtered maintenance requests
final filteredMaintenanceRequestsProvider = FutureProvider.family<
    List<MaintenanceRequest>, MaintenanceRequestFilter>((ref, filter) async {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return repository.getMaintenanceRequests(
    roomId: filter.roomId,
    status: filter.status,
    priority: filter.priority,
    category: filter.category,
    assignedTo: filter.assignedTo,
  );
});

/// Filter model for maintenance requests
@freezed
sealed class MaintenanceRequestFilter with _$MaintenanceRequestFilter {
  const factory MaintenanceRequestFilter({
    int? roomId,
    MaintenanceStatus? status,
    MaintenancePriority? priority,
    MaintenanceCategory? category,
    int? assignedTo,
  }) = _MaintenanceRequestFilter;
}

// ============================================================
// State Management for Operations
// ============================================================

/// State for housekeeping operations
@freezed
sealed class HousekeepingState with _$HousekeepingState {
  const factory HousekeepingState({
    @Default(false) bool isLoading,
    String? errorMessage,
    HousekeepingTask? selectedTask,
    MaintenanceRequest? selectedRequest,
    @Default([]) List<HousekeepingTask> tasks,
    @Default([]) List<MaintenanceRequest> requests,
  }) = _HousekeepingState;
}

/// StateNotifier for managing housekeeping operations
class HousekeepingNotifier extends StateNotifier<HousekeepingState> {
  final HousekeepingRepository _repository;
  final Ref _ref;

  HousekeepingNotifier(this._repository, this._ref)
      : super(const HousekeepingState());

  // ==================== Task Operations ====================

  /// Load all tasks
  Future<void> loadTasks({
    int? roomId,
    HousekeepingTaskStatus? status,
    HousekeepingTaskType? taskType,
    int? assignedTo,
    DateTime? scheduledDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tasks = await _repository.getTasks(
        roomId: roomId,
        status: status,
        taskType: taskType,
        assignedTo: assignedTo,
        scheduledDate: scheduledDate,
      );
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create a new task
  Future<HousekeepingTask?> createTask(HousekeepingTaskCreate task) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newTask = await _repository.createTask(task);
      state = state.copyWith(
        isLoading: false,
        tasks: [...state.tasks, newTask],
      );
      _invalidateProviders();
      return newTask;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Assign a task to a staff member
  Future<HousekeepingTask?> assignTask(int taskId, int userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedTask = await _repository.assignTask(taskId, userId);
      _updateTaskInList(updatedTask);
      _invalidateProviders();
      return updatedTask;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Complete a task
  Future<HousekeepingTask?> completeTask(int taskId, {String? notes}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedTask = await _repository.completeTask(taskId, notes: notes);
      _updateTaskInList(updatedTask);
      _invalidateProviders();
      return updatedTask;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Verify a completed task
  Future<HousekeepingTask?> verifyTask(int taskId, {String? notes}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedTask = await _repository.verifyTask(taskId, notes: notes);
      _updateTaskInList(updatedTask);
      _invalidateProviders();
      return updatedTask;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Delete a task
  Future<bool> deleteTask(int taskId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteTask(taskId);
      state = state.copyWith(
        isLoading: false,
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void _updateTaskInList(HousekeepingTask updatedTask) {
    final updatedTasks = state.tasks.map((t) {
      return t.id == updatedTask.id ? updatedTask : t;
    }).toList();
    state = state.copyWith(isLoading: false, tasks: updatedTasks);
  }

  // ==================== Maintenance Request Operations ====================

  /// Load all maintenance requests
  Future<void> loadMaintenanceRequests({
    int? roomId,
    MaintenanceStatus? status,
    MaintenancePriority? priority,
    MaintenanceCategory? category,
    int? assignedTo,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final requests = await _repository.getMaintenanceRequests(
        roomId: roomId,
        status: status,
        priority: priority,
        category: category,
        assignedTo: assignedTo,
      );
      state = state.copyWith(isLoading: false, requests: requests);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create a new maintenance request
  Future<MaintenanceRequest?> createMaintenanceRequest(
      MaintenanceRequestCreate request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newRequest = await _repository.createMaintenanceRequest(request);
      state = state.copyWith(
        isLoading: false,
        requests: [...state.requests, newRequest],
      );
      _invalidateProviders();
      return newRequest;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Update an existing maintenance request
  Future<MaintenanceRequest?> updateMaintenanceRequest(
    int id,
    MaintenanceRequestUpdate update,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedRequest = await _repository.updateMaintenanceRequest(
        id,
        update,
      );
      _updateRequestInList(updatedRequest);
      _invalidateProviders();
      return updatedRequest;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Assign a maintenance request
  Future<MaintenanceRequest?> assignMaintenanceRequest(
    int requestId,
    int userId, {
    int? estimatedCost,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedRequest = await _repository.assignMaintenanceRequest(
        requestId,
        userId,
        estimatedCost: estimatedCost,
      );
      _updateRequestInList(updatedRequest);
      _invalidateProviders();
      return updatedRequest;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Complete a maintenance request
  Future<MaintenanceRequest?> completeMaintenanceRequest(
    int requestId, {
    int? actualCost,
    String? resolutionNotes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedRequest = await _repository.completeMaintenanceRequest(
        requestId,
        actualCost: actualCost,
        resolutionNotes: resolutionNotes,
      );
      _updateRequestInList(updatedRequest);
      _invalidateProviders();
      return updatedRequest;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Put a maintenance request on hold
  Future<MaintenanceRequest?> holdMaintenanceRequest(
    int requestId, {
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedRequest = await _repository.holdMaintenanceRequest(
        requestId,
        reason: reason,
      );
      _updateRequestInList(updatedRequest);
      _invalidateProviders();
      return updatedRequest;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Resume a maintenance request
  Future<MaintenanceRequest?> resumeMaintenanceRequest(int requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedRequest =
          await _repository.resumeMaintenanceRequest(requestId);
      _updateRequestInList(updatedRequest);
      _invalidateProviders();
      return updatedRequest;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Cancel a maintenance request
  Future<MaintenanceRequest?> cancelMaintenanceRequest(
    int requestId, {
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedRequest = await _repository.cancelMaintenanceRequest(
        requestId,
        reason: reason,
      );
      _updateRequestInList(updatedRequest);
      _invalidateProviders();
      return updatedRequest;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Delete a maintenance request
  Future<bool> deleteMaintenanceRequest(int requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteMaintenanceRequest(requestId);
      state = state.copyWith(
        isLoading: false,
        requests: state.requests.where((r) => r.id != requestId).toList(),
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void _updateRequestInList(MaintenanceRequest updatedRequest) {
    final updatedRequests = state.requests.map((r) {
      return r.id == updatedRequest.id ? updatedRequest : r;
    }).toList();
    state = state.copyWith(isLoading: false, requests: updatedRequests);
  }

  // ==================== Helpers ====================

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Select a task
  void selectTask(HousekeepingTask? task) {
    state = state.copyWith(selectedTask: task);
  }

  /// Select a maintenance request
  void selectRequest(MaintenanceRequest? request) {
    state = state.copyWith(selectedRequest: request);
  }

  /// Invalidate related providers to refresh data
  void _invalidateProviders() {
    _ref.invalidate(housekeepingTasksProvider);
    _ref.invalidate(todayTasksProvider);
    _ref.invalidate(myTasksProvider);
    _ref.invalidate(maintenanceRequestsProvider);
    _ref.invalidate(urgentRequestsProvider);
    _ref.invalidate(myMaintenanceRequestsProvider);
  }
}

/// Provider for HousekeepingNotifier
final housekeepingNotifierProvider =
    StateNotifierProvider<HousekeepingNotifier, HousekeepingState>((ref) {
  final repository = ref.watch(housekeepingRepositoryProvider);
  return HousekeepingNotifier(repository, ref);
});
