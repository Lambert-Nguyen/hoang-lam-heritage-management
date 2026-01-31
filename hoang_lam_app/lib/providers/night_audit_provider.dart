import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/night_audit.dart';
import '../repositories/night_audit_repository.dart';

part 'night_audit_provider.freezed.dart';

/// Provider for NightAuditRepository
final nightAuditRepositoryProvider = Provider<NightAuditRepository>((ref) {
  return NightAuditRepository();
});

/// Provider for all night audits list
final nightAuditsProvider = FutureProvider.autoDispose<List<NightAuditListItem>>((ref) async {
  final repository = ref.watch(nightAuditRepositoryProvider);
  return repository.getAudits();
});

/// Provider for today's night audit
final todayAuditProvider = FutureProvider.autoDispose<NightAudit>((ref) async {
  final repository = ref.watch(nightAuditRepositoryProvider);
  return repository.getTodayAudit();
});

/// Provider for latest night audit
final latestAuditProvider = FutureProvider.autoDispose<NightAudit?>((ref) async {
  final repository = ref.watch(nightAuditRepositoryProvider);
  return repository.getLatestAudit();
});

/// Provider for a single night audit by ID
final nightAuditByIdProvider = FutureProvider.autoDispose.family<NightAudit, int>((ref, id) async {
  final repository = ref.watch(nightAuditRepositoryProvider);
  return repository.getAudit(id);
});

/// Provider for audits in a specific month
final monthlyAuditsProvider = FutureProvider.autoDispose.family<List<NightAuditListItem>, NightAuditMonthYear>((ref, monthYear) async {
  final repository = ref.watch(nightAuditRepositoryProvider);
  return repository.getAuditsForMonth(monthYear.year, monthYear.month);
});

/// Helper class for month/year parameters (renamed to avoid conflict)
class NightAuditMonthYear {
  final int year;
  final int month;

  const NightAuditMonthYear(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NightAuditMonthYear && year == other.year && month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

/// State for NightAuditNotifier
@freezed
class NightAuditState with _$NightAuditState {
  const factory NightAuditState({
    @Default(false) bool isLoading,
    @Default(false) bool isCreating,
    @Default(false) bool isClosing,
    NightAudit? currentAudit,
    @Default([]) List<NightAuditListItem> audits,
    String? error,
  }) = _NightAuditState;
}

/// StateNotifier for managing night audits
class NightAuditNotifier extends StateNotifier<NightAuditState> {
  final NightAuditRepository _repository;
  final Ref _ref;

  NightAuditNotifier(this._repository, this._ref) : super(const NightAuditState());

  /// Load all audits
  Future<void> loadAudits({
    NightAuditStatus? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final audits = await _repository.getAudits(
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      state = state.copyWith(isLoading: false, audits: audits);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load today's audit
  Future<void> loadTodayAudit() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final audit = await _repository.getTodayAudit();
      state = state.copyWith(isLoading: false, currentAudit: audit);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new audit for a specific date
  Future<NightAudit?> createAudit(DateTime date, {String notes = ''}) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final request = NightAuditRequest(auditDate: date, notes: notes);
      final audit = await _repository.createAudit(request);
      state = state.copyWith(isCreating: false, currentAudit: audit);
      // Invalidate list to refresh
      _ref.invalidate(nightAuditsProvider);
      return audit;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return null;
    }
  }

  /// Update audit notes
  Future<NightAudit?> updateAuditNotes(int id, String notes) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final audit = await _repository.updateAudit(id, notes: notes);
      state = state.copyWith(isLoading: false, currentAudit: audit);
      return audit;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Close an audit
  Future<NightAudit?> closeAudit(int id) async {
    state = state.copyWith(isClosing: true, error: null);
    try {
      final audit = await _repository.closeAudit(id);
      state = state.copyWith(isClosing: false, currentAudit: audit);
      // Invalidate list to refresh
      _ref.invalidate(nightAuditsProvider);
      return audit;
    } catch (e) {
      state = state.copyWith(isClosing: false, error: e.toString());
      return null;
    }
  }

  /// Recalculate audit statistics
  Future<NightAudit?> recalculateAudit(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final audit = await _repository.recalculateAudit(id);
      state = state.copyWith(isLoading: false, currentAudit: audit);
      return audit;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Delete an audit
  Future<bool> deleteAudit(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteAudit(id);
      state = state.copyWith(isLoading: false, currentAudit: null);
      // Invalidate list to refresh
      _ref.invalidate(nightAuditsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Set current audit
  void setCurrentAudit(NightAudit? audit) {
    state = state.copyWith(currentAudit: audit);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for NightAuditNotifier
final nightAuditNotifierProvider = StateNotifierProvider<NightAuditNotifier, NightAuditState>((ref) {
  final repository = ref.watch(nightAuditRepositoryProvider);
  return NightAuditNotifier(repository, ref);
});
