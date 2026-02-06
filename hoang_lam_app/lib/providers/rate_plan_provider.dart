import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/rate_plan.dart';
import '../repositories/rate_plan_repository.dart';

part 'rate_plan_provider.freezed.dart';

/// Provider for RatePlanRepository
final ratePlanRepositoryProvider = Provider<RatePlanRepository>((ref) {
  return RatePlanRepository();
});

/// Provider for all rate plans
final ratePlansProvider = FutureProvider<List<RatePlanListItem>>((ref) async {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return repository.getRatePlans();
});

/// Provider for active rate plans only
final activeRatePlansProvider = FutureProvider<List<RatePlanListItem>>((ref) async {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return repository.getRatePlans(isActive: true);
});

/// Provider for rate plans by room type
final ratePlansByRoomTypeProvider =
    FutureProvider.family<List<RatePlanListItem>, int>((ref, roomTypeId) async {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return repository.getRatePlansByRoomType(roomTypeId);
});

/// Provider for a specific rate plan by ID
final ratePlanByIdProvider =
    FutureProvider.family<RatePlan, int>((ref, id) async {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return repository.getRatePlan(id);
});

/// Provider for filtered rate plans
final filteredRatePlansProvider =
    FutureProvider.family<List<RatePlanListItem>, RatePlanFilter>(
        (ref, filter) async {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return repository.getRatePlans(
    roomTypeId: filter.roomTypeId,
    isActive: filter.isActive,
  );
});

/// Rate plan filter for querying rate plans
@freezed
sealed class RatePlanFilter with _$RatePlanFilter {
  const factory RatePlanFilter({
    int? roomTypeId,
    bool? isActive,
  }) = _RatePlanFilter;
}

/// Provider for all date rate overrides
final dateRateOverridesProvider =
    FutureProvider<List<DateRateOverrideListItem>>((ref) async {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return repository.getDateRateOverrides();
});

/// Provider for date rate overrides by room type and date range
final dateRateOverridesByRoomTypeProvider = FutureProvider.family<
    List<DateRateOverrideListItem>, DateRateOverrideFilter>((ref, filter) async {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return repository.getDateRateOverridesByRoomType(
    filter.roomTypeId,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

/// Provider for a specific date rate override by ID
final dateRateOverrideByIdProvider =
    FutureProvider.family<DateRateOverride, int>((ref, id) async {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return repository.getDateRateOverride(id);
});

/// Date rate override filter for querying overrides
@freezed
sealed class DateRateOverrideFilter with _$DateRateOverrideFilter {
  const factory DateRateOverrideFilter({
    required int roomTypeId,
    required DateTime startDate,
    required DateTime endDate,
  }) = _DateRateOverrideFilter;
}

/// State notifier for managing rate plan operations
class RatePlanNotifier extends StateNotifier<AsyncValue<List<RatePlanListItem>>> {
  final RatePlanRepository _repository;
  final Ref _ref;

  RatePlanNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadRatePlans();
  }

  Future<void> loadRatePlans({int? roomTypeId, bool? isActive}) async {
    state = const AsyncValue.loading();
    try {
      final ratePlans = await _repository.getRatePlans(
        roomTypeId: roomTypeId,
        isActive: isActive,
      );
      state = AsyncValue.data(ratePlans);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<RatePlan> createRatePlan(RatePlanCreateRequest request) async {
    final ratePlan = await _repository.createRatePlan(request);
    await loadRatePlans();
    return ratePlan;
  }

  Future<RatePlan> updateRatePlan(int id, Map<String, dynamic> updates) async {
    final ratePlan = await _repository.updateRatePlan(id, updates);
    await loadRatePlans();
    return ratePlan;
  }

  Future<void> deleteRatePlan(int id) async {
    await _repository.deleteRatePlan(id);
    await loadRatePlans();
  }
}

/// Provider for RatePlanNotifier
final ratePlanNotifierProvider =
    StateNotifierProvider<RatePlanNotifier, AsyncValue<List<RatePlanListItem>>>(
        (ref) {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return RatePlanNotifier(repository, ref);
});

/// State notifier for managing date rate override operations
class DateRateOverrideNotifier
    extends StateNotifier<AsyncValue<List<DateRateOverrideListItem>>> {
  final RatePlanRepository _repository;
  final Ref _ref;

  DateRateOverrideNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading());

  Future<void> loadOverrides({
    int? roomTypeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final overrides = await _repository.getDateRateOverrides(
        roomTypeId: roomTypeId,
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(overrides);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<DateRateOverride> createOverride(
      DateRateOverrideCreateRequest request) async {
    final override = await _repository.createDateRateOverride(request);
    await loadOverrides();
    return override;
  }

  Future<List<DateRateOverride>> bulkCreateOverrides(
      DateRateOverrideBulkCreateRequest request) async {
    final overrides = await _repository.bulkCreateDateRateOverrides(request);
    await loadOverrides();
    return overrides;
  }

  Future<DateRateOverride> updateOverride(
      int id, Map<String, dynamic> updates) async {
    final override = await _repository.updateDateRateOverride(id, updates);
    await loadOverrides();
    return override;
  }

  Future<void> deleteOverride(int id) async {
    await _repository.deleteDateRateOverride(id);
    await loadOverrides();
  }
}

/// Provider for DateRateOverrideNotifier
final dateRateOverrideNotifierProvider = StateNotifierProvider<
    DateRateOverrideNotifier, AsyncValue<List<DateRateOverrideListItem>>>((ref) {
  final repository = ref.watch(ratePlanRepositoryProvider);
  return DateRateOverrideNotifier(repository, ref);
});
