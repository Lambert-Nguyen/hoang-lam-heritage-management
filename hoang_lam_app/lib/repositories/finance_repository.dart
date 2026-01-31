import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/finance.dart';

/// Repository for financial management operations
class FinanceRepository {
  final ApiClient _apiClient;

  FinanceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ==================== Financial Categories ====================

  /// Get all financial categories with optional filters
  Future<List<FinancialCategory>> getCategories({
    EntryType? categoryType,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};

    if (categoryType != null) {
      queryParams['category_type'] = categoryType.toApiValue;
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.categoriesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both list and paginated responses
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => FinancialCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final results = dataMap['results'] as List<dynamic>;
        return results
            .map((json) => FinancialCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  /// Get income categories
  Future<List<FinancialCategory>> getIncomeCategories() async {
    return getCategories(categoryType: EntryType.income, isActive: true);
  }

  /// Get expense categories
  Future<List<FinancialCategory>> getExpenseCategories() async {
    return getCategories(categoryType: EntryType.expense, isActive: true);
  }

  /// Get a single category by ID
  Future<FinancialCategory> getCategory(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.categoriesEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Category not found');
    }
    return FinancialCategory.fromJson(response.data!);
  }

  // ==================== Financial Entries ====================

  /// Get all financial entries with optional filters
  Future<List<FinancialEntryListItem>> getEntries({
    EntryType? entryType,
    int? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    PaymentMethod? paymentMethod,
  }) async {
    final queryParams = <String, dynamic>{};

    if (entryType != null) {
      queryParams['entry_type'] = entryType.toApiValue;
    }
    if (category != null) {
      queryParams['category'] = category.toString();
    }
    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
    }
    if (paymentMethod != null) {
      queryParams['payment_method'] = paymentMethod.toApiValue;
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.financesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both list and paginated responses
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => FinancialEntryListItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final results = dataMap['results'] as List<dynamic>;
        return results
            .map((json) => FinancialEntryListItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  /// Get entries with filter object
  Future<List<FinancialEntryListItem>> getEntriesWithFilter(
    FinancialEntryFilter filter,
  ) async {
    return getEntries(
      entryType: filter.entryType,
      category: filter.category,
      dateFrom: filter.dateFrom,
      dateTo: filter.dateTo,
      paymentMethod: filter.paymentMethod,
    );
  }

  /// Get a single entry by ID
  Future<FinancialEntry> getEntry(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.financesEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Entry not found');
    }
    return FinancialEntry.fromJson(response.data!);
  }

  /// Create a new financial entry
  Future<FinancialEntry> createEntry(FinancialEntryRequest entry) async {
    final data = {
      'entry_type': entry.entryType.toApiValue,
      'category': entry.category,
      'amount': entry.amount,
      'currency': entry.currency,
      'exchange_rate': entry.exchangeRate,
      'date': entry.date.toIso8601String().split('T')[0],
      'description': entry.description,
      'payment_method': entry.paymentMethod.toApiValue,
      if (entry.booking != null) 'booking': entry.booking,
      if (entry.receiptNumber != null) 'receipt_number': entry.receiptNumber,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.financesEndpoint,
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to create entry');
    }
    return FinancialEntry.fromJson(response.data!);
  }

  /// Create income entry (convenience method)
  Future<FinancialEntry> createIncome({
    required int category,
    required double amount,
    required DateTime date,
    required String description,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    int? booking,
    String? receiptNumber,
  }) async {
    return createEntry(FinancialEntryRequest(
      entryType: EntryType.income,
      category: category,
      amount: amount,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      booking: booking,
      receiptNumber: receiptNumber,
    ));
  }

  /// Create expense entry (convenience method)
  Future<FinancialEntry> createExpense({
    required int category,
    required double amount,
    required DateTime date,
    required String description,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? receiptNumber,
  }) async {
    return createEntry(FinancialEntryRequest(
      entryType: EntryType.expense,
      category: category,
      amount: amount,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      receiptNumber: receiptNumber,
    ));
  }

  /// Update a financial entry
  Future<FinancialEntry> updateEntry(int id, FinancialEntryRequest entry) async {
    final data = {
      'entry_type': entry.entryType.toApiValue,
      'category': entry.category,
      'amount': entry.amount,
      'currency': entry.currency,
      'exchange_rate': entry.exchangeRate,
      'date': entry.date.toIso8601String().split('T')[0],
      'description': entry.description,
      'payment_method': entry.paymentMethod.toApiValue,
      if (entry.booking != null) 'booking': entry.booking,
      if (entry.receiptNumber != null) 'receipt_number': entry.receiptNumber,
    };

    final response = await _apiClient.put<Map<String, dynamic>>(
      '${AppConstants.financesEndpoint}$id/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to update entry');
    }
    return FinancialEntry.fromJson(response.data!);
  }

  /// Delete a financial entry
  Future<void> deleteEntry(int id) async {
    await _apiClient.delete('${AppConstants.financesEndpoint}$id/');
  }

  // ==================== Summaries ====================

  /// Get daily financial summary
  Future<DailyFinancialSummary> getDailySummary({DateTime? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) {
      queryParams['date'] = date.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.financesEndpoint}daily-summary/',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      throw Exception('Failed to get daily summary');
    }

    // Parse date from string if needed
    final data = Map<String, dynamic>.from(response.data!);
    if (data['date'] is String) {
      data['date'] = DateTime.parse(data['date'] as String);
    }

    return DailyFinancialSummary.fromJson(data);
  }

  /// Get today's summary (convenience method)
  Future<DailyFinancialSummary> getTodaySummary() async {
    return getDailySummary(date: DateTime.now());
  }

  /// Get monthly financial summary
  Future<MonthlyFinancialSummary> getMonthlySummary({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final queryParams = <String, dynamic>{
      'year': (year ?? now.year).toString(),
      'month': (month ?? now.month).toString(),
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.financesEndpoint}monthly-summary/',
      queryParameters: queryParams,
    );

    if (response.data == null) {
      throw Exception('Failed to get monthly summary');
    }

    return MonthlyFinancialSummary.fromJson(response.data!);
  }

  /// Get current month summary (convenience method)
  Future<MonthlyFinancialSummary> getCurrentMonthSummary() async {
    final now = DateTime.now();
    return getMonthlySummary(year: now.year, month: now.month);
  }

  // ==================== Helper Methods ====================

  /// Get recent entries (last N days)
  Future<List<FinancialEntryListItem>> getRecentEntries({int days = 7}) async {
    final now = DateTime.now();
    final fromDate = now.subtract(Duration(days: days));
    return getEntries(dateFrom: fromDate, dateTo: now);
  }

  /// Get income entries for a date range
  Future<List<FinancialEntryListItem>> getIncomeEntries({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return getEntries(
      entryType: EntryType.income,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  /// Get expense entries for a date range
  Future<List<FinancialEntryListItem>> getExpenseEntries({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return getEntries(
      entryType: EntryType.expense,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
