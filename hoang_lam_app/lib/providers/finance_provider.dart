import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/finance.dart';
import '../repositories/finance_repository.dart';

part 'finance_provider.freezed.dart';

/// Provider for FinanceRepository
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});

// ==================== Category Providers ====================

/// Provider for all financial categories
final financialCategoriesProvider = FutureProvider<List<FinancialCategory>>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getCategories();
});

/// Provider for income categories
final incomeCategoriesProvider = FutureProvider<List<FinancialCategory>>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getIncomeCategories();
});

/// Provider for expense categories
final expenseCategoriesProvider = FutureProvider<List<FinancialCategory>>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getExpenseCategories();
});

// ==================== Entry Providers ====================

/// Provider for all financial entries
final financialEntriesProvider =
    FutureProvider.autoDispose<List<FinancialEntryListItem>>((ref) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getEntries();
    });

/// Provider for recent entries (last 7 days)
final recentEntriesProvider =
    FutureProvider.autoDispose<List<FinancialEntryListItem>>((ref) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getRecentEntries(days: 7);
    });

/// Provider for filtered entries
final filteredEntriesProvider = FutureProvider.autoDispose
    .family<List<FinancialEntryListItem>, FinancialEntryFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getEntriesWithFilter(filter);
    });

/// Provider for a specific entry by ID
final financialEntryByIdProvider = FutureProvider.autoDispose
    .family<FinancialEntry, int>((ref, id) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getEntry(id);
    });

/// Provider for income entries
final incomeEntriesProvider = FutureProvider.autoDispose
    .family<List<FinancialEntryListItem>, DateRange?>((ref, dateRange) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getIncomeEntries(
        dateFrom: dateRange?.start,
        dateTo: dateRange?.end,
      );
    });

/// Provider for expense entries
final expenseEntriesProvider = FutureProvider.autoDispose
    .family<List<FinancialEntryListItem>, DateRange?>((ref, dateRange) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getExpenseEntries(
        dateFrom: dateRange?.start,
        dateTo: dateRange?.end,
      );
    });

// ==================== Summary Providers ====================

/// Provider for today's summary
final todayFinancialSummaryProvider =
    FutureProvider.autoDispose<DailyFinancialSummary>((ref) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getTodaySummary();
    });

/// Provider for daily summary by date
final dailyFinancialSummaryProvider = FutureProvider.autoDispose
    .family<DailyFinancialSummary, DateTime?>((ref, date) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getDailySummary(date: date);
    });

/// Provider for current month summary
final currentMonthSummaryProvider =
    FutureProvider.autoDispose<MonthlyFinancialSummary>((ref) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getCurrentMonthSummary();
    });

/// Provider for monthly summary by year/month
final monthlyFinancialSummaryProvider = FutureProvider.autoDispose
    .family<MonthlyFinancialSummary, MonthYear>((ref, monthYear) async {
      final repository = ref.watch(financeRepositoryProvider);
      return repository.getMonthlySummary(
        year: monthYear.year,
        month: monthYear.month,
      );
    });

// ==================== Helper Classes ====================

/// Date range for filtering
@freezed
sealed class DateRange with _$DateRange {
  const factory DateRange({required DateTime start, required DateTime end}) =
      _DateRange;
}

/// Month and year for monthly queries
@freezed
sealed class MonthYear with _$MonthYear {
  const factory MonthYear({required int year, required int month}) = _MonthYear;
}

// ==================== State Notifier for Finance Management ====================

/// State for finance screen
@freezed
sealed class FinanceState with _$FinanceState {
  const factory FinanceState({
    @Default([]) List<FinancialEntryListItem> entries,
    @Default([]) List<FinancialCategory> incomeCategories,
    @Default([]) List<FinancialCategory> expenseCategories,
    MonthlyFinancialSummary? monthlySummary,
    @Default(false) bool isLoading,
    @Default(null) String? error,
    @Default(FinanceFilterState()) FinanceFilterState filter,
  }) = _FinanceState;
}

/// Filter state for finance
@freezed
sealed class FinanceFilterState with _$FinanceFilterState {
  const factory FinanceFilterState({
    @Default(null) EntryType? entryType,
    @Default(null) int? categoryId,
    @Default(null) DateTime? dateFrom,
    @Default(null) DateTime? dateTo,
    @Default(null) PaymentMethod? paymentMethod,
  }) = _FinanceFilterState;
}

/// State notifier for finance management operations
class FinanceNotifier extends StateNotifier<FinanceState> {
  final FinanceRepository _repository;
  int _currentYear;
  int _currentMonth;

  FinanceNotifier(this._repository)
    : _currentYear = DateTime.now().year,
      _currentMonth = DateTime.now().month,
      super(const FinanceState(isLoading: true)) {
    _loadInitialData();
  }

  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;

  /// Load initial data
  Future<void> _loadInitialData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Load categories and monthly summary in parallel
      final results = await Future.wait([
        _repository.getIncomeCategories(),
        _repository.getExpenseCategories(),
        _repository.getMonthlySummary(year: _currentYear, month: _currentMonth),
        _repository.getEntries(
          entryType: state.filter.entryType,
          category: state.filter.categoryId,
          dateFrom: state.filter.dateFrom,
          dateTo: state.filter.dateTo,
          paymentMethod: state.filter.paymentMethod,
        ),
      ]);

      state = state.copyWith(
        incomeCategories: results[0] as List<FinancialCategory>,
        expenseCategories: results[1] as List<FinancialCategory>,
        monthlySummary: results[2] as MonthlyFinancialSummary,
        entries: results[3] as List<FinancialEntryListItem>,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _loadInitialData();
  }

  /// Load entries with filter
  Future<void> loadEntries() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final entries = await _repository.getEntries(
        entryType: state.filter.entryType,
        category: state.filter.categoryId,
        dateFrom: state.filter.dateFrom,
        dateTo: state.filter.dateTo,
        paymentMethod: state.filter.paymentMethod,
      );

      state = state.copyWith(entries: entries, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  /// Change month
  Future<void> changeMonth(int year, int month) async {
    _currentYear = year;
    _currentMonth = month;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final summary = await _repository.getMonthlySummary(
        year: year,
        month: month,
      );

      // Calculate date range for the month
      final dateFrom = DateTime(year, month, 1);
      final dateTo = DateTime(year, month + 1, 0);

      final entries = await _repository.getEntries(
        entryType: state.filter.entryType,
        category: state.filter.categoryId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        paymentMethod: state.filter.paymentMethod,
      );

      state = state.copyWith(
        monthlySummary: summary,
        entries: entries,
        isLoading: false,
        filter: state.filter.copyWith(dateFrom: dateFrom, dateTo: dateTo),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  /// Go to previous month
  Future<void> previousMonth() async {
    var year = _currentYear;
    var month = _currentMonth - 1;
    if (month < 1) {
      month = 12;
      year--;
    }
    await changeMonth(year, month);
  }

  /// Go to next month
  Future<void> nextMonth() async {
    var year = _currentYear;
    var month = _currentMonth + 1;
    if (month > 12) {
      month = 1;
      year++;
    }
    await changeMonth(year, month);
  }

  /// Apply filter
  Future<void> applyFilter(FinanceFilterState filter) async {
    state = state.copyWith(filter: filter);
    await loadEntries();
  }

  /// Filter by entry type
  Future<void> filterByType(EntryType? type) async {
    state = state.copyWith(filter: state.filter.copyWith(entryType: type));
    await loadEntries();
  }

  /// Clear filter
  Future<void> clearFilter() async {
    state = state.copyWith(filter: const FinanceFilterState());
    await loadEntries();
  }

  /// Create income entry
  Future<FinancialEntry> createIncome({
    required int category,
    required double amount,
    required DateTime date,
    required String description,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    int? booking,
    String? receiptNumber,
  }) async {
    final entry = await _repository.createIncome(
      category: category,
      amount: amount,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      booking: booking,
      receiptNumber: receiptNumber,
    );
    await refresh();
    return entry;
  }

  /// Create expense entry
  Future<FinancialEntry> createExpense({
    required int category,
    required double amount,
    required DateTime date,
    required String description,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? receiptNumber,
  }) async {
    final entry = await _repository.createExpense(
      category: category,
      amount: amount,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      receiptNumber: receiptNumber,
    );
    await refresh();
    return entry;
  }

  /// Create entry from request (generic)
  Future<FinancialEntry> createEntry(FinancialEntryRequest request) async {
    final entry = await _repository.createEntry(request);
    await refresh();
    return entry;
  }

  /// Update entry
  Future<FinancialEntry> updateEntry(
    int id,
    FinancialEntryRequest request,
  ) async {
    final entry = await _repository.updateEntry(id, request);
    await refresh();
    return entry;
  }

  /// Delete entry
  Future<void> deleteEntry(int id) async {
    await _repository.deleteEntry(id);
    await refresh();
  }
}

/// Provider for FinanceNotifier
final financeNotifierProvider =
    StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
      final repository = ref.watch(financeRepositoryProvider);
      return FinanceNotifier(repository);
    });
