import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/room_inspection.dart';
import '../repositories/room_inspection_repository.dart';

part 'room_inspection_provider.freezed.dart';

/// Provider for RoomInspectionRepository
final roomInspectionRepositoryProvider = Provider<RoomInspectionRepository>((
  ref,
) {
  return RoomInspectionRepository();
});

// ============================================================
// Room Inspection Providers
// ============================================================

/// Provider for all room inspections
final roomInspectionsProvider = FutureProvider<List<RoomInspection>>((
  ref,
) async {
  final repository = ref.watch(roomInspectionRepositoryProvider);
  return repository.getInspections();
});

/// Provider for pending inspections today
final pendingInspectionsTodayProvider = FutureProvider<List<RoomInspection>>((
  ref,
) async {
  final repository = ref.watch(roomInspectionRepositoryProvider);
  return repository.getPendingToday();
});

/// Provider for a specific inspection by ID
final roomInspectionByIdProvider = FutureProvider.family<RoomInspection, int>((
  ref,
  id,
) async {
  final repository = ref.watch(roomInspectionRepositoryProvider);
  return repository.getInspection(id);
});

/// Provider for filtered inspections
final filteredInspectionsProvider =
    FutureProvider.family<List<RoomInspection>, InspectionFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(roomInspectionRepositoryProvider);
      return repository.getInspections(
        roomId: filter.roomId,
        status: filter.status,
        type: filter.type,
        fromDate: filter.fromDate,
        toDate: filter.toDate,
      );
    });

/// Provider for inspection statistics
final inspectionStatisticsProvider = FutureProvider<InspectionStatistics>((
  ref,
) async {
  final repository = ref.watch(roomInspectionRepositoryProvider);
  return repository.getStatistics();
});

/// Provider for inspections by room
final inspectionsByRoomProvider =
    FutureProvider.family<List<RoomInspection>, int>((ref, roomId) async {
      final repository = ref.watch(roomInspectionRepositoryProvider);
      return repository.getInspections(roomId: roomId);
    });

/// Filter model for inspections
@freezed
sealed class InspectionFilter with _$InspectionFilter {
  const factory InspectionFilter({
    int? roomId,
    InspectionStatus? status,
    InspectionType? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) = _InspectionFilter;
}

// ============================================================
// Inspection Template Providers
// ============================================================

/// Provider for all inspection templates
final inspectionTemplatesProvider = FutureProvider<List<InspectionTemplate>>((
  ref,
) async {
  final repository = ref.watch(roomInspectionRepositoryProvider);
  return repository.getTemplates(isActive: true);
});

/// Provider for a specific template by ID
final inspectionTemplateByIdProvider =
    FutureProvider.family<InspectionTemplate, int>((ref, id) async {
      final repository = ref.watch(roomInspectionRepositoryProvider);
      return repository.getTemplate(id);
    });

/// Provider for default templates
final defaultTemplatesProvider = FutureProvider<List<InspectionTemplate>>((
  ref,
) async {
  final repository = ref.watch(roomInspectionRepositoryProvider);
  return repository.getDefaultTemplates();
});

/// Provider for templates by type
final templatesByTypeProvider =
    FutureProvider.family<List<InspectionTemplate>, InspectionType>((
      ref,
      type,
    ) async {
      final repository = ref.watch(roomInspectionRepositoryProvider);
      return repository.getTemplates(type: type, isActive: true);
    });

// ============================================================
// State Management
// ============================================================

/// State for room inspection operations
@freezed
sealed class RoomInspectionState with _$RoomInspectionState {
  const factory RoomInspectionState({
    @Default(false) bool isLoading,
    String? errorMessage,
    RoomInspection? selectedInspection,
    @Default([]) List<RoomInspection> inspections,
    InspectionStatistics? statistics,
  }) = _RoomInspectionState;
}

/// StateNotifier for managing room inspection operations
class RoomInspectionNotifier extends StateNotifier<RoomInspectionState> {
  final RoomInspectionRepository _repository;
  final Ref _ref;

  RoomInspectionNotifier(this._repository, this._ref)
    : super(const RoomInspectionState());

  /// Load all inspections
  Future<void> loadInspections({
    int? roomId,
    InspectionStatus? status,
    InspectionType? type,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final inspections = await _repository.getInspections(
        roomId: roomId,
        status: status,
        type: type,
      );
      state = state.copyWith(isLoading: false, inspections: inspections);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Load statistics
  Future<void> loadStatistics() async {
    try {
      final statistics = await _repository.getStatistics();
      state = state.copyWith(statistics: statistics);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Create a new inspection
  Future<RoomInspection?> createInspection(RoomInspectionCreate data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newInspection = await _repository.createInspection(data);
      await loadInspections();
      _ref.invalidate(roomInspectionsProvider);
      _ref.invalidate(pendingInspectionsTodayProvider);
      _ref.invalidate(inspectionStatisticsProvider);
      return newInspection;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Update an inspection
  Future<RoomInspection?> updateInspection(
    int id,
    RoomInspectionUpdate update,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedInspection = await _repository.updateInspection(id, update);
      await loadInspections();
      _ref.invalidate(roomInspectionByIdProvider(id));
      _ref.invalidate(roomInspectionsProvider);
      return updatedInspection;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Start an inspection
  Future<RoomInspection?> startInspection(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final inspection = await _repository.startInspection(id);
      await loadInspections();
      _ref.invalidate(roomInspectionByIdProvider(id));
      _ref.invalidate(roomInspectionsProvider);
      _ref.invalidate(pendingInspectionsTodayProvider);
      return inspection;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Complete an inspection
  Future<RoomInspection?> completeInspection(
    int id,
    CompleteInspection data,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final inspection = await _repository.completeInspection(id, data);
      await loadInspections();
      _ref.invalidate(roomInspectionByIdProvider(id));
      _ref.invalidate(roomInspectionsProvider);
      _ref.invalidate(pendingInspectionsTodayProvider);
      _ref.invalidate(inspectionStatisticsProvider);
      return inspection;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Create inspection from checkout
  Future<RoomInspection?> createFromCheckout(
    int bookingId, {
    int? templateId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final inspection = await _repository.createFromCheckout(
        bookingId,
        templateId: templateId,
      );
      await loadInspections();
      _ref.invalidate(roomInspectionsProvider);
      _ref.invalidate(pendingInspectionsTodayProvider);
      return inspection;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Delete an inspection
  Future<bool> deleteInspection(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteInspection(id);
      await loadInspections();
      _ref.invalidate(roomInspectionsProvider);
      _ref.invalidate(inspectionStatisticsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Select an inspection
  void selectInspection(RoomInspection? inspection) {
    state = state.copyWith(selectedInspection: inspection);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for RoomInspectionNotifier
final roomInspectionNotifierProvider =
    StateNotifierProvider<RoomInspectionNotifier, RoomInspectionState>((ref) {
      final repository = ref.watch(roomInspectionRepositoryProvider);
      return RoomInspectionNotifier(repository, ref);
    });

// ============================================================
// Template State Management
// ============================================================

/// State for inspection template operations
@freezed
sealed class InspectionTemplateState with _$InspectionTemplateState {
  const factory InspectionTemplateState({
    @Default(false) bool isLoading,
    String? errorMessage,
    InspectionTemplate? selectedTemplate,
    @Default([]) List<InspectionTemplate> templates,
  }) = _InspectionTemplateState;
}

/// StateNotifier for managing inspection template operations
class InspectionTemplateNotifier
    extends StateNotifier<InspectionTemplateState> {
  final RoomInspectionRepository _repository;
  final Ref _ref;

  InspectionTemplateNotifier(this._repository, this._ref)
    : super(const InspectionTemplateState());

  /// Load all templates
  Future<void> loadTemplates({InspectionType? type}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final templates = await _repository.getTemplates(
        type: type,
        isActive: true,
      );
      state = state.copyWith(isLoading: false, templates: templates);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Create a new template
  Future<InspectionTemplate?> createTemplate(
    InspectionTemplateCreate data,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newTemplate = await _repository.createTemplate(data);
      await loadTemplates();
      _ref.invalidate(inspectionTemplatesProvider);
      _ref.invalidate(defaultTemplatesProvider);
      return newTemplate;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Update a template
  Future<InspectionTemplate?> updateTemplate(
    int id,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedTemplate = await _repository.updateTemplate(id, data);
      await loadTemplates();
      _ref.invalidate(inspectionTemplateByIdProvider(id));
      _ref.invalidate(inspectionTemplatesProvider);
      return updatedTemplate;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteTemplate(id);
      await loadTemplates();
      _ref.invalidate(inspectionTemplatesProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Select a template
  void selectTemplate(InspectionTemplate? template) {
    state = state.copyWith(selectedTemplate: template);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for InspectionTemplateNotifier
final inspectionTemplateNotifierProvider =
    StateNotifierProvider<InspectionTemplateNotifier, InspectionTemplateState>((
      ref,
    ) {
      final repository = ref.watch(roomInspectionRepositoryProvider);
      return InspectionTemplateNotifier(repository, ref);
    });
